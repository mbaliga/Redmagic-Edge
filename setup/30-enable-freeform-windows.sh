#!/data/data/com.termux/files/usr/bin/bash
#
# Task 9 (EXPERIMENTAL) — no-root Android freeform windows.
#
# Toggles the same class of stock Android Settings.Global flags this
# project already used to disable the phantom-process killer: no root,
# fully reversible, just plain `adb shell settings put`. Unlocks Android's
# built-in (if OEM-dependent) support for dragging ordinary apps into
# resizable floating windows -- the first step toward running native
# Android apps alongside the XFCE desktop on the external monitor.
# See docs/PHASE2-EXPLORATION.md for what this does and doesn't get you,
# and why (root-gated cross-app window management is out of reach by the
# project's own "no root, ever" rule -- this is the no-root alternative).
#
# Requires ADB wireless debugging already paired to this phone (Settings ->
# Developer options -> Wireless debugging), same as used earlier in this
# project.
#
set -uo pipefail

say() { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }

if ! command -v adb >/dev/null 2>&1; then
  echo "adb not found. Install with: pkg install android-tools"
  exit 1
fi

say "Checking for a connected/paired device"
adb devices -l

say "Enabling freeform windows + resizable activities + external-display desktop mode"
adb shell settings put global development_settings_enabled 1
adb shell settings put global enable_freeform_support 1
adb shell settings put global force_resizable_activities 1
adb shell settings put global force_desktop_mode_on_external_displays 1

cat <<NOTE

[freeform] --------------------------------------------------------------
Done when: reboot the phone, plug into the monitor, and try dragging an
ordinary Android app (not Termux:X11) into a resizable floating window.

  Works    -> real freeform windows are live. Next step (not yet
              automated by this repo -- untested combination): sideload
              the "Taskbar" app (github.com/farmerbb/Taskbar or F-Droid)
              for an actual taskbar/app-drawer over those windows on the
              external display. See docs/PHASE2-EXPLORATION.md.
  Doesn't  -> RedMagic's Android skin may be blocking it even with these
              flags set -- its own desktop-mode implementation has
              reported similar bugs elsewhere. Not a dead end, just
              unproven on this device.

Reversible any time -- rerun with each value set to 0 (or false) to
revert. These are plain Settings.Global values, not a system or
bootloader change: no root, no bootloader unlock. No reports found of
these specific flags affecting Play Integrity, but that is an absence of
bad reports, not a Google-documented guarantee -- see
docs/PHASE2-EXPLORATION.md.
[freeform] --------------------------------------------------------------
NOTE
