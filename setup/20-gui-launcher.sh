#!/data/data/com.termux/files/usr/bin/bash
#
# Task 8 (Termux half) — one-tap launcher, no typing required.
# Run in Termux, after Tasks 1-7 are working. Idempotent.
#
# Sets up:
#   - Termux:Widget shortcuts (~/.shortcuts) -> tap a home-screen icon to
#     start/stop the desktop instead of opening Termux and typing.
#   - A persistent Start/Stop notification via Termux:API.
#
# Requires two COMPANION APKS you install yourself (same "the APK is
# separate from the package" gotcha as Termux:X11 -- see README.md):
#   - Termux:Widget  (F-Droid) -- turns ~/.shortcuts scripts into tappable
#     home-screen icons / long-press app shortcuts.
#   - Termux:API     (F-Droid) -- lets scripts post the notification below.
#     (Android 13+ also needs notification permission granted once.)
#
set -uo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SHORTCUTS_DIR="$HOME/.shortcuts"
BIN="/data/data/com.termux/files/usr/bin/bash"

say() { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }

say "Installing termux-api (the CLI side of Termux:API)"
pkg install -y termux-api

say "Writing Termux:Widget shortcuts to $SHORTCUTS_DIR"
mkdir -p "$SHORTCUTS_DIR"

cat > "$SHORTCUTS_DIR/Start Desktop.sh" <<EOF
#!$BIN
exec "$REPO_DIR/start-desktop.sh"
EOF

cat > "$SHORTCUTS_DIR/Stop Desktop.sh" <<EOF
#!$BIN
exec "$REPO_DIR/stop-desktop.sh"
EOF

chmod +x "$SHORTCUTS_DIR/Start Desktop.sh" "$SHORTCUTS_DIR/Stop Desktop.sh"

say "Posting a persistent Start/Stop notification (needs the Termux:API app)"
# Buttons point at the repo scripts directly (no spaces in the path) rather
# than the widget shortcuts above, since a path with spaces in a
# notification button action is a known way to have it misparsed.
termux-notification \
  --id redmagic-desktop \
  --title "Redmagic Desktop" \
  --content "Tap a button to start or stop the desktop" \
  --ongoing \
  --button1 "Start" --button1-action "$REPO_DIR/start-desktop.sh" \
  --button2 "Stop"  --button2-action "$REPO_DIR/stop-desktop.sh" \
  2>/dev/null || echo "  (skipped -- install the Termux:API app, grant notification permission, and re-run if this failed)"

cat <<NOTE

[gui-launcher] --------------------------------------------------------
Done when:
  1. Install Termux:Widget (F-Droid) if you haven't already. Long-press its
     launcher icon for "Start Desktop" / "Stop Desktop" app shortcuts, or
     drag its home-screen widget on and pick them from the grid.
     Tap-to-launch, no typing, no opening Termux by hand.
  2. Install Termux:API (F-Droid) if you want the notification -- pull down
     notifications, you should see "Redmagic Desktop" with Start/Stop
     buttons.
[gui-launcher] --------------------------------------------------------
NOTE
