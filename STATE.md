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
- If the real "Clackpad" product turns up (link/photo), tighten
  `tune-pointer-input.sh` with device-specific config instead of the generic
  auto-detect fallback.
- Phase 2 Moonlight/Remmina; Phase 3 native Android desktop — not started.
- See `docs/PHASE2-EXPLORATION.md` for the wireless-monitor and Taskbar-app
  research that didn't turn into shipped automation yet.

## Owner-verified
Phase 1 (Tasks 1-7) — all runtime, confirmed working on-device.
Phase 1.5 (Tasks 8-9) — not yet; scripts target aarch64 Android, can't run in
the cloud container that authored them.
