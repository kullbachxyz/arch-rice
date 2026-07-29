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

  if sudo test -f "$SUDOERS_TEMP_FILE"; then
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

build_from_source() {
  mkdir -p "$SRC_DIR"

  local repos=(
    "https://github.com/kullbachxyz/dwm.git"
    "https://github.com/kullbachxyz/dwmblocks.git"
    "https://github.com/kullbachxyz/dmenu.git"
    "https://github.com/kullbachxyz/st.git"
    "https://github.com/kullbachxyz/abook.git"
  )

  for repo in "${repos[@]}"; do
    local name
    name="$(basename "$repo" .git)"
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
  local repo_url="https://github.com/kullbachxyz/dotfiles.git"
  local git_dir="${HOME}/.dotfiles"
  local work_tree="${HOME}"
  local backup_dir="${HOME}/.conf-backup-$(date +%Y%m%d%H%M%S)"

  if [[ -d "$git_dir" ]]; then
    return 0
  fi

  git clone --bare "$repo_url" "$git_dir"

  if ! git --git-dir="$git_dir" --work-tree="$work_tree" checkout master; then
    mkdir -p "$backup_dir"
    git --git-dir="$git_dir" --work-tree="$work_tree" checkout master 2>&1 \
      | awk '/^\s+/ { gsub(/^[[:space:]]+|[[:space:]]+$/, ""); print }' \
      | while read -r path; do
          if [[ -e "$work_tree/$path" ]]; then
            mkdir -p "$(dirname "$backup_dir/$path")"
            mv "$work_tree/$path" "$backup_dir/$path"
          fi
        done
    git --git-dir="$git_dir" --work-tree="$work_tree" checkout master
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
password   include      system-local-login
session    optional     pam_gnome_keyring.so auto_unlock
PAMEOF
  fi

  # Add PAM line to /etc/pam.d/passwd so keyring password updates with user password
  if ! grep -q "pam_gnome_keyring.so" "$pam_passwd" 2>/dev/null; then
    echo "password   optional     pam_gnome_keyring.so" | sudo tee -a "$pam_passwd" >/dev/null
  fi

}

enable_services() {
  if ! command -v systemctl >/dev/null 2>&1; then
    return 0
  fi

  # NetworkManager is enabled by archinstall; boot/hardware units
  # (thinkfan, hibernate) are hardware-specific and handled manually.
  local units=(
    bluetooth.service
    cronie.service
    sshd.service
    cups.socket
  )

  for u in "${units[@]}"; do
    if sudo systemctl enable "$u" >/dev/null 2>&1; then
      log "Enabled $u"
    else
      log "enable $u failed (non-fatal)."
    fi
  done
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
    gnome-keyring-daemon.socket
    gnome-keyring-daemon.service
  )

  systemctl --user mask "${units[@]}" >/dev/null 2>&1 || true
  log "Masked user services: ${units[*]}"
}


setup_theme() {
  # Generate the derived MMD dark assets (not stored in git; see docs/gtk.md).
  # Configs themselves live in dotfiles; only generated output is built here.
  if [[ -x "$ROOT_DIR/scripts/build-mmd-dark-gtk.sh" ]]; then
    log "Building MMD-Dark GTK theme -> ~/.themes/MMD-Dark"
    sh "$ROOT_DIR/scripts/build-mmd-dark-gtk.sh" || log "GTK theme build failed (non-fatal)."
  fi
  if [[ -x "$ROOT_DIR/scripts/generate-icons.sh" ]]; then
    log "Generating HighContrastInverse icon theme"
    sh "$ROOT_DIR/scripts/generate-icons.sh" || log "Icon generation failed (non-fatal)."
  fi

  # Inject browser-profile theming (profile dirs are per-machine -> can't live
  # in dotfiles). Thunderbird + LibreWolf userChrome/userContent.
  local assets="$ROOT_DIR/theme-assets"

  for prof in "$HOME"/.thunderbird/*.default-release "$HOME"/.thunderbird/*.default; do
    [[ -d "$prof" ]] || continue
    log "Injecting Thunderbird MMD theme -> $prof"
    mkdir -p "$prof/chrome"
    cp "$assets"/thunderbird/chrome/*.css "$prof/chrome/" 2>/dev/null || true
    cp "$assets"/thunderbird/user.js "$prof/user.js" 2>/dev/null || true
  done

  for prof in "$HOME"/.librewolf/*.default*; do
    [[ -d "$prof" ]] || continue
    log "Injecting LibreWolf MMD theme -> $prof"
    mkdir -p "$prof/chrome"
    cp "$assets"/librewolf/chrome/*.css "$prof/chrome/" 2>/dev/null || true
  done

  log "Chromium theme manifests: load manually from $assets/chromium-themes (see docs/browsers.md)."
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
  enable_services
  setup_dotfiles
  setup_mpd_dirs
  setup_abook
  setup_keyring_pam
  mask_user_services
  build_from_source
  setup_theme
  set_default_shell
  disable_temp_nopasswd

  log "Done. Run startx to start dwm."
  log "Note: log out and back in for the default shell change to take effect."
}

main "$@"
