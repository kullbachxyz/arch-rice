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
- (done) Unserstand pass debus issue
- (done) Prevent double-start of mpd (user service vs `.xinitrc`) in all contexts.
- (done) Fix keyring issue for Electron apps (PAM config + xinitrc bootstrap via secret-tool)
- (done) Add lf-git and get image previews to work.
- fix smartborder issue after swallow
- (done) Add aerc & mbsync. See [docs/email-setup.md](docs/email-setup.md).
- (done) SSH agent setup: Using `pam_ssh` (AUR) for automatic SSH key unlock at login. See [docs/ssh-key-setup.md](docs/ssh-key-setup.md).
- Add `.gtkrc-2.0` with a symlink to `.config/gtk-2.0/gtkrc-2.0`.
- Consider moving `.xprofile` and `.xinitrc` into `.config/x11` (LARBS-style).
- Add `.config/shell/aliasrc`.
- Decide on `.xprofile` vs `.zprofile` for environment exports.
