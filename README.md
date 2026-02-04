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
- Add aerc & mbsybc (maybe a secondary wizard for setup).
- automatic SSH key unlock: The systemd `gnome-keyring-daemon.socket` starts the daemon before `.xinitrc` runs, but without the `ssh` component. Fix by:
  1. Adding a systemd user override to dotfiles at `conf/.config/systemd/user/gnome-keyring-daemon.service.d/ssh.conf`:
     ```ini
     [Service]
     ExecStart=
     ExecStart=/usr/bin/gnome-keyring-daemon --foreground --components=pkcs11,secrets,ssh --control-directory=%t/keyring
     ```
  2. Adding `systemctl --user daemon-reload` to `install.sh` after `setup_dotfiles()`.

  After relogin, run `ssh-add ~/.ssh/id_ed25519` once — gnome-keyring stores the passphrase and auto-unlocks on future logins.
- Add `.gtkrc-2.0` with a symlink to `.config/gtk-2.0/gtkrc-2.0`.
- Consider moving `.xprofile` and `.xinitrc` into `.config/x11` (LARBS-style).
- Add `.config/shell/aliasrc`.
- Decide on `.xprofile` vs `.zprofile` for environment exports.
