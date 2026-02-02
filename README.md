# arch-rice

Post-install setup for Arch Linux with X + dwm.

## Structure
- `install.sh` — installs packages, sets up yay, builds dwm/dwmblocks/dmenu/st from source.
- `packages/pacman.txt` — repo packages.
- `packages/aur.txt` — AUR packages.
- `scripts/check-installed.sh` — checks what from the lists is already installed.

## Usage
```bash
./install.sh
```

Check installed packages only:
```bash
./scripts/check-installed.sh
```

## TODO
- Audit dmenu fork: ensure `make install` consistently installs all expected scripts (e.g. `dmenu_path`, `dmenu_run`) or adjust install logic upstream.
- Add temporary NOPASSWD sudoers option for fully unattended installs.
