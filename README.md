# Redmagic-Edge — Mobile Desktop, Phase 1

> **Constellation** · `state: parked` · private · [registry: `Personal-Tracker/CONSTELLATION.md`](https://github.com/mbaliga/Personal-Tracker/blob/main/CONSTELLATION.md)
> No-root XFCE Linux desktop on a RedMagic phone via Termux + proot-distro + Termux:X11.

A **no-root** Linux desktop (XFCE) running inside **Termux** on a **RedMagic 11 Pro**,
rendered through **Termux:X11**, driving an external monitor over USB-C DP-Alt.
This is Phase 1 of a layered "DeX-like" setup.

> **Where this runs:** ON THE PHONE'S TERMUX. Not on a PC, not on the Dell
> homelab. These scripts are authored for `aarch64` Android/Termux and are meant
> to be executed on the device.

## Hard constraints

- **NO ROOT. EVER.** Play Integrity stays intact. No Magisk / KernelSU / LSPosed,
  no bootloader unlock, no custom recovery. Everything here is userspace
  (Termux + proot-distro + Termux:X11).
- **Phone-first.** No desktop machine is assumed.
- Each step leaves the system in a working, demonstrable state.

## Prerequisites (already on the device)

- Termux (F-Droid / GitHub build — **not** the dead Play Store build).
- The **Termux:X11 companion APK** (F-Droid/GitHub). This is separate from the
  `termux-x11-nightly` package installed below — you need **both**.
- A Bluetooth (or wired-through-hub) keyboard/mouse.
- DP-Alt USB-C hub is optional for Tasks 1–6; only Task 7 needs it.

## What's in here

| Path | Task(s) | Run where |
|------|---------|-----------|
| `setup/00-termux-base.sh`    | 1        | Termux |
| `setup/10-install-debian.sh` | 2,3,5,6  | Termux (calls the provisioner) |
| `setup/debian-provision.sh`  | 2,3,5,6,8| inside Debian (auto-invoked) |
| `start-desktop.sh`           | 4,5,7    | Termux |
| `stop-desktop.sh`             | 4,8      | Termux |
| `setup/audio-test.sh`        | 5        | inside Debian |
| `setup/20-gui-launcher.sh`   | 8 (optional)     | Termux |
| `setup/30-enable-freeform-windows.sh` | 9 (experimental) | Termux |
| `docs/RUNBOOK.md`            | all      | step-by-step with done-when checks |
| `docs/TROUBLESHOOTING.md`    | all      | gotchas & fixes |
| `docs/PHASE2-EXPLORATION.md` | 9, wireless | honest write-up of what's proven vs. guessed |

## Quick start (on the phone, in Termux)

```bash
git clone <this repo> ~/Redmagic-Edge && cd ~/Redmagic-Edge

bash setup/00-termux-base.sh      # Task 1: Termux base + X server
bash setup/10-install-debian.sh   # Tasks 2,3,5,6: Debian + XFCE + audio + Node + Claude Code
./start-desktop.sh                # Task 4: bring up the desktop on the phone screen
```

Then for **Task 7**: plug the DP-Alt hub (video + USB-A kb/mouse + PD-in), let
Android mirror, and re-run `./start-desktop.sh`.

```bash
bash setup/20-gui-launcher.sh     # Task 8 (optional): tap-to-launch, no typing
bash setup/30-enable-freeform-windows.sh  # Task 9 (experimental): Android apps in windows
```

Tunables via env vars: `DISTRO` (default `debian`), `USERNAME` (default
`redmagic`), `DISP` (default `:0`).

## Definition of done (Phase 1)

One script (`start-desktop.sh`) brings up a real XFCE Linux desktop on the
external monitor — no root, Play Integrity intact — with a working terminal,
file manager (Thunar), browser (Firefox ESR), audio, and Claude Code. The phone
screen can sleep while the desktop stays up.

## Out of scope this phase

- No root / Magisk / LSPosed / bootloader unlock.
- Not targeting the Dell (that's Phase 2: Moonlight/Remmina).
- No native Android desktop mode (Phase 3).

## Stretch goals (Phase 1.5, partly explored)

Tasks 8-9 above and a wireless-monitor option go beyond the core Phase 1
scope — a tap-to-launch GUI layer, and a no-root attempt at running native
Android apps in resizable windows (what `mekhontsev/magicdesk` does, but that
project requires root; we don't). See `docs/PHASE2-EXPLORATION.md` for an
honest account of what's confirmed vs. still unverified on this exact device.

---

### Note on validation

These scripts were authored and reviewed against the current Termux / `termux-x11`
/ proot-distro behavior, but they target Android `aarch64` and **cannot be
executed in the cloud build container** that produced this branch. Run them on
the phone and use `docs/RUNBOOK.md` to confirm each task's done-when check.
Sources consulted are linked in `docs/TROUBLESHOOTING.md`.

## Do not touch

- The working **`start-desktop.sh` runbook flow** — freeze fixes (no compositing / software GL) prevent proot freezes; don't regress them.
- **No root** — pure userspace (Termux + proot-distro + Termux:X11); Play Integrity must stay intact.
