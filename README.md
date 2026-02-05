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
- [x] Ensure dmenu fork includes `dmenu_path` and `dmenu_run` (commit scripts so `make install` works cleanly on fresh systems).
- [x] Temporary NOPASSWD sudoers option for fully unattended installs.
- [x] Understand pass dbus issue.
- [x] Prevent double-start of mpd (user service vs `.xinitrc`) in all contexts.
- [x] Fix keyring issue for Electron apps (PAM config + xinitrc bootstrap via secret-tool).
- [x] Add lf-git and get image previews to work.
- [x] Add aerc & mbsync. See [docs/email-setup.md](docs/email-setup.md).
- [x] SSH agent setup: Using `pam_ssh` (AUR) for automatic SSH key unlock at login. See [docs/ssh-key-setup.md](docs/ssh-key-setup.md).
- [x] Add `.config/shell/aliasrc`.
- [x] Use `.zprofile` for environment exports (removed `.xprofile`).
- [x] Fix lf previews
- [ ] Decide on keeping smartborder/vanitygaps/xrdb patch.
- [ ] Decide on default fonts (currently Libertinus Sans/Serif & JetBrains Mono Nerd)
- [ ] Fix smartborder issue after swallow.
- [ ] Write minimal vim plugin manager.
- [ ] Improve vim config.
