# Colour palette / tokens

The desktop runs stock dark themes. There is no single cross-app palette; each
layer uses its own upstream scheme.

## Terminal (st)
Gruvbox dark, loaded from Xresources at `~/.config/x11/resources`
(`xrdb -merge` at login in `.xinitrc`). Only st reads this file — it consumes
`*.foreground` / `*.background`, `*.color0..15`, and `*.alpha` (0.8). st reloads
colours + alpha live on `pkill -USR1 -x st`.

Gruvbox dark: bg `#282828`, fg `#ebdbb2`. Accents — red `#cc241d` green `#98971a`
yellow `#d79921` blue `#458588` magenta `#b16286` cyan `#689d6a`; bright red
`#fb4934` green `#b8bb26` yellow `#fabd2f` blue `#83a598` magenta `#d3869b`
cyan `#8ec07c`. (A pure-monochrome preset is kept commented in the file.)

## dwm / dmenu
Standard suckless **gray + blue**, compiled into each `config.h` — they ignore
Xresources (optional `dwm.*` / `dmenu.*` overrides are not set, so the compiled
values win):
- normal: fg `#bbbbbb`, bg `#222222`, border `#444444`.
- selected / focused: fg `#eeeeee`, bg/border `#005577` (blue).

## GTK / Qt
- GTK: stock **Adwaita-dark** (see `gtk.md`).
- Qt: **Fusion** + stock `darker.conf` scheme (see `qt.md`).

## rofi / dunst
- rofi: neutral dark grey theme `~/.config/rofi/dark.rasi` — bg `#1c1c1c`,
  fg `#e0e0e0`, selection `#3a3a3a`, 3px border `#666666` (see `apps.md`).
- dunst: bg `#222222`, fg `#e0e0e0`, frame `#444444`; critical urgency frame
  red `#cc241d`.

## Typography
- UI everywhere: **Lato** (forced via fontconfig, see `fonts.md`).
- Terminal / monospace: **IBM Plex Mono**.
- dwm bar: `IBM Plex Mono:size=12` (matches st); dmenu: `Lato:size=14`.
