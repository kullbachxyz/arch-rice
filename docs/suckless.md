# suckless (st / dmenu / dwm / dwmblocks)

> Not a build guide. The suckless tools are built from **their own repos** with the
> appropriate patch set — link those repos here:
>
> - st:        `<link>`
> - dmenu:     `<link>`
> - dwm:       `<link>`
> - dwmblocks: `<link>`

The only requirement for **this** setup is that the right patches are applied (in the
linked repos) and the tools are `sudo make install`-ed.

## What matters for the theme system

The patch *this project* relies on is an **xresources / xrdb** patch on each tool
(the `epaper-theme-xresources` patch in the linked repos). It makes st/dmenu/dwm read
their colours from Xresources:

- **st** — xresources loader + **SIGUSR1 reload** (`config_init()` in `x.c`,
  `resources[]` in `config.h`); `pkill -USR1 -x st` re-reads xrdb → live recolour.
- **dmenu** — `readxresources()` reads `dmenu.*` from xrdb at launch.
- **dwm** — `loadxrdb()` reads `dwm.*` at startup; **SIGHUP restarts dwm in place**
  (existing restartsig patch) → `pkill -HUP -x dwm` re-reads xrdb.

Resource names live in `~/.config/x11/xres-dark`:
`st.color0..15`, `st.foreground/background`, `dwm.norm*/sel*color`, `dmenu.norm*/sel*`.

## Non-theme tweaks made here
- **dwm** `config.h`: `gaps = 0`, bar font `Lato:size=14`; `dwm.c` drawbar patched so
  the focused-window **title** uses `SchemeNorm` (no black title bar).
- **dwmblocks** `blocks.h`: divider `delim = "  │  "`; scripts in `../bin/statusbar/`
  print plain text (`VOL 35%`, `BAT 94%`, `Sa 18 Jul 00:11`, `WIFI`).

`~/.xinitrc` loads the theme at login:
`xrdb -merge ~/.config/x11/xres-dark`.
