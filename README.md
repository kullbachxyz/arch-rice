# arch-rice

Post-install setup for Arch Linux with X + i3 + polybar. Repos are hosted on `git.lokal.kullbach.net`.

## Structure

- `install.sh` - installs packages, builds dmenu, st and abook from source, sets up dotfiles and PAM.
- `packages/pacman.txt` - official repo packages.
- `packages/aur.txt` - AUR packages.
- `docs/` - setup guides for email, SSH/GPG key unlock, hibernate, pass.
- `scripts/check-installed.sh` - checks what from the package lists is already installed.

## What install.sh does

1. Installs pacman and AUR packages
2. Builds dmenu, st and abook from source into `~/.local/src/`
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

- [Hibernate setup](docs/hibernate-setup.md)
- [Gnome Keyring setup](docs/gnome-keyring-setup.md) - PAM auto-unlock for Nextcloud and other credential storage
