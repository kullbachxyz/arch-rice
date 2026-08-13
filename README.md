# arch-rice

Post-install setup for Arch Linux with X + dwm, themed as a neutral dark desktop.
Repos are mirrored on GitHub (`github.com/kullbachxyz`).

Assumes a base system installed via `archinstall`, which already handles the
bootloader, disk/EFI setup, locale, timezone, hostname and NetworkManager.

## Structure

- `install.sh` - installs packages, builds the suckless tools from source, sets up dotfiles and gnome-keyring PAM.
- `packages/pacman.txt` - official repo packages.
- `packages/aur.txt` - AUR packages.
- `scripts/` - `check-installed.sh`.
- `theme-assets/` - the per-machine Thunderbird dark pref injected by `install.sh` (profile path can't live in dotfiles).
- `docs/` - theme docs (palette, gtk, qt, suckless, fonts, browsers, apps, gotchas) plus hibernate and gnome-keyring guides.

## Theme

Dark, using stock themes — no custom theme to build:

- **st** — Gruvbox dark (Xresources, `~/.config/x11/resources`)
- **dwm / dmenu** — standard gray + blue, compiled in
- **GTK** — Adwaita-dark (dotfiles gtk settings + xsettingsd)
- **Qt** — Fusion + stock `darker.conf` (dotfiles qtXct)

## What install.sh does

1. Installs pacman and AUR packages
2. Enables system services (bluetooth, cronie, sshd, cups)
3. Builds dwm, dwmblocks, dmenu, st and abook from source into `~/.local/src/`
4. Clones dotfiles bare repo to `~/.dotfiles`
5. Configures PAM for gnome-keyring auto-unlock
6. Masks user services that are started manually via `.xinitrc`
7. Sets the Thunderbird dark pref
8. Sets zsh as default shell

## Not covered (manual / hardware-specific)

These are intentionally left out of `install.sh` — either archinstall handles them
or they depend on the specific hardware:

- Bootloader, disk/EFI, locale, timezone, hostname, NetworkManager → archinstall
- ThinkPad fan control (`thinkfan`) → see hardware notes; laptop-specific
- Hibernate / resume → [docs/hibernate-setup.md](docs/hibernate-setup.md)
- `syncthing` as a user service (`systemctl --user enable syncthing.service`) if used

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

Theme:

- [Palette / design tokens](docs/palette.md)
- [GTK theme](docs/gtk.md) · [Qt theme](docs/qt.md)
- [suckless (st/dmenu/dwm patches)](docs/suckless.md)
- [Fonts](docs/fonts.md)
- [Browsers](docs/browsers.md) · [Apps](docs/apps.md) · [Gotchas](docs/gotchas.md)

System:

- [Hibernate setup](docs/hibernate-setup.md)
- [Gnome Keyring setup](docs/gnome-keyring-setup.md) - PAM auto-unlock for Nextcloud and other credential storage
