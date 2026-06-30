SHELLS = {'fish', 'zsh', 'bash', 'sh', 'dash', 'ksh', 'tcsh', 'nu', 'xonsh'}

# Programs shown as "<icon|name> · <dir>". Anything not here shows the full
# typed command (so "azsh dev odesa" survives intact).
NAMED_PROGRAMS = {
    'nvim', 'vim', 'vi', 'nano', 'hx', 'helix',
    'less', 'man', 'git', 'lazygit', 'gitui',
    'top', 'htop', 'btop', 'k9s',
}

# Per-program glyph instead of the program name. \ue6ae is the Neovim logo
# (Nerd Font only — falls back to an empty box without one).
ICONS = {
    'nvim': '\ue6ae',
    'vim':  '\ue6ae',
}

CLAUDE_WAITING = {'✳', '✻', '✽', '✶'}  # claude idle/waiting glyphs

def _name(path):
    return path.rstrip('/').rsplit('/', 1)[-1]

def _is_braille(ch):
    return bool(ch) and 0x2800 <= ord(ch) <= 0x28ff

def _strip_cwd(title):
    head, _, tail = title.rpartition(' ')
    if head and (tail.startswith('~') or tail.startswith('/')):
        return head
    return title

def draw_title(data):
    title = (data['title'] or '').strip()
    tab = data['tab']
    first = title[:1]
    dirname = _name(tab.active_wd) or '~'

    # 1) Claude Code: "<glyph> <task>" -> "claude · <task>". Tab color (driven
    #    by Claude Code hooks) signals working/waiting, so no robot glyph here.
    if _is_braille(first) or first in CLAUDE_WAITING:
        task = title[1:].strip()
        label = f'claude · {task}' if task else 'claude'
        return label

    exe = tab.active_exe

    # 2) Fish prompt -> "🐡 · <dir>".
    if not exe or exe.lstrip('-') in SHELLS:
        return f'🐡 · {dirname}'

    # 3) Command running. Named tools -> "<icon|name> · <dir>";
    #    everything else -> the full typed command.
    cmd = _strip_cwd(title)
    head = cmd.split(' ', 1)[0] if cmd else ''
    if head in NAMED_PROGRAMS:
        return f'{ICONS.get(head, head)} · {dirname}'
    return cmd or dirname


# ─── Claude state tinting ───
# Tint the whole tab (rounded caps + pill body) from the `claude_state` user-var
# set by the Claude Code hook ~/.claude/kitty-tab-color.sh:
#   working -> amber, waiting -> red, otherwise the default tab colors.
# The templates paint the caps with {fmt.fg.tab} and the body bg with {fmt.bg.tab},
# and tab fg == tab bg in kitty.conf, so overriding those colors here tints the
# caps and body together as one capsule. Guarded: if kitty's API ever changes, no
# draw_tab is defined and kitty falls back to the normal separator render.
# NOTE: needs `tab_bar_style custom` in kitty.conf for kitty to call draw_tab.
# Edits hot-reload via `kitten @ action load_config_file` (or Ctrl+Shift+F5) — no
# restart required.
try:
    from kitty.tab_bar import draw_tab_with_separator
    from kitty.fast_data_types import Color, get_boss

    # (active = bright tint, inactive = dimmed tint). Active tabs render dark
    # body text so a bright tint reads; inactive tabs render LIGHT body text, so
    # they get a darker tint to keep that light text legible.
    # Set by the Claude Code hook ~/.claude/kitty-tab-color.sh (Tokyo Night).
    _STATE_COLOR = {
        'ready':      (Color(0x9e, 0xce, 0x6a), Color(0x4f, 0x67, 0x35)),  # green / dim
        'working':    (Color(0xe0, 0xaf, 0x68), Color(0x7a, 0x5e, 0x28)),  # amber / dim
        'waiting':    (Color(0xf7, 0x76, 0x8e), Color(0x8a, 0x34, 0x46)),  # red / dim
        'background': (Color(0x7a, 0xa2, 0xf7), Color(0x41, 0x48, 0x68)),  # blue / dim (kitty default)
        'error':      (Color(0xdb, 0x4b, 0x4b), Color(0x6d, 0x25, 0x25)),  # red / dim (distinct from waiting)
    }

    def _claude_state(tab_id):
        try:
            tab = get_boss().tab_for_id(tab_id)
            win = tab.active_window if tab else None
            return (win.user_vars.get('claude_state') if win else None) or None
        except Exception:
            return None

    def draw_tab(draw_data, screen, tab, before, max_tab_length,
                 index, is_last, extra_data):
        try:
            pair = _STATE_COLOR.get(_claude_state(tab.tab_id))
            if pair is not None:
                bright, dim = pair
                # tab_fg drives the caps, tab_bg the body; bright shade for the
                # active tab (dark text), dim shade for inactive (light text).
                draw_data = draw_data._replace(
                    active_fg=bright, active_bg=bright,
                    inactive_fg=dim, inactive_bg=dim)
        except Exception:
            pass
        return draw_tab_with_separator(
            draw_data, screen, tab, before, max_tab_length,
            index, is_last, extra_data)
except Exception:
    pass
