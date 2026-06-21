#!/data/data/com.termux/files/usr/bin/bash
#
# Task 1 — Termux base + X server
# Run this INSIDE Termux on the phone (NOT inside Debian, NOT on the Dell).
#
# Brings Termux up to date and installs the X server + audio + proot tooling.
# Idempotent: safe to re-run.
#
set -euo pipefail

say() { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }

# --- sanity: we must be in Termux ---------------------------------------------
if [ ! -d /data/data/com.termux/files/usr ]; then
  echo "ERROR: This does not look like Termux. Run this on the phone's Termux." >&2
  exit 1
fi

say "Updating Termux packages (pkg update && upgrade)"
pkg update -y
pkg upgrade -y

say "Requesting shared storage access"
# Pops an Android permission dialog the first time. Accept it on the phone.
# Harmless to call again once granted.
termux-setup-storage || true

say "Enabling the X11 package repo"
pkg install -y x11-repo

say "Installing X server, audio, and proot-distro"
# termux-x11-nightly: the server-side package (pairs with the Termux:X11 APK).
# pulseaudio:        audio bridge to the phone speakers (Task 5).
# proot-distro:      no-root Linux guest manager (Task 2).
# pulseaudio-utils ships pactl, used by start-desktop.sh / audio test.
pkg install -y termux-x11-nightly pulseaudio proot-distro

say "Versions installed:"
termux-x11 --help >/dev/null 2>&1 && echo "  termux-x11: present" || echo "  termux-x11: NOT found (check x11-repo)"
command -v proot-distro >/dev/null && echo "  proot-distro: $(proot-distro --version 2>/dev/null | head -n1)"
command -v pulseaudio   >/dev/null && echo "  pulseaudio: $(pulseaudio --version 2>/dev/null)"

cat <<'NOTE'

----------------------------------------------------------------------
Task 1 done-when check:
  1. Make sure the Termux:X11 COMPANION APK is installed (F-Droid/GitHub
     build — NOT the dead Play Store one). The apk and this package are
     two different things; you need both.
  2. Smoke test the X surface:
         export XDG_RUNTIME_DIR="$TMPDIR"
         termux-x11 :0 &
         am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity
     The Termux:X11 app should show a black X screen — no crash.
  3. Stop it when done:
         am broadcast -a com.termux.x11.ACTION_STOP -p com.termux.x11
         pkill -f com.termux.x11 || true

Next: setup/10-install-debian.sh
----------------------------------------------------------------------
NOTE
