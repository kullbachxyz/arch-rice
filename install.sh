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
    git clone git@git.lokal.kullbach.net:kullbachxyz/arch-rice.git "$tmpdir/arch-rice"
  else
    if command -v pacman >/dev/null 2>&1; then
      sudo pacman -Sy --noconfirm git
      git clone git@git.lokal.kullbach.net:kullbachxyz/arch-rice.git "$tmpdir/arch-rice"
    else
    curl -L -o "$tmpdir/arch-rice.tar.gz" \
      https://git.lokal.kullbach.net/kullbachxyz/arch-rice/archive/main.tar.gz
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

build_suckless() {
  mkdir -p "$SRC_DIR"

  local repos=(
    "git@git.lokal.kullbach.net:kullbachxyz/dwm.git"
    "git@git.lokal.kullbach.net:kullbachxyz/dwmblocks.git"
    "git@git.lokal.kullbach.net:kullbachxyz/dmenu.git"
    "git@git.lokal.kullbach.net:kullbachxyz/st.git"
    "git@git.lokal.kullbach.net:kullbachxyz/abook.git"
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
  local repo_url="git@git.lokal.kullbach.net:kullbachxyz/dotfiles.git"
  local git_dir="${HOME}/.dotfiles"
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


setup_pam_ssh_gnupg() {
  local pam_system_login="/etc/pam.d/system-login"

  if ! pacman -Qi pam_ssh >/dev/null 2>&1 || ! pacman -Qi pam-gnupg >/dev/null 2>&1; then
    log "pam_ssh or pam-gnupg not installed; skipping PAM ssh/gnupg setup."
    return 0
  fi

  if grep -q "pam_ssh.so" "$pam_system_login" 2>/dev/null && \
     grep -q "pam_gnupg.so" "$pam_system_login" 2>/dev/null; then
    log "pam_ssh and pam_gnupg already configured in system-login."
    return 0
  fi

  log "Configuring PAM for automatic SSH and GPG key unlock..."

  sudo tee "$pam_system_login" >/dev/null << 'PAMEOF'
#%PAM-1.0

auth       required   pam_shells.so
auth       requisite  pam_nologin.so
auth       include    system-auth
auth       optional   pam_gnupg.so store-only
auth       optional   pam_ssh.so try_first_pass

account    required   pam_access.so
account    required   pam_nologin.so
account    include    system-auth

password   include    system-auth

session    optional   pam_loginuid.so
session    optional   pam_keyinit.so force revoke
session    include    system-auth
session    optional   pam_lastlog2.so silent
session    optional   pam_motd.so
session    optional   pam_mail.so dir=/var/spool/mail standard quiet
session    optional   pam_umask.so
-session   optional   pam_systemd.so
session    required   pam_env.so
session    optional   pam_gnupg.so
session    optional   pam_ssh.so
PAMEOF

  mkdir -p "${HOME}/.ssh/login-keys.d"

  local gpg_agent_conf="${HOME}/.gnupg/gpg-agent.conf"
  mkdir -p "${HOME}/.gnupg"
  if ! grep -q "allow-preset-passphrase" "$gpg_agent_conf" 2>/dev/null; then
    printf 'allow-preset-passphrase\nmax-cache-ttl 86400\n' >> "$gpg_agent_conf"
  fi

  log "pam_ssh and pam_gnupg configured. See pam-ssh-gnupg-setup.md for key setup."
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
  setup_pam_ssh_gnupg
  mask_user_services
  build_suckless
  set_default_shell
  disable_temp_nopasswd

  log "Done. Use .xinitrc + startx as desired."
  log "Note: log out and back in for the default shell change to take effect."
}

main "$@"
