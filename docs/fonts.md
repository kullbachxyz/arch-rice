# Fonts — Lato everywhere except monospace

One UI typeface: **Lato**. Everything non-monospace is forced to Lato;
the terminal/monospace stays as-is.

## Files
- `~/.config/fontconfig/fonts.conf` — `sans-serif`/`serif` → Lato (Noto only as
  glyph fallback); `monospace` block unchanged.
- `~/.config/fontconfig/conf.d/99-force-lato.conf` — the **force** rules.
- GTK: `gtk-font-name = Lato 11` (settings.ini + gsettings).
- Qt: qt6ct/qt5ct `[Fonts] general = Lato,11,…` (the `fixed=`/mono slot untouched).

## Why the `99-` conf.d file
A plain `<alias>` for `serif` in `fonts.conf` **lost** to the system
`66-noto-serif.conf` (Lato ended up behind Noto Serif). fontconfig processes files
in order; a user file numbered **`99-`** loads *after* the system generic aliases,
so its `<match target="pattern">` prepends actually win.

It force-maps generics (`serif`, `sans-serif`, `sans`) **and** common named
families (Adwaita Sans, Cantarell, DejaVu, Arial, Helvetica, Times, Georgia,
Segoe UI, Roboto, Open Sans, Ubuntu, Verdana, Tahoma, Liberation, Noto Sans/Serif)
to Lato via `prepend binding="strong"` (Lato first, original kept as glyph fallback).

## Verify
```
fc-match sans-serif     # -> Lato
fc-match serif          # -> Lato
fc-match "Times New Roman"  # -> Lato
fc-match monospace      # -> Noto Sans Mono   (unchanged)
```
Needs `ttf-lato`. After edits: `fc-cache -f`. Running apps pick it up on relaunch
(GTK live via xsettingsd `Gtk/FontName`).
