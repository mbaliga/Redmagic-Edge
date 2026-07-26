#!/data/data/com.termux/files/usr/bin/bash
#
# Companion to start-desktop.sh — gracefully tears down the XFCE session and
# the Termux:X11 server. Run from Termux, or via the "Stop Desktop"
# Termux:Widget shortcut / notification button (setup/20-gui-launcher.sh).
#
set -uo pipefail

DISTRO="${DISTRO:-debian}"
USERNAME="${USERNAME:-redmagic}"
DISP="${DISP:-:0}"

say() { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }

say "Ending the XFCE session inside $DISTRO"
proot-distro login "$DISTRO" --user "$USERNAME" --shared-tmp -- \
  pkill -u "$USERNAME" -f xfce4-session 2>/dev/null || true
sleep 1

say "Stopping the Termux:X11 server"
am broadcast -a com.termux.x11.ACTION_STOP -p com.termux.x11 >/dev/null 2>&1 || true
pkill -f com.termux.x11 2>/dev/null || true
pkill -f "termux-x11 $DISP" 2>/dev/null || true

say "Desktop stopped. (PulseAudio is left running — harmless, and audio-test.sh needs it.)"
