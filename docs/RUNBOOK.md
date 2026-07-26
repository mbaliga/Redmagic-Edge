# Phase 1 Runbook — step by step

Run everything **on the phone, in Termux**, unless a step says "inside Debian".
Validate on the **phone screen** (Tasks 1–6) before touching the monitor (Task 7).

---

## Task 1 — Termux base + X server

```bash
bash setup/00-termux-base.sh
```

Installs: `x11-repo`, `termux-x11-nightly`, `pulseaudio`, `proot-distro`, and
runs `termux-setup-storage` (accept the Android prompt).

**Done when** — a blank X surface renders without crashing:

```bash
export XDG_RUNTIME_DIR="$TMPDIR"
termux-x11 :0 &
am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity
# Open the Termux:X11 app -> black X screen, no crash.
# Stop:
am broadcast -a com.termux.x11.ACTION_STOP -p com.termux.x11
pkill -f com.termux.x11 || true
```

> Reminder: the **APK** and the **`termux-x11-nightly` package** are different
> things. You need both.

---

## Task 2 — Debian guest via proot-distro

```bash
bash setup/10-install-debian.sh
```

Installs Debian and runs `setup/debian-provision.sh` inside it (apt upgrade,
`en_US.UTF-8` locale, and a non-root daily user — `redmagic` by default).

**Done when** — you can log in and apt works:

```bash
proot-distro login debian --user redmagic --shared-tmp
# inside:
whoami            # -> redmagic
sudo apt-get update
exit
```

---

## Task 3 — XFCE + core apps (inside Debian)

Handled by `debian-provision.sh` (run in Task 2). It installs:
`xfce4 xfce4-terminal xfce4-goodies dbus-x11 x11-apps firefox-esr`.
Thunar ships with `xfce4-goodies`.

**Done when** — those packages installed cleanly (rendering is checked in Task 4).

---

## Task 4 — Launch the desktop (the payoff)

```bash
./start-desktop.sh
```

Starts PulseAudio, the Termux:X11 server, foregrounds the app, then enters
Debian as the daily user and runs `xfce4-session` via `dbus-launch`.

**Done when** — a usable XFCE desktop appears on the phone, with a working
terminal, Thunar, and Firefox.

---

## Task 5 — Audio bridge

PulseAudio is started by `start-desktop.sh` with `module-native-protocol-tcp`
on `127.0.0.1`; `PULSE_SERVER=127.0.0.1` is exported inside Debian (via
`~/.desktop-env.sh`). Test it:

```bash
# inside the XFCE terminal (Debian):
bash ~/Redmagic-Edge/setup/audio-test.sh   # or wherever the repo is mounted
```

**Done when** — a Linux app (the test tone, or a YouTube tab in Firefox) is
audible on the phone speakers.

---

## Task 6 — Claude Code inside the desktop

Node 20 (NodeSource) + `@anthropic-ai/claude-code` are installed by
`debian-provision.sh`.

**Done when** — in the XFCE terminal:

```bash
node --version    # >= 18
claude            # launches
```

---

## Task 7 — External monitor

1. Plug the DP-Alt hub: video out + USB-A for kb/mouse + PD-in for charging.
2. Let Android mirror to the monitor.
3. Run `./start-desktop.sh`.
4. Tune resolution/DPI: XFCE → Settings → Display, and
   Settings → Appearance → Fonts → DPI for scaling on a large panel.
5. Pair Bluetooth kb/mouse, or use the ones wired through the hub.

**Done when** — XFCE fills the monitor, input works, and the **phone screen can
sleep** while the desktop stays up.

> Tip: keep Termux alive across screen-off by acquiring a wakelock — Termux
> notification → "Acquire wakelock", or run `termux-wake-lock`.

---

## Task 8 (optional) — GUI launcher + panel polish

`debian-provision.sh` (Task 2/3, re-run is safe/idempotent) now also wires up:
- A Whisker Menu + pinned taskbar (Terminal, Files, Firefox, Claude Code) in
  XFCE — already installed by `xfce4-goodies`, just switched on.
- `Super+space` opens the menu; `Super+arrows` snap/maximize windows;
  `Super+d` shows the desktop.
- A generic trackpad/mouse auto-tuner that turns on tap-to-click, natural
  scrolling, and a faster pointer speed for whatever real pointer device is
  connected (see `docs/TROUBLESHOOTING.md` if it doesn't pick up your device).

Then, in Termux (Task 8's Termux half):

```bash
bash setup/20-gui-launcher.sh
```

Sets up Termux:Widget shortcuts and a Start/Stop notification so launching the
desktop no longer requires opening Termux and typing a command.

**Done when** — after installing the Termux:Widget and Termux:API companion
APKs (F-Droid, same "APK is separate from the package" rule as Termux:X11):
tapping a home-screen shortcut (or notification button) starts/stops the
desktop, and the XFCE panel shows a working Start menu + taskbar on next boot.

---

## Task 9 (experimental) — no-root Android apps in windows

```bash
bash setup/30-enable-freeform-windows.sh
```

Flips four reversible `adb shell settings put global ...` flags (same
mechanism as the earlier phantom-process-killer fix) to try unlocking
Android's built-in freeform multi-window support — a no-root path toward
running native Android apps in resizable windows next to the XFCE desktop,
the way `mekhontsev/magicdesk` does with root.

**Done when** — after rebooting and plugging into the monitor, an ordinary
Android app can be dragged into a resizable floating window. This is a
go/no-go test, not guaranteed to work on RedMagic's Android skin — see
`docs/PHASE2-EXPLORATION.md` for the full picture, the next step (the
"Taskbar" app) if it passes, and the honest state of wireless monitor
casting as a bonus path.
