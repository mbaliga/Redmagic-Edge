## Current state
Phase 1 complete + owner-verified. Phase 1.5 (GUI launcher/panel polish,
generic trackpad tuning, no-root freeform-window experiment) added on top —
implemented, syntax-checked, **not yet owner-verified on-device**.

## Next
- Owner to run `setup/20-gui-launcher.sh` and Task 8's provisioning re-run,
  confirm the panel/Whisker Menu/shortcuts/keybinds/notification work as
  documented in `docs/RUNBOOK.md` Task 8.
- Owner to try `setup/30-enable-freeform-windows.sh` (Task 9, experimental)
  and report the go/no-go drag-a-window test.
- Clackpad is confirmed to be the owner's own custom Android IME (not
  hardware). Non-Shizuku trackpad mode is owner-verified on-device: it
  drives XFCE focus-navigation (arrow-key-style, cycling desktop icon
  selection) through the full Clackpad → Termux:X11 → X11 → XFCE chain,
  exactly as the architecture research predicted. Still to verify: typing
  into a real focused text field, and the Shizuku pointer-mode test.
- Phase 2 Moonlight/Remmina; Phase 3 native Android desktop — not started.
- See `docs/PHASE2-EXPLORATION.md` for the wireless-monitor and Taskbar-app
  research that didn't turn into shipped automation yet.

## Owner-verified
Phase 1 (Tasks 1-7) — all runtime, confirmed working on-device.
Phase 1.5 (Tasks 8-9) — not yet; scripts target aarch64 Android, can't run in
the cloud container that authored them.
Clackpad non-Shizuku trackpad mode (screen-recorded, see
`docs/PHASE2-EXPLORATION.md`) — confirmed working as designed.
