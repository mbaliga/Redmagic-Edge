#!/usr/bin/env bash
#
# Task 5 audio sanity check. Run INSIDE the Debian guest (in the XFCE terminal,
# or via: proot-distro login debian --user redmagic --shared-tmp).
# Requires start-desktop.sh to have started PulseAudio on the Termux side.
#
set -uo pipefail
export PULSE_SERVER="${PULSE_SERVER:-127.0.0.1}"

echo "PULSE_SERVER=$PULSE_SERVER"
echo "== pactl info =="
pactl info || { echo "Cannot reach PulseAudio. Is start-desktop.sh running on the Termux side?"; exit 1; }

echo
echo "Playing a test tone for ~3s — you should hear it on the phone speakers."
if command -v speaker-test >/dev/null 2>&1; then
  speaker-test -t sine -f 440 -l 1 || true
elif command -v paplay >/dev/null 2>&1 && [ -f /usr/share/sounds/alsa/Front_Center.wav ]; then
  paplay /usr/share/sounds/alsa/Front_Center.wav || true
else
  echo "Install alsa-utils for speaker-test:  sudo apt-get install -y alsa-utils"
fi

echo
echo "If silent: confirm 'pactl info' on the Termux side shows the TCP module,"
echo "and that PULSE_SERVER=127.0.0.1 is exported here (it is via .desktop-env.sh)."
