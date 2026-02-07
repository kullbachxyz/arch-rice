#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACMAN_LIST="$ROOT_DIR/packages/pacman.txt"
AUR_LIST="$ROOT_DIR/packages/aur.txt"
SRC_DIR="${HOME}/.local/src"
LOG_FILE="${HOME}/arch-rice-install-$(date +%Y%m%d%H%M%S).log"
SUDOERS_TEMP_FILE="/etc/sudoers.d/arch-rice-temp"
TEMP_NOPASSWD_ENABLED=0

bootstrap_repo() {
  if [[ -f "$PACMAN_LIST" && -f "$AUR_LIST" ]]; then
    return 0
  fi

  if [[ -n "${ARCH_RICE_BOOTSTRAPPED:-}" ]]; then
    echo "Bootstrap failed: package lists not found." >&2
    exit 1
  fi

  local tmpdir
  tmpdir="$(mktemp -d)"
  if command -v git >/dev/null 2>&1; then
    git clone https://github.com/kullbachxyz/arch-rice.git "$tmpdir/arch-rice"
  else
    if command -v pacman >/dev/null 2>&1; then
      sudo pacman -Sy --noconfirm git
      git clone https://github.com/kullbachxyz/arch-rice.git "$tmpdir/arch-rice"
    else
    curl -L -o "$tmpdir/arch-rice.tar.gz" \
      https://github.com/kullbachxyz/arch-rice/archive/refs/heads/main.tar.gz
    tar -xzf "$tmpdir/arch-rice.tar.gz" -C "$tmpdir"
    mv "$tmpdir/arch-rice-main" "$tmpdir/arch-rice"
    fi
  fi

  ARCH_RICE_BOOTSTRAPPED=1 exec "$tmpdir/arch-rice/install.sh"
}

log() {
  printf '[%s] %s\n' "$(date +%Y-%m-%dT%H:%M:%S%z)" "$*"
}

setup_logging() {
  exec > >(tee -a "$LOG_FILE") 2>&1
  log "Logging to $LOG_FILE"
}

preflight() {
  local missing=0

  if ! command -v sudo >/dev/null 2>&1; then
    echo "sudo is required but not found." >&2
    missing=1
  fi
  if ! command -v pacman >/dev/null 2>&1; then
    echo "pacman is required but not found." >&2
    missing=1
  fi
  if ! command -v git >/dev/null 2>&1; then
    echo "git is required but not found." >&2
    missing=1
  fi

  if [[ "$missing" -ne 0 ]]; then
    exit 1
  fi

  log "Checking sudo access..."
  sudo -v

  log "Checking network connectivity..."
  if command -v curl >/dev/null 2>&1; then
    curl -Is https://archlinux.org >/dev/null
  else
    ping -c 1 archlinux.org >/dev/null
  fi
}

keep_sudo_alive() {
  while true; do
    sudo -n true
    sleep 60
    kill -0 "$$" || exit
  done 2>/dev/null &
}

enable_temp_nopasswd() {
  if [[ "$(id -u)" -eq 0 ]]; then
    return 0
  fi

  if ! command -v sudo >/dev/null 2>&1; then
    return 0
  fi

  if [[ -f "$SUDOERS_TEMP_FILE" ]]; then
    return 0
  fi

  log "Enabling temporary NOPASSWD for current user."
  echo "$USER ALL=(ALL) NOPASSWD:ALL" | sudo tee "$SUDOERS_TEMP_FILE" >/dev/null
  sudo chmod 440 "$SUDOERS_TEMP_FILE"
  TEMP_NOPASSWD_ENABLED=1
}

disable_temp_nopasswd() {
  if [[ "$(id -u)" -eq 0 ]]; then
    return 0
  fi

  if [[ "$TEMP_NOPASSWD_ENABLED" -eq 1 && -f "$SUDOERS_TEMP_FILE" ]]; then
    log "Removing temporary NOPASSWD sudoers file."
    sudo rm -f "$SUDOERS_TEMP_FILE"
  fi
}

ensure_pacman_packages() {
  if [[ ! -f "$PACMAN_LIST" ]]; then
    echo "Missing $PACMAN_LIST" >&2
    exit 1
  fi

  sudo pacman -Syu --noconfirm
  sudo pacman -S --needed --noconfirm $(grep -Ev '^\s*#|^\s*$' "$PACMAN_LIST")
}

ensure_yay() {
  if command -v yay >/dev/null 2>&1; then
    return 0
  fi

  local tmpdir
  tmpdir="$(mktemp -d)"
  git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"
  pushd "$tmpdir/yay" >/dev/null
  makepkg -si --noconfirm
  popd >/dev/null
  rm -rf "$tmpdir"
}

ensure_aur_packages() {
  if [[ ! -f "$AUR_LIST" ]]; then
    echo "Missing $AUR_LIST" >&2
    exit 1
  fi

  if [[ -s "$AUR_LIST" ]]; then
    yay -S --needed --noconfirm --sudoloop $(grep -Ev '^\s*#|^\s*$' "$AUR_LIST")
  fi
}

build_suckless() {
  mkdir -p "$SRC_DIR"

  local repos=(
    "https://github.com/kullbachxyz/dwm"
    "https://github.com/kullbachxyz/dwmblocks"
    "https://github.com/kullbachxyz/dmenu"
    "https://github.com/kullbachxyz/st"
    "https://github.com/kullbachxyz/slock"
  )

  for repo in "${repos[@]}"; do
    local name
    name="$(basename "$repo")"
    if [[ -d "$SRC_DIR/$name/.git" ]]; then
      git -C "$SRC_DIR/$name" pull --ff-only
    else
      git clone "$repo" "$SRC_DIR/$name"
    fi

    pushd "$SRC_DIR/$name" >/dev/null
    make clean
    if [[ "$name" == "dmenu" ]]; then
      make
      if ! sudo make install; then
        log "dmenu make install failed; installing binaries manually."
        sudo install -m 755 dmenu /usr/local/bin/dmenu
        sudo install -m 755 stest /usr/local/bin/stest
        if [[ -f dmenu_path ]]; then
          sudo install -m 755 dmenu_path /usr/local/bin/dmenu_path
        fi
        if [[ -f dmenu_run ]]; then
          sudo install -m 755 dmenu_run /usr/local/bin/dmenu_run
        fi
      fi
    else
      sudo make install
    fi
    popd >/dev/null
  done
}

setup_dotfiles() {
  local repo_url="https://github.com/kullbachxyz/conf"
  local git_dir="${HOME}/.conf"
  local work_tree="${HOME}"
  local backup_dir="${HOME}/.conf-backup-$(date +%Y%m%d%H%M%S)"

  if [[ -d "$git_dir" ]]; then
    return 0
  fi

  git clone --bare "$repo_url" "$git_dir"

  if ! git --git-dir="$git_dir" --work-tree="$work_tree" checkout; then
    mkdir -p "$backup_dir"
    git --git-dir="$git_dir" --work-tree="$work_tree" checkout 2>&1 \
      | awk '/^\s+/' \
      | while read -r path; do
          if [[ -e "$work_tree/$path" ]]; then
            mkdir -p "$(dirname "$backup_dir/$path")"
            mv "$work_tree/$path" "$backup_dir/$path"
          fi
        done
    git --git-dir="$git_dir" --work-tree="$work_tree" checkout
  fi

  git --git-dir="$git_dir" --work-tree="$work_tree" config --local status.showUntrackedFiles no
}

setup_mpd_dirs() {
  mkdir -p "${HOME}/music"
  mkdir -p "${HOME}/.config/mpd"
  touch "${HOME}/.config/mpd/database"
}

setup_abook() {
  mkdir -p "${HOME}/.config/abook"
  touch "${HOME}/.config/abook/addressbook"
}

setup_keyring_pam() {
  local pam_login="/etc/pam.d/login"
  local pam_passwd="/etc/pam.d/passwd"

  # Configure /etc/pam.d/login for gnome-keyring auto-unlock on console login
  # Lines must be in correct position within each section (auth after auth, session after session)
  if ! grep -q "pam_gnome_keyring.so" "$pam_login" 2>/dev/null; then
    log "Configuring PAM for gnome-keyring auto-unlock..."
    sudo tee "$pam_login" >/dev/null << 'PAMEOF'
#%PAM-1.0

auth       requisite    pam_nologin.so
auth       include      system-local-login
auth       optional     pam_gnome_keyring.so
account    include      system-local-login
session    include      system-local-login
session    optional     pam_gnome_keyring.so auto_start
password   include      system-local-login
PAMEOF
  fi

  # Add PAM line to /etc/pam.d/passwd so keyring password updates with user password
  if ! grep -q "pam_gnome_keyring.so" "$pam_passwd" 2>/dev/null; then
    echo "password   optional     pam_gnome_keyring.so" | sudo tee -a "$pam_passwd" >/dev/null
  fi

}

mask_user_services() {
  if ! command -v systemctl >/dev/null 2>&1; then
    return 0
  fi

  if ! systemctl --user list-unit-files >/dev/null 2>&1; then
    log "systemctl --user not available; skipping service masking."
    return 0
  fi

  local units=(
    mpd.service
    pipewire.socket
    pipewire.service
    pipewire-pulse.socket
    pipewire-pulse.service
    wireplumber.service
  )

  systemctl --user mask "${units[@]}" >/dev/null 2>&1 || true
  log "Masked user services: ${units[*]}"
}


setup_pam_ssh() {
  local pam_system_login="/etc/pam.d/system-login"

  if ! pacman -Qi pam_ssh >/dev/null 2>&1; then
    log "pam_ssh not installed; skipping PAM ssh setup."
    return 0
  fi

  if grep -q "pam_ssh.so" "$pam_system_login" 2>/dev/null; then
    log "pam_ssh already configured in system-login."
    return 0
  fi

  log "Configuring PAM for automatic SSH key unlock..."

  # Add auth line after "auth include system-auth"
  sudo sed -i '/^auth.*include.*system-auth$/a auth       optional   pam_ssh.so       try_first_pass' "$pam_system_login"

  # Add session line at the end
  echo "session    optional   pam_ssh.so" | sudo tee -a "$pam_system_login" >/dev/null

  # Create login-keys.d directory
  mkdir -p "${HOME}/.ssh/login-keys.d"

  log "pam_ssh configured. See docs/ssh-key-setup.md for adding SSH keys."
}

setup_librewolf_hardening() {
  if ! command -v librewolf >/dev/null 2>&1; then
    log "LibreWolf not found; skipping hardening."
    return 0
  fi

  local arkenfox_url="https://raw.githubusercontent.com/arkenfox/user.js/master/user.js"
  local overrides_file="$ROOT_DIR/config/librewolf-overrides.js"
  local profiles_dir="${HOME}/.librewolf"
  local profiles_ini="${profiles_dir}/profiles.ini"
  local policy_file="/usr/lib/librewolf/distribution/policies.json"

  log "Ensuring LibreWolf profile exists..."
  if [[ ! -f "$profiles_ini" ]]; then
    mkdir -p "$profiles_dir"
    local default_profile="default.default-default"
    mkdir -p "${profiles_dir}/${default_profile}"
    cat > "$profiles_ini" << EOF
[General]
StartWithLastProfile=1

[Profile0]
Name=default
IsRelative=1
Path=${default_profile}
Default=1
EOF
    log "Created LibreWolf profile at ${profiles_dir}/${default_profile}."
  fi

  local profile_rel
  profile_rel="$(sed -n 's/^Path=\(.*\.default-default\)$/\1/p' "$profiles_ini" | head -n 1)"

  if [[ -z "$profile_rel" ]]; then
    log "LibreWolf default profile not found; skipping hardening."
    return 0
  fi

  local profile_path="${profiles_dir}/${profile_rel}"
  if [[ ! -d "$profile_path" ]]; then
    log "LibreWolf profile path missing; skipping hardening."
    return 0
  fi

  log "Applying LibreWolf hardening to ${profile_path}."

  if [[ -f "$profile_path/user.js" ]]; then
    mv "$profile_path/user.js" "$profile_path/user.js.bak_$(date +%F_%T)"
  fi

  if [[ ! -f "$overrides_file" ]]; then
    log "Overrides file not found at $overrides_file; skipping hardening."
    return 0
  fi

  if ! curl -fsSL "$arkenfox_url" -o "$profile_path/user.js"; then
    log "Failed to download arkenfox user.js; skipping hardening."
    return 0
  fi

  printf '\n\n' >> "$profile_path/user.js"
  cat "$overrides_file" >> "$profile_path/user.js"

  if command -v jq >/dev/null 2>&1 && [[ -f "$policy_file" ]]; then
    local backup="${policy_file}.bak_$(date +%F_%T)"
    sudo cp "$policy_file" "$backup"

    sudo jq '
      .policies.ExtensionSettings = (.policies.ExtensionSettings // {}) |
      .policies.ExtensionSettings["jid1-BoFifL9Vbdl2zQ@jetpack"] = {
        "install_url": "https://addons.mozilla.org/firefox/downloads/latest/decentraleyes/latest.xpi",
        "installation_mode": "normal_installed"
      } |
      .policies.ExtensionSettings["idcac-pub@guus.ninja"] = {
        "install_url": "https://addons.mozilla.org/firefox/downloads/latest/istilldontcareaboutcookies/latest.xpi",
        "installation_mode": "normal_installed"
      } |
      .policies.ExtensionSettings["uBlock0@raymondhill.net"] = {
        "install_url": "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi",
        "installation_mode": "normal_installed"
      } |
      .policies.ExtensionSettings["{d7742d87-e61d-4b78-b8a1-b469842139fa}"] = {
        "install_url": "https://addons.mozilla.org/firefox/downloads/latest/vimium-ff/latest.xpi",
        "installation_mode": "normal_installed"
      }
    ' "$policy_file" | sudo tee "$policy_file.tmp" >/dev/null

    sudo mv "$policy_file.tmp" "$policy_file"
  else
    log "policies.json not found or jq missing; skipping extension policies."
  fi

  # Force resistFingerprinting off in librewolf.cfg (runs after user.js, always wins)
  local lw_cfg="/usr/lib/librewolf/librewolf.cfg"
  if [[ -f "$lw_cfg" ]] && ! grep -q 'privacy.resistFingerprinting.*false' "$lw_cfg" 2>/dev/null; then
    log "Setting resistFingerprinting=false in librewolf.cfg for dark mode support."
    printf '\n// Allow dark mode detection\ndefaultPref("privacy.resistFingerprinting", false);\n' | sudo tee -a "$lw_cfg" >/dev/null
  fi

  pkill -u "$USER" librewolf >/dev/null 2>&1 || true
}
set_default_shell() {
  if command -v zsh >/dev/null 2>&1; then
    if [[ "${SHELL:-}" != "/bin/zsh" ]]; then
      if command -v chsh >/dev/null 2>&1; then
        sudo chsh -s /bin/zsh "$USER"
      elif command -v usermod >/dev/null 2>&1; then
        sudo usermod -s /bin/zsh "$USER"
      fi
    fi
  fi
}

main() {
  bootstrap_repo
  setup_logging
  preflight
  trap disable_temp_nopasswd EXIT INT TERM
  enable_temp_nopasswd
  keep_sudo_alive
  ensure_pacman_packages
  ensure_yay
  ensure_aur_packages
  setup_dotfiles
  setup_mpd_dirs
  setup_abook
  setup_keyring_pam
  setup_pam_ssh
  mask_user_services
  setup_librewolf_hardening
  build_suckless
  set_default_shell
  disable_temp_nopasswd

  log "Done. Use .xinitrc + startx as desired."
  log "Note: log out and back in for the default shell change to take effect."
}

main "$@"
