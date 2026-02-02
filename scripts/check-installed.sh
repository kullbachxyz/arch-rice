#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACMAN_LIST="$ROOT_DIR/packages/pacman.txt"
AUR_LIST="$ROOT_DIR/packages/aur.txt"

list_missing() {
  local list_file="$1"
  if [[ ! -f "$list_file" ]]; then
    echo "Missing $list_file" >&2
    return 1
  fi

  local wanted
  wanted="$(grep -Ev '^\s*#|^\s*$' "$list_file" | sort -u)"
  local installed
  installed="$(pacman -Qq | sort -u)"

  comm -23 <(printf '%s\n' "$wanted") <(printf '%s\n' "$installed")
}

list_installed() {
  local list_file="$1"
  if [[ ! -f "$list_file" ]]; then
    echo "Missing $list_file" >&2
    return 1
  fi

  local wanted
  wanted="$(grep -Ev '^\s*#|^\s*$' "$list_file" | sort -u)"
  local installed
  installed="$(pacman -Qq | sort -u)"

  comm -12 <(printf '%s\n' "$wanted") <(printf '%s\n' "$installed")
}

echo "Repo packages installed:"
list_installed "$PACMAN_LIST" || true

echo

echo "Repo packages missing:"
list_missing "$PACMAN_LIST" || true

echo

echo "AUR packages installed:"
list_installed "$AUR_LIST" || true

echo

echo "AUR packages missing:"
list_missing "$AUR_LIST" || true
