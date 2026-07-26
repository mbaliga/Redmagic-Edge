# Phase 1.5 exploration — wireless monitor + Android apps in windows

Two stretch goals beyond the core Phase 1 build, researched but only
partly implemented. This doc is deliberately honest about what's
confirmed vs. guessed — treat anything marked "unverified" as a thing to
test on-device, not a promise.

---

## Wireless monitor connection ("Wireless DeX" equivalent)

**Short answer: no true wireless *extended* desktop exists — only
mirroring, and mirroring has real lag.**

- RedMagic phones ship a built-in **Screencast** feature
  (`Settings → More connection settings → Screencast`) that mirrors the
  whole phone screen — including a fullscreen Termux:X11 window — over
  Miracast (direct phone-to-dongle, no home Wi-Fi needed) or Google
  Cast/Chromecast (needs a shared Wi-Fi network). This has shipped on
  RedMagic OS for years; it has **not been specifically verified on the
  11 Pro / RedMagic OS 11** — a 2-minute on-device check before relying
  on it.
- RedMagic's actual taskbar/windowed **Console/desktop mode** (the thing
  `mekhontsev/magicdesk` enhances) is documented **only** over the wired
  USB-C DP-Alt cable. No manual, forum thread, or review describes a
  wireless path to that specific mode — the wired cable looks like the
  only way in today.
- **Latency, stated honestly:** wired DP-Alt is essentially instant.
  Miracast runs ~100-200ms and degrades with Wi-Fi congestion. Google
  Cast/Chromecast mirroring is worse — 250ms-1000ms+, and is explicitly
  not built for real-time interaction. Neither is a substitute for the
  cable when you're dragging windows or typing; both are fine for
  glancing at the desktop from across the room.
- A receiver on the monitor side would be a Miracast-class wireless-HDMI
  dongle (e.g. ScreenBeam-class) for the lower-latency path, or a
  Chromecast/Google TV Streamer for the higher-latency, network-dependent
  path.
- A Bluetooth keyboard/trackpad paired to the phone should keep working
  normally regardless of wireless video-out — separate radio systems,
  independent code paths. Only theoretical risk is 2.4GHz band
  contention between Bluetooth and Wi-Fi Direct on some chipsets; modern
  combo chips (and both protocols preferring 5GHz when available) avoid
  this in practice.

**Not implemented as a script** — this is an OS Settings toggle, not
something this repo can automate. Worth trying once, framed as "check the
desktop from across the room," not a cable replacement.

---

## Android apps in floating windows, no root

**Short answer: plausible, staged, not proven as a full combo yet.**

`mekhontsev/magicdesk` gets Android apps into a taskbar/Alt+Tab
environment by hooking WMShell — and needs root to do it, by their own
admission ("Android does not expose the required cross-display desktop
APIs to ordinary third-party applications"). That capability is out of
reach here on purpose — this project's hard constraint is **no root,
ever**.

There is a no-root alternative, staged as three steps of increasing risk:

1. **`setup/30-enable-freeform-windows.sh`** (implemented, this repo) —
   four `adb shell settings put global ...` flags, the same mechanism
   already used earlier in this project to disable Android's phantom
   process killer. Unlocks AOSP's built-in (if OEM-dependent) freeform
   multi-window support and a stronger "desktop mode on external
   displays" flag. Fully reversible, no root, no bootloader change.
   **Go/no-go test:** after running it and rebooting, can you drag an
   ordinary Android app into a resizable window on the external monitor?
   If RedMagic's skin blocks it even with the flag set (their own
   desktop-mode implementation has reported similar bugs elsewhere),
   this is where it stops — not a guaranteed win, just the cheapest way
   to find out.

2. **Taskbar** (`github.com/farmerbb/Taskbar`, also on F-Droid) — an
   open-source, no-root app that turns step 1's raw freeform support into
   an actual taskbar + Start-menu-style app drawer + window management,
   specifically designed for exactly this "external monitor gets a
   desktop, phone keeps its own screen" scenario. Last tagged release is
   ~21 months old with open Android 14+ compatibility questions in its
   issue tracker — worth testing standalone (with ordinary Android apps)
   before assuming it's solid. **Not installed by this repo** — sideload
   it yourself from GitHub/F-Droid (not the Play Store build, to be sure
   you get the current one) once step 1 passes its go/no-go test.

3. **Running Taskbar alongside the XFCE/Termux:X11 desktop, same
   monitor** — untested, unpublished combination. There's real supporting
   evidence it's structurally possible: Termux:X11 is independently
   confirmed (termux-x11 issue #581) to already run as an ordinary
   freeform window on another Android 14 device, meaning Android's own
   WindowManager can host it as one window among others rather than it
   needing to own the whole display. But both Termux:X11 and Taskbar's
   Desktop Mode want to claim the external display's default/home slot,
   so expect to disable Termux:X11's auto-fullscreen-on-external-display
   behavior and iterate. Nobody has published this exact recipe — budget
   real hands-on debugging if you chase it, and don't expect a first-try
   clean result.

**On Play Integrity:** no reports found — positive or negative — of the
freeform/desktop-mode `Settings.Global` flags in step 1 affecting Play
Integrity or SafetyNet attestation. Integrity checks are keyed off
bootloader/verified-boot/system-partition state, which these flags don't
touch, consistent with the absence of reports. That's "low risk," not a
Google-documented guarantee — worth knowing before treating it as zero
risk.

**Also worth knowing:** Android 16 QPR3 (per the Android Developers Blog,
March 2026) brought an *official*, Google/Samsung co-developed desktop
windowing framework for external displays — currently confirmed only on
Pixel 8/9/10 and newer Samsung tablets/foldables. No sign RedMagic has
adopted it yet; their OEM skin still runs its own separate (and reportedly
buggier) desktop-mode path. Worth rechecking RedMagic OS changelogs
periodically — if they ever adopt the AOSP stack, it likely obsoletes
steps 1-3 above with something more solid.

---

## The "Clackpad" question

Research turned up **no product actually named "Clackpad"** matching "a
phone keyboard case with a built-in trackpad" — not on RedMagic's own
store, Amazon, AliExpress, Kickstarter, or any forum. This might be a
region-limited listing, an unreleased/rumored device, a different actual
name, or a small-batch product outside normal search indexes.

Rather than build config against a guess, `setup/debian-provision.sh`'s
new pointer-tuning step (`tune-pointer-input.sh`, installed under Task 8)
is written generically: it inspects whatever pointer device is actually
plugged in at session start and turns on tap-to-click/natural
scroll/faster pointer speed **if and only if** the device exposes real
libinput properties. This works for any real HID trackpad, whatever it's
actually called — you don't need to identify the exact product for the
base case to work.

If you do have a product link, screenshot, or listing for the actual
device, share it and this doc (plus the input config) can be tightened
with device-specific specifics instead of the generic fallback.
