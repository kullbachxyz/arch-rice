# arch-rice

Post-install setup for Arch Linux with X + dwm, themed as a monochrome, e-ink-friendly
(MMD) dark desktop. Repos are hosted on `git.lokal.kullbach.net`.

## Structure

- `install.sh` - installs packages, builds the suckless tools from source, sets up dotfiles, gnome-keyring PAM, and the MMD dark theme.
- `packages/pacman.txt` - official repo packages.
- `packages/aur.txt` - AUR packages.
- `scripts/` - `check-installed.sh` plus the MMD theme generators (GTK theme, inverted icons, Element theme).
- `theme-assets/` - browser-profile theming injected by `install.sh` (Thunderbird/LibreWolf chrome, Chromium manifests) — these can't live in dotfiles since profile paths are per-machine.
- `docs/` - the MMD theme docs (palette, gtk, qt, suckless, shader, fonts, browsers, apps, gotchas) plus hibernate and gnome-keyring guides.

## What install.sh does

1. Installs pacman and AUR packages
2. Builds dwm, dwmblocks, dmenu, st and abook from source into `~/.local/src/`
3. Clones dotfiles bare repo to `~/.dotfiles`
4. Configures PAM for gnome-keyring auto-unlock
5. Masks user services that are started manually via `.xinitrc`
6. Generates the MMD dark GTK theme + inverted icons and injects browser theming
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

MMD dark theme:

- [Palette / design tokens](docs/palette.md)
- [GTK theme](docs/gtk.md) · [Qt theme](docs/qt.md)
- [suckless (st/dmenu/dwm patches)](docs/suckless.md)
- [E-ink shader](docs/shader.md) · [Fonts](docs/fonts.md)
- [Browsers](docs/browsers.md) · [Apps](docs/apps.md) · [Gotchas](docs/gotchas.md)

System:

- [Hibernate setup](docs/hibernate-setup.md)
- [Gnome Keyring setup](docs/gnome-keyring-setup.md) - PAM auto-unlock for Nextcloud and other credential storage
