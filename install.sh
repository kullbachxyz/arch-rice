#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACMAN_LIST="$ROOT_DIR/packages/pacman.txt"
AUR_LIST="$ROOT_DIR/packages/aur.txt"
SRC_DIR="${HOME}/.local/src"
LOG_FILE="${HOME}/arch-rice-install-$(date +%Y%m%d%H%M%S).log"
SUDOERS_TEMP_FILE="/etc/sudoers.d/arch-rice-temp"

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
}

disable_temp_nopasswd() {
  if [[ "$(id -u)" -eq 0 ]]; then
    return 0
  fi

  if [[ -f "$SUDOERS_TEMP_FILE" ]]; then
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

set_default_shell() {
  if command -v zsh >/dev/null 2>&1; then
    if [[ "${SHELL:-}" != "/bin/zsh" ]]; then
      chsh -s /bin/zsh
    fi
  fi
}

main() {
  bootstrap_repo
  setup_logging
  preflight
  enable_temp_nopasswd
  keep_sudo_alive
  ensure_pacman_packages
  ensure_yay
  ensure_aur_packages
  setup_dotfiles
  build_suckless
  set_default_shell
  disable_temp_nopasswd

  log "Done. Use .xinitrc + startx as desired."
}

main "$@"
