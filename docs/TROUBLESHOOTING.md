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
