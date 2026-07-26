#!/usr/bin/env bash
#
# Runs INSIDE the Debian proot guest (as root). Invoked by 10-install-debian.sh.
# Covers:
#   Task 2 — apt upgrade, locale, non-root user
#   Task 3 — XFCE + core apps (terminal, Thunar, browser)
#   Task 5 — PULSE_SERVER wiring for the daily user
#   Task 6 — Node 18+ and Claude Code
#
# Idempotent: safe to re-run.
#
set -euo pipefail

USERNAME="${USERNAME:-redmagic}"
export DEBIAN_FRONTEND=noninteractive

say() { printf '\n\033[1;32m[guest] ==> %s\033[0m\n' "$*"; }

# --- Task 2: base, locale, user ----------------------------------------------
say "apt update && upgrade"
apt-get update
apt-get -y upgrade

say "Base tooling (sudo, locales, dbus, ca-certificates, curl)"
apt-get install -y sudo locales dbus-x11 ca-certificates curl wget nano

say "Generating en_US.UTF-8 locale"
sed -i 's/^# *en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
update-locale LANG=en_US.UTF-8

say "Creating non-root user: $USERNAME"
if ! id -u "$USERNAME" >/dev/null 2>&1; then
  useradd -m -s /bin/bash "$USERNAME"
  # No interactive passwd in proot; lock a default and grant passwordless sudo.
  echo "$USERNAME:$USERNAME" | chpasswd
fi
usermod -aG sudo "$USERNAME"
echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/"$USERNAME"
chmod 0440 /etc/sudoers.d/"$USERNAME"

# --- Task 3: XFCE + core apps ------------------------------------------------
say "Installing XFCE desktop + apps (this is the big download)"
apt-get install -y \
  xfce4 xfce4-terminal xfce4-goodies \
  dbus-x11 x11-apps xfconf xinput \
  firefox-esr

# --- Task 5: audio env for the daily user ------------------------------------
say "Wiring PULSE_SERVER + DISPLAY for $USERNAME"
USER_HOME="/home/$USERNAME"
PROFILE_SNIP="$USER_HOME/.desktop-env.sh"
cat > "$PROFILE_SNIP" <<'EOF'
# Sourced by start-desktop.sh and ~/.bashrc — desktop session environment.
export DISPLAY=:0
export PULSE_SERVER=127.0.0.1
export LANG=en_US.UTF-8
# Software GL — proot has no GPU driver; without this the XFCE compositor
# falls back to llvmpipe and stalls (Termux:X11 "isn't responding" / freezes).
export LIBGL_ALWAYS_SOFTWARE=1
export GALLIUM_DRIVER=llvmpipe
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp/runtime-$(id -u)}"
mkdir -p "$XDG_RUNTIME_DIR" 2>/dev/null || true
chmod 700 "$XDG_RUNTIME_DIR" 2>/dev/null || true
EOF

say "Disabling the XFCE window-manager compositor (no GPU in proot)"
# With software rendering, compositing causes freezes/ANRs. Turn it off by
# pre-writing the xfwm4 config so it's off from the very first session.
XFWM_DIR="$USER_HOME/.config/xfce4/xfconf/xfce-perchannel-xml"
mkdir -p "$XFWM_DIR"
cat > "$XFWM_DIR/xfwm4.xml" <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="use_compositing" type="bool" value="false"/>
  </property>
</channel>
XML
chown -R "$USERNAME:$USERNAME" "$USER_HOME/.config"
# Source it from .bashrc so interactive shells inside the desktop also get it.
if ! grep -q '.desktop-env.sh' "$USER_HOME/.bashrc" 2>/dev/null; then
  echo '[ -f "$HOME/.desktop-env.sh" ] && . "$HOME/.desktop-env.sh"' >> "$USER_HOME/.bashrc"
fi
chown "$USERNAME:$USERNAME" "$PROFILE_SNIP"

# --- Task 8: GUI polish — taskbar, Start menu, keyboard shortcuts ------------
say "Configuring the XFCE panel (Whisker Menu + pinned taskbar launchers)"
# xfce4-goodies already pulled in xfce4-whiskermenu-plugin; it's just never
# been wired into the default panel layout until now.
PANEL_DIR="$USER_HOME/.config/xfce4/panel/launcher-2"
mkdir -p "$PANEL_DIR"

# Reuse the real installed .desktop files where apt already ships them;
# Claude Code has none upstream (it's a CLI), so write a minimal one.
for f in xfce4-terminal.desktop thunar.desktop firefox-esr.desktop; do
  [ -f "/usr/share/applications/$f" ] && cp -f "/usr/share/applications/$f" "$PANEL_DIR/$f"
done
cat > "$PANEL_DIR/claude-code.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=Claude Code
Comment=AI coding assistant
Exec=xfce4-terminal --title=Claude Code -e "bash -lc claude"
Icon=utilities-terminal
Terminal=false
Categories=Development;
EOF

cat > "$XFWM_DIR/xfce4-panel.xml" <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-panel" version="1.0">
  <property name="panels" type="array">
    <value type="int" value="1"/>
  </property>
  <property name="panel-1" type="empty">
    <property name="position" type="string" value="p=6;x=0;y=0"/>
    <property name="length" type="uint" value="100"/>
    <property name="size" type="uint" value="34"/>
    <property name="plugin-ids" type="array">
      <value type="int" value="1"/>
      <value type="int" value="2"/>
      <value type="int" value="3"/>
      <value type="int" value="4"/>
    </property>
  </property>
  <property name="plugins" type="empty">
    <property name="plugin-1" type="string" value="whiskermenu"/>
    <property name="plugin-2" type="string" value="launcher">
      <property name="items" type="array">
        <value type="string" value="xfce4-terminal.desktop"/>
        <value type="string" value="thunar.desktop"/>
        <value type="string" value="firefox-esr.desktop"/>
        <value type="string" value="claude-code.desktop"/>
      </property>
    </property>
    <property name="plugin-3" type="string" value="tasklist"/>
    <property name="plugin-4" type="string" value="clock"/>
  </property>
</channel>
XML
# NOTE: xfce4-panel's exact XML shape has shifted slightly across versions.
# If the panel looks wrong on first boot, arrange it once by hand (right-
# click the panel -> Panel -> Add New Items) -- it persists from then on,
# no need to re-run this script. See docs/TROUBLESHOOTING.md.

say "Adding keyboard shortcuts (Super+space menu, Super+arrows to snap windows)"
cat > "$XFWM_DIR/xfce4-keyboard-shortcuts.xml" <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-keyboard-shortcuts" version="1.0">
  <property name="commands" type="empty">
    <property name="custom" type="empty">
      <property name="&lt;Super&gt;space" type="string" value="xfce4-popup-whiskermenu"/>
    </property>
  </property>
  <property name="xfwm4" type="empty">
    <property name="custom" type="empty">
      <property name="&lt;Primary&gt;&lt;Alt&gt;d" type="string" value="show_desktop_key"/>
      <property name="&lt;Super&gt;d" type="string" value="show_desktop_key"/>
      <property name="&lt;Super&gt;Left" type="string" value="tile_left_key"/>
      <property name="&lt;Super&gt;Right" type="string" value="tile_right_key"/>
      <property name="&lt;Super&gt;Up" type="string" value="maximize_window_key"/>
      <property name="&lt;Super&gt;Down" type="string" value="hide_window_key"/>
    </property>
  </property>
</channel>
XML
# Deliberately NOT binding bare Super_L alone -- XFCE grabs a standalone
# Super binding in a way that silently breaks every other <Super>+key
# shortcut above. <Super>space (a chord) sidesteps that bug.

say "Installing pointer/trackpad auto-tuning (device unknown until it's plugged in)"
mkdir -p "$USER_HOME/bin" "$USER_HOME/.config/autostart"
cat > "$USER_HOME/bin/tune-pointer-input.sh" <<'SH'
#!/usr/bin/env bash
# Idempotent -- runs at every XFCE session start via the autostart entry
# below. Detects any real (non-virtual) pointer device that exposes
# libinput properties (tap-to-click, natural scroll, etc.) and turns those
# on, plus a faster pointer speed for a big external monitor. The device's
# name can't be known at provisioning time (no hardware attached, no X
# server running during apt-get), so this can't be pre-baked as static XML
# the way xfwm4.xml is -- it has to run live, after DISPLAY/D-Bus exist.
set -uo pipefail
export DISPLAY="${DISPLAY:-:0}"

command -v xinput >/dev/null 2>&1 || exit 0

xfconf_name() {
  local s="${1// /_}"
  printf '%s' "$s" | tr -cd 'A-Za-z0-9_-'
}

xinput list 2>/dev/null | grep 'slave  pointer' | while IFS= read -r line; do
  case "$line" in
    *"Virtual core"*|*XTEST*) continue ;;
  esac
  id="$(printf '%s\n' "$line" | grep -oE 'id=[0-9]+' | cut -d= -f2)"
  [ -n "$id" ] || continue
  name="$(printf '%s\n' "$line" | sed -E 's/^[^A-Za-z0-9]*//; s/[[:space:]]+id=[0-9]+.*$//')"
  [ -n "$name" ] || continue

  props="$(xinput list-props "$id" 2>/dev/null)" || continue
  printf '%s\n' "$props" | grep -q "libinput Tapping Enabled" || continue

  dev="$(xfconf_name "$name")"
  xfconf-query -c pointers -p "/${dev}/Properties/libinput_Tapping_Enabled" -n -t bool -s true 2>/dev/null
  xfconf-query -c pointers -p "/${dev}/Properties/libinput_Natural_Scrolling_Enabled" -n -t bool -s true 2>/dev/null
  xfconf-query -c pointers -p "/${dev}/Properties/libinput_Disable_While_Typing_Enabled" -n -t bool -s true 2>/dev/null
  xfconf-query -c pointers -p "/${dev}/Properties/libinput_Scroll_Method_Enabled" -n -t int -t int -t int -s 1 -s 0 -s 0 2>/dev/null
  xfconf-query -c pointers -p "/${dev}/Properties/libinput_Accel_Speed" -n -t double -s 0.300000 2>/dev/null
done
SH
chmod +x "$USER_HOME/bin/tune-pointer-input.sh"

cat > "$USER_HOME/.config/autostart/tune-pointer-input.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=Tune pointer input
Exec=/bin/bash -lc "$HOME/bin/tune-pointer-input.sh"
NoDisplay=true
X-GNOME-Autostart-enabled=true
EOF

chown -R "$USERNAME:$USERNAME" "$USER_HOME/.config" "$USER_HOME/bin"

# --- Task 6: Node 18+ and Claude Code ----------------------------------------
say "Installing Node.js 20 (NodeSource) — apt's default is too old for Claude Code"
if ! command -v node >/dev/null 2>&1 || [ "$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null || echo 0)" -lt 18 ]; then
  curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
  apt-get install -y nodejs
fi
node --version || true

say "Installing @anthropic-ai/claude-code globally"
npm install -g @anthropic-ai/claude-code
command -v claude >/dev/null && echo "  claude: $(command -v claude)"

say "Cleaning apt caches"
apt-get clean

cat <<NOTE

[guest] ----------------------------------------------------------------
Provisioning done.
  Task 3 done-when: packages above installed cleanly.
  Task 6 done-when: 'claude' resolves -> run it in the XFCE terminal later.
  Task 8 done-when: next desktop session shows a Whisker Menu + pinned
    taskbar (top panel), Super+space opens the menu, and Super+arrows
    snap windows. If a trackpad/mouse is attached, tap-to-click and
    natural scrolling should already be on -- see docs/TROUBLESHOOTING.md
    if not.
[guest] ----------------------------------------------------------------
NOTE
