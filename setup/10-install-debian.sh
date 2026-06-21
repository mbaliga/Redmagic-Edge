#!/data/data/com.termux/files/usr/bin/bash
#
# Task 2 — Install the Debian guest, then provision it (Tasks 2,3,5,6).
# Run this INSIDE Termux on the phone, AFTER 00-termux-base.sh.
#
# Idempotent-ish: proot-distro refuses to reinstall an existing distro, which
# is fine — we just (re)run the provisioning step inside it either way.
#
set -euo pipefail

DISTRO="${DISTRO:-debian}"
# Daily-use non-root user created inside the guest. Override with USERNAME=...
USERNAME="${USERNAME:-redmagic}"

say() { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }

if ! command -v proot-distro >/dev/null 2>&1; then
  echo "ERROR: proot-distro not found. Run setup/00-termux-base.sh first." >&2
  exit 1
fi

say "Installing $DISTRO (skips if already installed)"
proot-distro install "$DISTRO" || echo "(already installed — continuing)"

# Locate the provisioning script that ships next to this one, and copy it into
# the guest's /root so we can execute it from inside the proot login.
HERE="$(cd "$(dirname "$0")" && pwd)"
PROV_SRC="$HERE/debian-provision.sh"
if [ ! -f "$PROV_SRC" ]; then
  echo "ERROR: $PROV_SRC missing." >&2
  exit 1
fi

say "Copying provisioning script into the guest"
GUEST_ROOT="$PREFIX/var/lib/proot-distro/installed-rootfs/$DISTRO/root"
cp "$PROV_SRC" "$GUEST_ROOT/debian-provision.sh"
chmod +x "$GUEST_ROOT/debian-provision.sh"

say "Provisioning the guest (apt upgrade, locale, user, XFCE, audio env, Node, Claude Code)"
# Run as root inside the guest; the script creates the non-root user itself.
proot-distro login "$DISTRO" --shared-tmp -- \
  env USERNAME="$USERNAME" bash /root/debian-provision.sh

cat <<NOTE

----------------------------------------------------------------------
Tasks 2/3/5/6 provisioning complete for guest: $DISTRO (user: $USERNAME)

Verify Debian login + apt (Task 2 done-when):
    proot-distro login $DISTRO --user $USERNAME --shared-tmp
    # inside: 'apt-get update' should work, 'whoami' -> $USERNAME

Next: launch the desktop with ./start-desktop.sh
----------------------------------------------------------------------
NOTE
