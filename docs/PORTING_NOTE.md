# Redmagic-Edge: porting note

> **PLAN, 2026-10-06. Nothing here has been built or run on any device.** Disposition note for the
> constellation porting program, `Personal-Tracker/PORTING_PROGRAM.md`, which defines the `OQ-n`, `F-n`,
> `P-*` and `R1`-`R12` ids used below. Every statement about a target platform has evidence `PLAN`.

## 1. What this repo is
Phase 1 scripts for a no-root XFCE desktop on a RedMagic phone: Termux, a proot-distro Debian guest (aarch64)
and Termux:X11 (`README.md`). `STATE.md`: "Phase 1 complete + owner-verified; parked"; Phase 2 and 3 not
started. Bash only (`setup/*.sh`, `start-desktop.sh`), two docs, and one six-hourly housekeeping workflow
(`.github/workflows/cleanup-artifacts.yml`). No application code, tests, build or LICENSE file.

## 2. Disposition: tier skip, and a Linux target host
Master §5 row: tier **skip**; Linux "a Linux target host"; other targets n/a; no gate before any wave. The
scripts are Android/Termux tooling by design (README: meant to run on the device), so nothing here ports.
What the repo supplies is an environment: the program's Linux device gate "the RedMagic under Termux:X11"
(master §4.2, wave P-LX) is this setup, and every Linux port must start on it.

| Target | Feasibility | Approach and blockers | Effort (eng-weeks, estimate) | Evidence today |
|---|---|---|---|---|
| Ubuntu Touch | not-applicable | Termux and proot-distro are Android tools; no UT form | 0 | PLAN |
| Linux desktop | not-applicable as a port; **target host** | profile in §3; repo unchanged | 0 | PLAN |
| iOS / iPadOS, macOS, Windows | not-applicable | same reason | 0 | PLAN |

Wave: **P-LX** (master §7), device-gate host only, no build-entry; no CI lane, package or signing is added (R3, R6).
Foundation: consumes F10 (tarball and `install.sh` template), F11 (the checklist, not held here), F6 (key tier)
and F8 (CPU engine builds); provides the §3 profile as input to F10 and F11, nothing else.

## 3. Host profile for every Linux port (master §4.2)
Read from the scripts, not measured; "unknown" items go to `DEVICE_CHECKLIST_LINUX.md` (F11), `NEEDS-DEVICE-VALIDATION`.

| Aspect | Set up by the repo | Consequence for a ported app |
|---|---|---|
| Display | X11 only: `termux-x11 :0`, `DISPLAY=:0` (`start-desktop.sh`) | no Wayland; ship the X11 path |
| GL, Vulkan | software GL: `LIBGL_ALWAYS_SOFTWARE=1`, `GALLIUM_DRIVER=llvmpipe`, xfwm4 compositing off (`setup/debian-provision.sh`); proot has no GPU driver, so Vulkan is treated as absent, never probed | CPU paths only; a stalled X server raises the "Termux:X11 isn't responding" ANR (`docs/TROUBLESHOOTING.md`) |
| Bluetooth | scripts install no BlueZ; keyboard and mouse pair in Android and arrive as X input | no RFCOMM or BLE from the guest |
| Guest | Debian aarch64 under proot-distro, user `redmagic`, `--shared-tmp`; no init system started (session is `dbus-launch --exit-with-session xfce4-session`); Debian release and glibc not pinned: unknown | build against master §4.2's glibc baseline; record the guest's glibc at checklist time |
| Runtime | scripts install Node 20 and Claude Code, no JDK, no flatpak (master §4.2: no flatpak under proot) | an app-image brings its own runtime; JVM under proot and Skiko's software render path are unknown |
| Audio, secrets | PulseAudio on the Termux side over TCP `127.0.0.1`, guest `PULSE_SERVER=127.0.0.1`; no secret-service daemon configured, presence in the guest unknown | clients play through it; key tier unknown, file tier at worst, shown in the UI (I-2, OQ-22) |

**Install path (proposed, unverified):** jpackage app-image tarball plus `install.sh`, linux-arm64 (master §4.2,
F10), run in the guest as `redmagic` into `$HOME`, no `sudo`, not Flatpak. Delivery to the guest is unsettled.

## 4. Binding rules that still apply
- **No root, ever; Play Integrity intact** (`README.md`): a port's install step never needs Android root.
- **Do not regress the freeze fix** (`README.md`, `docs/TROUBLESHOOTING.md`): compositing off, software GL; a
  port needing another render setting sets it in its own launcher, not here (R1).
- **Environment honesty (I-4):** this container cannot run any of it; Phase 1 is owner-verified, and whether a
  ported app runs under proot is unknown. I-1 (no telemetry) and I-3 (colour never alone) bind the apps run here.

## 5. Open questions for the owner
1. **OQ-5 (hardware stance):** names other Linux device gates but not the phone. Is the RedMagic under
   Termux:X11 an accepted P-LX device-gate host? Blocks its row in `DEVICE_CHECKLIST_LINUX.md`.
2. **OQ-22 (secret custody):** which key tier is acceptable on this host. Blocks any port holding a key here.
3. **Proposal, no master id:** a read-only probe script printing glibc, GL renderer, Vulkan, secret-service
   and audio facts, to turn §3's unknowns into measurements. Needs a repo decision; not in `STATE.md`'s plan.
4. **No master id (would extend OQ-12):** the public repo has no LICENSE file. Blocks nothing in a port.

## 6. Sources read
`README.md`, `STATE.md`, `start-desktop.sh`, `setup/*.sh`, `docs/*.md`, `.github/workflows/cleanup-artifacts.yml`; master §0-§4, §5 (this row), §6-§8.
