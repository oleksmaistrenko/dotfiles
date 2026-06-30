#!/usr/bin/env bash
# Record this Claude session's state as a kitty user-var on its window.
# ~/.config/kitty/tab_bar.py reads `claude_state` and tints the tab to match.
# (The actual colors live there, in _STATE_COLOR — this script only names the
#  state; the mechanism is unchanged: set one user-var on this window.)
#
#   state       color   hex        meaning
#   ready       green   #9ece6a    session started / turn finished cleanly — ready for input
#   working     amber   #e0af68    actively running (prompt, tools, subagents)
#   waiting     red     #f7768e    blocked on you (permission prompt / dialog)
#   background  blue    #7aa2f7    turn done, prompt free, but a background agent still runs
#   error       red     #db4b4b    turn ended in failure (distinct from waiting)
#   reset       none    —          clear the tab color back to default
#
# Usage: kitty-tab-color.sh ready|working|waiting|background|error|reset
# Any unknown argument falls back to reset.
[ -z "$KITTY_WINDOW_ID" ] && exit 0          # no-op outside kitty (ssh/tmux/etc.)
KITTEN="$(command -v kitten || echo /opt/homebrew/bin/kitten)"
case "$1" in
  ready)      arg="claude_state=ready" ;;
  working)    arg="claude_state=working" ;;
  waiting)    arg="claude_state=waiting" ;;
  background) arg="claude_state=background" ;;
  error)      arg="claude_state=error" ;;
  reset|*)    arg="claude_state" ;;        # reset or unknown -> unset the user-var
esac
"$KITTEN" @ set-user-vars --match id:"$KITTY_WINDOW_ID" "$arg" >/dev/null 2>&1 || true
