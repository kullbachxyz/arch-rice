# GTK (Thunar & all GTK apps) + live reload

GTK is the trickiest layer. `@define-color` overrides on Adwaita do nothing, so we
use **real themes** and an **XSETTINGS daemon** for live switching.

## Themes
| Mode | GTK theme | Source |
|------|-----------|--------|
| Light | `HighContrast` | stock (built into GTK, `gnome-themes-extra`) — black on white |
| Dark  | `MMD-Dark` | custom, `~/.themes/MMD-Dark` — pure black/white (see below) |

Set by `theme` in `~/.config/gtk-3.0/settings.ini` (`gtk-theme-name`) **+** gsettings
`org.gnome.desktop.interface gtk-theme` **+** xsettingsd `Net/ThemeName`.

### Why `MMD-Dark` is a custom on-disk theme with a unique name
1. Adwaita ignores `@define-color` → need a real theme.
2. `HighContrastInverse` (built-in) is dark **grey** `#303030` + **blue** selection —
   not pure black. So we extract its CSS and recolour to `#000`/`#fff`.
3. Named "HighContrastInverse", it loaded at startup but **lost to the built-in on a
   live reload**. A **unique** name (`MMD-Dark`) has no collision → always wins.

Rebuild: `scripts/build-mmd-dark-gtk.sh` (extracts `gtk-contained-inverse.css` from
`libgtk-3.so.0` gresource, sed-recolours: greys→`#000`, blue→grey `#505050`).

### Selection is grey, not a white bar
GTK CSS has **no `!important`**, and the base theme paints selected text/icons white
(it assumes a dark selection). A white selection bar would be white-on-white in many
spots. So dark selection = grey `#505050` + white text — readable, works with the
theme. (See `gotchas.md`.)

## Icons
| Mode | Icon theme |
|------|-----------|
| Light | `HighContrast` — stock black monochrome icons |
| Dark  | `HighContrastInverse` — **generated** white icons |

The white set is made by inverting the black HighContrast icons
(`magick mogrify -channel RGB -negate`, keeping alpha) → `~/.local/share/icons/`.
Rebuild: `scripts/generate-icons.sh`. (Coloured folder icons you might still see are
the app/mime icons that fall back to Adwaita — rare.)

## Live reload — xsettingsd
On bare dwm there's no XSETTINGS provider, so GTK reads settings only at startup.
**`xsettingsd`** broadcasts `Net/ThemeName` / `Net/IconThemeName` / `Gtk/FontName`
over XSETTINGS; `theme` rewrites `~/.config/xsettingsd/xsettingsd.conf` and does
`pkill -HUP -x xsettingsd` → running GTK apps switch **live, no restart**.

- Autostart: `xsettingsd &` in `~/.xinitrc` (before the GTK/Qt apps).
- `~/.config/gtk-3.0/gtk.css` is intentionally empty (colours come from the theme).
