#!/data/data/com.termux/files/usr/bin/bash
#
# Task 4/5/7 — One command brings up the full XFCE desktop.
# Run INSIDE Termux on the phone. Validate on the phone screen first (Tasks
# 1-6), then plug the DP-Alt hub and re-run for the monitor (Task 7).
#
# Flow: start audio -> start X server -> foreground Termux:X11 app ->
#       enter Debian as the daily user -> run xfce4-session via dbus-launch.
#
set -uo pipefail   # not -e: we want to keep going past best-effort steps

DISTRO="${DISTRO:-debian}"
USERNAME="${USERNAME:-redmagic}"
DISP="${DISP:-:0}"

say() { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }

# --- clean any previous session ----------------------------------------------
say "Stopping any previous X11/desktop session"
am broadcast -a com.termux.x11.ACTION_STOP -p com.termux.x11 >/dev/null 2>&1 || true
pkill -f com.termux.x11 2>/dev/null || true
pkill -f "termux-x11 $DISP" 2>/dev/null || true
sleep 1

export XDG_RUNTIME_DIR="$TMPDIR"

# --- Task 5: audio -----------------------------------------------------------
say "Starting PulseAudio with TCP module on 127.0.0.1"
# Load the TCP module at start so Debian apps (PULSE_SERVER=127.0.0.1) can reach
# the phone's audio. Re-running is harmless; --exit-idle-time=-1 keeps it alive.
pulseaudio --start \
  --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" \
  --exit-idle-time=-1 || true
# Belt-and-suspenders: ensure the module is loaded even if the daemon was
# already running without it.
pactl load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1 \
  >/dev/null 2>&1 || true

# --- Task 1/4: X server ------------------------------------------------------
say "Starting Termux:X11 server on $DISP"
termux-x11 "$DISP" &
sleep 3

say "Bringing the Termux:X11 app to the foreground"
am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity >/dev/null 2>&1 || \
  echo "WARN: could not auto-launch the app — open Termux:X11 manually."
sleep 1

# --- Task 4: enter Debian and start XFCE -------------------------------------
say "Entering $DISTRO as $USERNAME and launching xfce4-session"
# --shared-tmp exposes the X socket in $TMPDIR to the guest (gotcha from spec).
# dbus-launch --exit-with-session is required or XFCE components hang.
proot-distro login "$DISTRO" --user "$USERNAME" --shared-tmp -- bash -lc "
  export DISPLAY=$DISP
  export PULSE_SERVER=127.0.0.1
  # Force CPU/software GL. Inside proot there's no GPU driver, so the XFCE
  # compositor would fall back to llvmpipe and stall (Android ANR / freezes).
  export LIBGL_ALWAYS_SOFTWARE=1
  export GALLIUM_DRIVER=llvmpipe
  [ -f \"\$HOME/.desktop-env.sh\" ] && . \"\$HOME/.desktop-env.sh\"
  export DISPLAY=$DISP   # re-assert after sourcing
  dbus-launch --exit-with-session xfce4-session
"

# When xfce4-session exits, tear the X server down too.
say "Desktop session ended — stopping X server"
pkill -f "termux-x11 $DISP" 2>/dev/null || true
am broadcast -a com.termux.x11.ACTION_STOP -p com.termux.x11 >/dev/null 2>&1 || true
