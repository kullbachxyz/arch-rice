# arch-rice

Post-install setup for Arch Linux with X + dwm. Repos are hosted on `git.lokal.kullbach.net`.

## Structure

- `install.sh` - installs packages, builds suckless tools and abook from source, sets up dotfiles and PAM.
- `packages/pacman.txt` - official repo packages.
- `packages/aur.txt` - AUR packages.
- `docs/` - setup guides for email, SSH/GPG key unlock, hibernate, pass.
- `scripts/check-installed.sh` - checks what from the package lists is already installed.

## What install.sh does

1. Installs pacman and AUR packages
2. Builds dwm, dwmblocks, dmenu, st, abook from source into `~/.local/src/`
3. Clones dotfiles bare repo to `~/.dotfiles`
4. Configures PAM for automatic SSH and GPG key unlock at TTY login
5. Configures PAM for gnome-keyring auto-unlock
6. Masks user services that are started manually via `.xinitrc`
7. Sets zsh as default shell

## Usage

The script clones all repos via HTTPS. No SSH key needed to run the install.

```bash
./install.sh
```

Check installed packages only:

```bash
./scripts/check-installed.sh
```

## Docs

- [Email setup](docs/email-setup.md) - mbsync + notmuch + neomutt + cron
- [SSH/GPG key unlock](docs/pam-ssh-gnupg-setup.md) - automatic unlock at TTY login via pam_ssh + pam-gnupg
- [SSH key setup](docs/ssh-key-setup.md)
- [GPG key setup](docs/gpg-key-setup.md)
- [pass multi-key setup](docs/pass-multi-key-setup.md)
- [Hibernate setup](docs/hibernate-setup.md)
