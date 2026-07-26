# Phase 1.5 exploration — wireless monitor, Android apps in windows, Clackpad

Stretch goals beyond the core Phase 1 build, researched but only partly
implemented. This doc is deliberately honest about what's confirmed vs.
guessed — treat anything marked "unverified" as a thing to test on-device,
not a promise.

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

**Short answer: plausible, staged, meaningfully strengthened by Shizuku —
but still short of full parity with a root-based approach.**

`mekhontsev/magicdesk` gets Android apps into a taskbar/Alt+Tab
environment by hooking WM Shell — the library that runs *inside* the
system-privileged SystemUI process and owns cross-display task
organizing — and needs root to reach it, by their own admission
("Android does not expose the required cross-display desktop APIs to
ordinary third-party applications"). That capability is out of reach here
on purpose — this project's hard constraint is **no root, ever**.

There is a no-root alternative, staged as increasing levels of capability:

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
   this is where it stops for this step — not a guaranteed win, just the
   cheapest way to find out.

2. **Shizuku** (`github.com/RikkaApps/Shizuku`) — a no-root privilege
   bridge that runs a background service under the ADB **shell** UID
   (2000, the same UID `adb` itself uses), reachable by apps that
   integrate its SDK. Confirmed directly against AOSP's shell manifest:
   the shell UID is granted `INJECT_EVENTS` (system-wide synthetic
   touch/pointer/key injection — the same primitive `adb shell input tap`
   uses) and `MANAGE_ACTIVITY_TASKS` plus related window/display
   permissions — a real, non-trivial slice of what a privileged app can
   do, all without root. See the dedicated **Shizuku** section below for
   activation, persistence, and Play Integrity details.

3. **Smart Dock** (`axel358/smartdock`, F-Droid, ~1.4k★, actively
   maintained) — goes further than Taskbar: its Shizuku integration
   genuinely calls Android's `IActivityManager` to list, resize, snap,
   and close real freeform windows, not just flip a settings flag. This
   is the strongest confirmed no-root window-management tool found.
   Caveat: it still has open issues with freeform windows breaking
   through its own UI and no clean native external-monitor support (a
   community workaround is pairing it with Taskbar for external-display
   detection) — even the most capable Shizuku-based tool hasn't cracked
   reliable external-monitor handling.

4. **Taskbar** (`github.com/farmerbb/Taskbar`, also on F-Droid) — an
   open-source, no-root app providing an actual taskbar + Start-menu-style
   app drawer + freeform window management, specifically designed for
   "external monitor gets a desktop, phone keeps its own screen." Its
   Shizuku support (since v6.2, confirmed from source) turned out to be
   narrow — a one-time self-grant of `WRITE_SECURE_SETTINGS`, functionally
   equivalent to step 1's manual ADB grant, nothing more. Still useful for
   its taskbar/launcher UI even though its Shizuku usage isn't as deep as
   Smart Dock's. Last tagged release ~21 months old, open Android 14+
   compatibility questions in its issue tracker — test standalone before
   trusting it. **Not installed by this repo** — sideload from
   GitHub/F-Droid (not the Play Store build) once step 1 passes.

5. **Running Taskbar/Smart Dock alongside the XFCE/Termux:X11 desktop,
   same monitor** — untested, unpublished combination. There's real
   supporting evidence it's structurally possible: Termux:X11 is
   independently confirmed (termux-x11 issue #581) to already run as an
   ordinary freeform window on another Android 14 device, meaning
   Android's own WindowManager can host it as one window among others
   rather than it needing to own the whole display. But all of these
   tools want to claim the external display's default/home slot, so
   expect to disable Termux:X11's auto-fullscreen-on-external-display
   behavior and iterate. Nobody has published this exact recipe — budget
   real hands-on debugging if you chase it.

**Where the ceiling actually is:** magicdesk's own README states it needs
root specifically because the cross-display taskbar/Alt+Tab experience
requires registering as the system's task organizer inside WM Shell,
which lives in the platform-signed SystemUI process — a privilege level
above what shell UID (even via Shizuku) can reach, no matter how many of
its permissions you use. Shizuku gets meaningfully closer to magicdesk
(real task list/resize/close, per Smart Dock) than the plain ADB flags
alone, but full parity on **external-display** window management
specifically appears to need true root. Treat that as a real wall, not
something more engineering effort resolves.

**On Play Integrity:** no reports found — positive or negative — of the
freeform/desktop-mode `Settings.Global` flags in step 1 affecting Play
Integrity or SafetyNet attestation. Integrity checks are keyed off
bootloader/verified-boot/system-partition state, which these flags don't
touch, consistent with the absence of reports. Shizuku specifically is
confirmed *not* to affect Play Integrity either — see below.

**Also worth knowing:** Android 16 QPR3 (per the Android Developers Blog,
March 2026) brought an *official*, Google/Samsung co-developed desktop
windowing framework for external displays — currently confirmed only on
Pixel 8/9/10 and newer Samsung tablets/foldables. No sign RedMagic has
adopted it yet; their OEM skin still runs its own separate (and reportedly
buggier) desktop-mode path. Worth rechecking RedMagic OS changelogs
periodically — if they ever adopt the AOSP stack, it likely obsoletes
most of the above with something more solid.

---

## Shizuku — activation, persistence, and safety

- **Activation**: install the Shizuku app, then either (a) pair once via
  Android 11+'s built-in "Wireless debugging → Pair device with pairing
  code" flow entirely inside the Shizuku app (no PC, no Termux command
  needed for this step), or (b) run its starter script once via `adb
  shell` from a PC/Termux. This project's phone already has wireless
  debugging paired from earlier ADB work, so path (a) should be the
  quickest.
- **It does NOT survive a reboot without root** — confirmed directly in
  Shizuku's own docs: *"On non-rooted devices, Shizuku needs to be
  manually restarted with adb every time on boot."* Only the *pairing*
  (the trust relationship) survives; the running service and the
  Wireless Debugging toggle itself both reset. Two ways to automate the
  restart exist — an in-app "start on boot" toggle (needs a one-time
  `WRITE_SECURE_SETTINGS` grant; the maintainer had Play-policy
  reservations about it historically, so verify it actually works on
  this device rather than assuming it does), or a Termux:Boot/Tasker
  script that re-runs the starter command after boot (well-precedented
  in the community, but fiddly around port discovery and the toggle
  resetting — not shipped here as a script because it's genuinely
  device-specific to get right, not because it's a bad idea).
- **Play Integrity: confirmed not a risk.** Verified directly against
  AOSP's `packages/Shell/AndroidManifest.xml` — Shizuku runs entirely as
  the ordinary `shell` UID (2000), the same one `adb` itself uses. It
  never obtains root, never patches boot images, never touches verified
  boot or SELinux policy — none of which is what Play Integrity's device
  attestation actually checks. The one soft caveat: a small minority of
  unusually strict apps (some banking/gambling apps) check whether
  Developer Options/USB-or-Wireless-debugging is *itself* turned on, as
  their own heuristic, separate from Play Integrity entirely — but that
  exposure already exists from the ADB wireless debugging this project
  already uses for other tweaks, so Shizuku doesn't add a new one.
- **Capability, confirmed via AOSP source**: the shell UID is granted
  `INJECT_EVENTS` (system-wide synthetic input — exactly what a
  Shizuku-powered pointer/trackpad feature needs) and
  `MANAGE_ACTIVITY_TASKS` plus related window/display permissions (what
  Smart Dock uses for real freeform window control). Real shipping
  proof: `github.com/prespic/android-desktop-touchpad` uses Shizuku's
  `INJECT_EVENTS` grant specifically to drive a virtual mouse pointer
  over whatever's on screen — architecturally the same thing Clackpad's
  Shizuku-enabled trackpad mode would be doing.

---

## Clackpad

Clackpad is the user's own custom Android IME (input method / on-screen
keyboard app), not yet published to the Play Store. Its trackpad has two
modes: without Shizuku, it moves the text cursor / acts like arrow-key
navigation (scoped to whatever text field is focused); with Shizuku
enabled, it moves a real system-wide pointer.

**Will Clackpad even work inside the XFCE desktop (via Termux:X11)?**
Confirmed at the source level: **yes, it should.** Termux:X11's rendering
surface is a genuine Android `View` that overrides the standard
`onCreateInputConnection()` hook and shows/hides the keyboard via the
normal `InputMethodManager.toggleSoftInput()` call — the exact mechanism
any Android app uses to invoke the system-selected IME. There is no
hardcoded keyboard UI in Termux:X11 and no allow-list blocking third-party
IMEs. Whatever Clackpad commits via the standard `InputConnection` API is
traced end-to-end (Java → JNI → the X server's own event queue) into real
X11 `KeyPress`/`KeyRelease` events delivered to whatever app has X focus
inside the Debian guest. Nobody has documented actually doing this with a
self-written IME before, so it's unverified in practice, but nothing in
Termux:X11's code would block it.

**One caveat for the non-Shizuku (text-cursor) mode specifically**:
Termux:X11 can't read what's actually inside the X11 window's text field
— it feeds any IME (including Gboard) a fake placeholder instead of real
surrounding text (`getTextBeforeCursor`/`getEditable` are stubbed out,
since it has no way to inspect X11 window contents). Basic typing and
simple directional cursor moves should still work fine; anything in
Clackpad that depends on reading real text around the cursor may behave
oddly specifically inside the X11 desktop.

**Will the Shizuku-powered pointer mode actually move the cursor inside
the XFCE desktop?** Architecturally plausible, not yet confirmed in
practice. Termux:X11's desktop surface is a normal touchable Android
`View`, so injected system-wide touch/gesture events (via Shizuku's
`INJECT_EVENTS`, the same mechanism `android-desktop-touchpad` already
uses for exactly this purpose) should be able to land on it like any
other touch input — but this specific combination hasn't been tested by
anyone as far as research could find.

**Fast ways to test, cheapest first:**
1. Set Clackpad as the system default keyboard, open Termux:X11, tap a
   terminal text field — confirm Clackpad's UI appears and typed
   characters land correctly.
2. With no text field focused (blank desktop), try the trackpad gesture
   with Shizuku *off* — should do nothing to the real pointer, confirming
   the non-Shizuku mode is correctly scoped to focus-navigation, not
   pointer control.
3. Get Shizuku running (see the Shizuku section above), then repeat the
   trackpad gesture with no text field focused — if the pointer moves
   inside the XFCE desktop, the whole chain works end to end.

No repo automation needed for any of this — it's testing an app (Clackpad)
against another app (Termux:X11), both outside this repo's scripts.

**Update — test 2 confirmed on-device (owner-verified, non-Shizuku mode):**
a screen recording of Clackpad's trackpad on the blank XFCE desktop (no text
field focused) shows exactly the predicted Architecture-1 behavior: the real
XFCE/X11 mouse cursor never moves — pixel-identical position across the
entire clip — while the trackpad gesture instead cycles focus between the
desktop icons (Trash → Home → File System), i.e. real directional/arrow-key
navigation reaching XFCE, not pointer control. This is a meaningful positive
result on its own: it confirms the full chain (Clackpad → Android IME
framework → Termux:X11 → real X11 KeyPress events → XFCE) works end to end
in practice, not just in source-level theory. Remaining unconfirmed: typing
into an actual focused text field (terminal/Firefox), and the Shizuku
pointer-mode test (test 3 above).
