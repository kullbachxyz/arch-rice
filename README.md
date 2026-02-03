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
- (done) Ensure dmenu fork includes `dmenu_path` and `dmenu_run` (commit scripts so `make install` works cleanly on fresh systems).
- (done) Temporary NOPASSWD sudoers option for fully unattended installs.
- !!! Fix keyring issue (important).
- Add `.gtkrc-2.0` with a symlink to `.config/gtk-2.0/gtkrc-2.0`.
- Consider moving `.xprofile` and `.xinitrc` into `.config/x11` (LARBS-style).
- Add `.config/shell/aliasrc`.
- Decide on `.xprofile` vs `.zprofile` for environment exports.
- Prevent double-start of mpd (user service vs `.xinitrc`) in all contexts.
- Unterstand why pass only works with dbus enabled
