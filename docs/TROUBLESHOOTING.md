# Troubleshooting & gotchas

## Package names / repos
- If a `pkg`/`apt` name 404s, the index drifted — search the current index
  (`pkg search <name>` / `apt-cache search <name>`) instead of guessing.
- `termux-x11-nightly` lives in **x11-repo** — install `x11-repo` first.

## X11 won't show anything
- The Termux:X11 **APK** and the **`termux-x11-nightly` package** are different.
  You need both. The APK must be the F-Droid/GitHub build, not the Play Store one.
- Use `--shared-tmp` on `proot-distro login` so the X socket in `$TMPDIR` is
  visible inside Debian. Without it, apps can't reach `:0`.
- Set `export XDG_RUNTIME_DIR="$TMPDIR"` on the Termux side before starting.
- If the app doesn't auto-foreground, open **Termux:X11** manually from the
  launcher after the server is up.
- Display number must match between server and app. We standardize on `:0`
  (override with `DISP=:1 ./start-desktop.sh` if needed).

## Desktop freezes / "Termux:X11 isn't responding" (ANR)
- Cause: proot has no GPU driver, so XFCE's compositor falls back to software
  GL (`llvmpipe`) and stalls on large displays. The log shows
  `xfwm4 WARNING: Unsupported GL renderer (llvmpipe ...)`.
- Fix (baked into the scripts): disable compositing
  (`xfwm4 → use_compositing = false`) and export `LIBGL_ALWAYS_SOFTWARE=1`
  + `GALLIUM_DRIVER=llvmpipe`. To disable compositing live: Settings → Window
  Manager Tweaks → Compositor → untick "Enable display compositing".
- When the ANR popup appears, tap **Wait**, never **Close app** (Close kills the
  X server and you get the "Not connected" screen).

## External monitor on RedMagic (Mirror vs Extended)
- RedMagic's display panel offers **Mirror mode** (monitor copies the phone,
  phone's aspect ratio, sleeps with the phone) and **Extended Mode** (monitor is
  a separate display with its own 1080P/2K/4K resolution; phone becomes a
  touchpad). Extended Mode + **Sleep Projection** is what satisfies the Phase 1
  "phone screen can sleep while the desktop stays up" goal, and a real mouse on
  the extended display avoids the touch-emulation click issues below.

## Termux:X11 mouse/keyboard quirks
- Soft keyboard pops up in fullscreen: hide it via the toolbar keyboard icon, or
  Termux:X11 Preferences → turn off "Show additional keyboard". Not needed when a
  hardware keyboard is attached.
- Left/right click misbehaves on the phone screen: that's touch-to-click
  emulation. Use a physical mouse (ideally on the extended display), or adjust
  the input/mouse mode in Termux:X11 Preferences.

## Trackpad/keyboard combo devices (generic, physical HID hardware)
- `debian-provision.sh` installs a generic, self-detecting tuner
  (`~/bin/tune-pointer-input.sh`, runs at every session start) that turns on
  tap-to-click / natural scrolling / disable-while-typing for **whatever** real
  pointer device is plugged in, if it exposes libinput properties. Works for any
  actual HID trackpad, whatever it's branded — useful if you ever attach a
  physical keyboard+trackpad combo. (This is unrelated to Clackpad, which turned
  out to be a software IME, not hardware — see the dedicated Clackpad section
  below.)
- To check what your device reports once it's connected and the desktop is up:
  `DISPLAY=:0 xinput list`, then `DISPLAY=:0 xinput list-props <id>` for the
  trackpad's id.
  - See `libinput ...` properties listed → the auto-tuner is doing its job; to
    tweak further, edit `~/bin/tune-pointer-input.sh` directly.
  - See only generic/core-pointer properties → this device isn't going through
    libinput at all (common for compact combo keyboards — the trackpad's own
    firmware does click detection and reports itself as a plain HID mouse).
    XFCE-side tuning has nothing to grab; control instead lives in Termux:X11
    itself — see the next point.
- Termux:X11 has a **"Capture external mouse when possible"** preference
  (long-press its launcher icon → Preferences) that changes how it forwards a
  genuine external mouse/trackpad's clicks and motion. Test both settings with
  your device connected — known upstream reports (termux-x11 #403, #598, #297)
  show either state can be the "wrong" one depending on the specific device
  (reversed axes, split click/motion devices, taps not registering). This is an
  Android-app setting, not something scriptable from inside Debian.
- If your device needs a companion Android app to unlock full function (custom
  gesture layers, macro keys, a proprietary Bluetooth protocol instead of plain
  HID), that layer will **not** reach the Linux/XFCE side — Termux/XFCE only see
  raw HID reports Android's input stack forwards, not app-level translations.
  Check this before assuming "it'll just work."

## XFCE components hang
- `dbus-launch` (from `dbus-x11`) is required: we run
  `dbus-launch --exit-with-session xfce4-session`. If it still hangs, try
  `termux-x11 :0 -xstartup "xfce4-session"` (dbus-launch fails for some users).

## No audio (Task 5)
- Confirm PulseAudio on the Termux side loaded the TCP module:
  `pactl list modules short | grep native-protocol-tcp`.
- Inside Debian, `PULSE_SERVER` must be `127.0.0.1` (exported via
  `~/.desktop-env.sh`). Check with `echo $PULSE_SERVER` and `pactl info`.
- Start order matters: PulseAudio must be running (start-desktop.sh does this)
  before Debian apps try to play.

## Node too old for Claude Code
- apt's Node can be < 18. We install Node 20 from NodeSource. nvm is an
  alternative if NodeSource ever fails on this arch.

## Keep the desktop alive while the phone sleeps (Task 7)
- Acquire a Termux wakelock: `termux-wake-lock` (or via the Termux notification).
- Disable Android battery optimization for Termux / Termux:X11 so they aren't
  killed in the background.

## Panel/taskbar looks wrong after Task 8 (GUI polish)
- `debian-provision.sh` pre-writes `xfce4-panel.xml` (Whisker Menu + pinned
  launchers + taskbar + clock). XFCE's panel XML schema has shifted slightly
  across versions, so this is best-effort, not guaranteed pixel-perfect.
- Fix: arrange the panel once by hand (right-click it → Panel → Add New Items /
  Panel Preferences) — it persists from then on; no need to re-run provisioning.
- The four pinned launcher icons (Terminal, Files, Firefox, Claude Code) are
  built from each app's real `.desktop` file where apt provides one; if an icon
  is missing/blank, that app's `.desktop` filename may differ from what
  provisioning expected (`xfce4-terminal.desktop`, `thunar.desktop`,
  `firefox-esr.desktop`) — check `/usr/share/applications/` and re-add manually
  via the panel's "Add New Items" if so.

## GUI launcher (Task 8, Termux side)
- `setup/20-gui-launcher.sh` needs the **Termux:Widget** APK (F-Droid) for
  tap-to-launch home-screen icons, and the **Termux:API** APK (F-Droid) for the
  Start/Stop notification — same "APK is separate from the package" gotcha as
  Termux:X11. Installing just the `termux-api` package (done by the script)
  isn't enough on its own.
- Android 13+ requires notification permission granted to Termux:API once, and
  background-triggered notification actions are more reliable with battery
  optimization disabled for Termux:API too (same setting already used for
  Termux / Termux:X11 in Task 7).
- If the notification never appears, that's expected until the Termux:API app
  is installed and permitted — re-run `setup/20-gui-launcher.sh` afterward.

## Wireless monitor ("Screencast") — mirror only, and it lags
- `Settings → More connection settings → Screencast` mirrors the whole phone
  screen (including a fullscreen Termux:X11 desktop) wirelessly via Miracast or
  Google Cast — no root, no app install. Not yet confirmed on this exact
  phone/firmware; worth a quick on-device check before relying on it.
- This is mirroring, not a true second wireless "extended desktop" — RedMagic's
  real taskbar/windowed Console Mode is documented only over the wired DP-Alt
  cable.
- Expect real lag: Miracast ~100-200ms, Chromecast/Google Cast 250ms-1000ms+.
  Fine for glancing at the desktop from across the room; noticeably laggy for
  dragging windows or typing. See `docs/PHASE2-EXPLORATION.md` for detail.

## Freeform Android windows (Task 9, experimental)
- `setup/30-enable-freeform-windows.sh` flips four `adb shell settings put
  global ...` flags (same mechanism as the earlier phantom-process-killer fix)
  to unlock Android's built-in freeform multi-window support. Needs a reboot to
  take effect, and needs ADB wireless debugging already paired (the pairing
  code is one-time-use, but a saved wireless-debugging connection usually
  survives reboots once paired).
- RedMagic's Android skin may block this even with the flags set — its own
  desktop-mode implementation has reported similar bugs elsewhere. Not a
  guaranteed win; see `docs/PHASE2-EXPLORATION.md` for the full picture and the
  next steps (Shizuku, then Smart Dock or Taskbar) if it does work.
- Fully reversible: rerun with each value set to `0` (or `false` for the
  boolean-looking ones) to revert.

## Shizuku (no-root privilege bridge)
- Confirmed safe for Play Integrity — runs as the ordinary ADB `shell` UID,
  never root, never touches verified boot. See `docs/PHASE2-EXPLORATION.md`
  for the full source-verified breakdown.
- **Doesn't survive a reboot without root** — Shizuku's own docs say the
  service must be restarted via ADB after every boot. Don't assume it's still
  running after the phone restarts; check the Shizuku app before relying on
  it. An in-app "start on boot" toggle exists but isn't fully verified as
  reliable on this device — test it rather than trust it.
- Needed by: Clackpad's system-wide-pointer trackpad mode, Smart Dock's real
  freeform window resize/snap/close, and Taskbar's simplified setup flow.

## Clackpad (custom IME) inside the XFCE desktop
- Clackpad is the project owner's own Android IME (on-screen keyboard app,
  not yet on the Play Store) — not a hardware product. Its trackpad moves the
  text cursor / arrow-key-style navigation without Shizuku, or a real
  system-wide pointer with Shizuku enabled.
- Termux:X11 is confirmed (source-level) to use Android's real system IME
  framework — no hardcoded keyboard, no allow-list — so Clackpad should be
  selectable and usable inside the desktop like any other IME. Untested in
  practice by anyone as of this writing.
- Caveat: Termux:X11 can't expose real text-field content to any IME (it has
  no way to read inside an X11 window), so it feeds a fake placeholder
  instead. This can affect IME features that depend on real surrounding text,
  even though basic typing and directional cursor moves should be fine.
- The Shizuku-powered pointer mode should, in principle, be able to move the
  cursor inside the XFCE desktop too — Termux:X11's rendering surface is a
  normal touchable Android View, and Shizuku's `INJECT_EVENTS` grant is the
  same system-wide input-injection primitive an existing real app
  (`android-desktop-touchpad`) already uses for exactly this purpose. Not
  confirmed in practice for this specific combination.
- See `docs/PHASE2-EXPLORATION.md` for the fast on-device tests to confirm
  each piece.

## No root — if a step seems to need it
- Stop. There is a userspace path for everything in this phase (proot-distro is
  the whole point). Do not reach for Magisk/root. Flag it instead.

---

## Sources consulted
- Termux:X11 — <https://github.com/termux/termux-x11>
- Termux:X11 usage guide — <https://ivonblog.com/en-us/posts/termux-x11/>
- proot-distro Linux in Termux — <https://termuxtools.com/proot-distro-linux-termux/>
- Debian proot setup (Termux-Desktops) — <https://deepwiki.com/LinuxDroidMaster/Termux-Desktops/6.2-debian-proot-setup>
- Forward audio proot-distro → Android — <https://gist.github.com/MS-Jahan/882a2d5db121c368eb6d88b5215e9407>
- PulseAudio in chroot/proot — <https://github.com/termux/termux-packages/issues/12289>
- xfsettingsd pointer property scheme — <https://github.com/xfce-mirror/xfce4-settings/blob/master/xfsettingsd/pointers.c>
- xfwm4 default keyboard shortcuts — <https://raw.githubusercontent.com/xfce-mirror/libxfce4ui/master/libxfce4kbd-private/xfce4-keyboard-shortcuts.xml>
- Termux:X11 external-mouse/trackpad issues — termux-x11 #403, #598, #297 on GitHub
- Termux:Widget — <https://github.com/termux/termux-widget>
- Termux:API `termux-notification` — <https://github.com/termux/termux-api-package>
- Taskbar (no-root freeform windows) — <https://github.com/farmerbb/Taskbar>
- Smart Dock (Shizuku-backed freeform window management) — <https://github.com/axel358/smartdock>
- Shizuku (no-root privilege bridge) — <https://github.com/RikkaApps/Shizuku>
- android-desktop-touchpad (Shizuku input injection example) — <https://github.com/prespic/android-desktop-touchpad>
- AOSP shell UID permissions (INJECT_EVENTS, MANAGE_ACTIVITY_TASKS) — <https://android.googlesource.com/platform/frameworks/base/+/master/packages/Shell/AndroidManifest.xml>
- mekhontsev/magicdesk (root-based comparison) — <https://github.com/mekhontsev/magicdesk>
