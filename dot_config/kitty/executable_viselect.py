#!/usr/bin/env python3
"""Minimal vi-like screen selector. Reads piped screen content on stdin,
drives its own TUI on /dev/tty, and yanks the selection to the clipboard.

Keys:
  h j k l    move
  0 $        line start / end
  g G        top / bottom
  w b        word forward / back
  v          char-wise visual
  V          line-wise visual
  y          yank selection and exit
  Esc        cancel visual / exit
  q          exit
"""
import os
import select
import subprocess
import sys
import termios
import tty

CSI = "\x1b["
RESET = CSI + "0m"
REVERSE = CSI + "7m"
CLEAR = CSI + "H" + CSI + "2J"
HIDE_CUR = CSI + "?25l"
SHOW_CUR = CSI + "?25h"


class App:
    def __init__(self, lines, tty_in, tty_out):
        self.lines = lines or [""]
        self.row = len(self.lines) - 1
        self.col = 0
        self.mode = "normal"  # "normal" | "visual" | "visual_line"
        self.anchor = None
        self.result = None
        self.tin = tty_in
        self.tout = tty_out
        size = os.get_terminal_size(tty_out.fileno())
        self.rows = size.lines
        self.cols = size.columns

    def w(self, s):
        self.tout.write(s)
        self.tout.flush()

    def read_key(self):
        ch = self.tin.read(1)
        if ch != b"\x1b":
            return ch.decode("utf-8", "replace")
        # Drain any escape sequence so we don't choke on arrow keys etc.
        while select.select([self.tin], [], [], 0.005)[0]:
            if not self.tin.read(1):
                break
        return "\x1b"

    def clamp(self):
        self.row = max(0, min(len(self.lines) - 1, self.row))
        line = self.lines[self.row]
        max_col = max(0, len(line) - 1)
        self.col = max(0, min(max_col, self.col))

    def sel_range(self):
        a = self.anchor
        b = (self.row, self.col)
        return (a, b) if a <= b else (b, a)

    def draw(self):
        out = [CLEAR]
        limit = min(len(self.lines), self.rows - 1)
        if self.mode == "normal":
            for i in range(limit):
                out.append(self.lines[i] + "\r\n")
        else:
            (sr, sc), (er, ec) = self.sel_range()
            for i in range(limit):
                line = self.lines[i]
                if self.mode == "visual_line":
                    if sr <= i <= er:
                        out.append(REVERSE + line + RESET + "\r\n")
                    else:
                        out.append(line + "\r\n")
                else:
                    if i < sr or i > er:
                        out.append(line + "\r\n")
                    else:
                        s = 0 if i > sr else sc
                        e = len(line) if i < er else ec + 1
                        out.append(line[:s] + REVERSE + line[s:e] + RESET + line[e:] + "\r\n")
        out.append(f"{CSI}{self.row + 1};{self.col + 1}H")
        self.w("".join(out))

    def selection(self):
        if self.mode == "normal":
            return self.lines[self.row]
        (sr, sc), (er, ec) = self.sel_range()
        if self.mode == "visual_line":
            return "\n".join(self.lines[sr:er + 1])
        if sr == er:
            return self.lines[sr][sc:ec + 1]
        parts = [self.lines[sr][sc:]]
        parts.extend(self.lines[sr + 1:er])
        parts.append(self.lines[er][:ec + 1])
        return "\n".join(parts)

    def word_fwd(self):
        line = self.lines[self.row]
        i = self.col
        n = len(line)
        while i < n - 1 and not line[i].isspace():
            i += 1
        while i < n - 1 and line[i].isspace():
            i += 1
        self.col = i

    def word_back(self):
        line = self.lines[self.row]
        i = max(0, self.col - 1)
        while i > 0 and line[i].isspace():
            i -= 1
        while i > 0 and not line[i - 1].isspace():
            i -= 1
        self.col = i

    def handle(self, ch):
        if ch == "\x1b":
            if self.mode != "normal":
                self.mode = "normal"
                self.anchor = None
                return False
            return True
        if ch == "q":
            return True
        if ch == "h":
            self.col -= 1
        elif ch == "l":
            self.col += 1
        elif ch == "j":
            self.row += 1
        elif ch == "k":
            self.row -= 1
        elif ch == "g":
            self.row = 0
        elif ch == "G":
            self.row = len(self.lines) - 1
        elif ch == "0":
            self.col = 0
        elif ch == "$":
            self.col = len(self.lines[self.row]) - 1
        elif ch == "w":
            self.word_fwd()
        elif ch == "b":
            self.word_back()
        elif ch == "v":
            if self.mode == "visual":
                self.mode = "normal"
                self.anchor = None
            else:
                self.mode = "visual"
                self.anchor = (self.row, self.col)
        elif ch == "V":
            if self.mode == "visual_line":
                self.mode = "normal"
                self.anchor = None
            else:
                self.mode = "visual_line"
                self.anchor = (self.row, self.col)
        elif ch == "y":
            self.result = self.selection()
            return True
        self.clamp()
        return False

    def run(self):
        fd = self.tin.fileno()
        old = termios.tcgetattr(fd)
        tty.setraw(fd)
        self.w(HIDE_CUR)
        self.draw()
        self.w(SHOW_CUR)
        try:
            while not self.handle(self.read_key()):
                self.draw()
        finally:
            termios.tcsetattr(fd, termios.TCSADRAIN, old)
            self.w(CLEAR)


def main():
    text = sys.stdin.read()
    lines = text.rstrip("\n").split("\n")
    while lines and not lines[-1].strip():
        lines.pop()
    tin = open("/dev/tty", "rb", buffering=0)
    tout = open("/dev/tty", "w")
    app = App(lines, tin, tout)
    app.run()
    if app.result is not None:
        p = subprocess.Popen(["pbcopy"], stdin=subprocess.PIPE)
        p.communicate(app.result.encode("utf-8"))


if __name__ == "__main__":
    try:
        main()
    except Exception:
        import traceback
        with open("/tmp/viselect.log", "a") as fh:
            fh.write(traceback.format_exc() + "\n")
        # Keep the window open briefly so user can see something went wrong.
        sys.stderr.write("viselect error — see /tmp/viselect.log\n")
        sys.stderr.flush()
        try:
            sys.stdin.read(1)
        except Exception:
            pass
