# Colour palette / tokens

Single source of truth for colours: `~/.config/x11/xres-{light,dark}` (Xresources),
consumed by st, dmenu, dwm. Every other app mirrors these values.

## MMD reference tokens

| Token | Light | Dark |
|-------|-------|------|
| background | `#ffffff` | `#000000` |
| foreground (ink) | `#000000` | `#ffffff` |
| border / divider | `#cccccc` | `#444444` |
| muted | `#999999` | `#b0b0b0` |
| code / inset bg | `#f2f2f2` | `#141414` |
| selection | inverted: **ink bar, paper text** | inverted / grey `#505050` (GTK) |

- **dwm / dmenu / rofi:** selection = full inversion (paper-on-ink light,
  ink-on-paper dark), border `#ccc`/`#444`, focused window border = ink/paper.
- **GTK dark selection** is grey `#505050` + white text, not a white bar — see
  `gotchas.md` (GTK has no `!important`, the base theme paints selected text white).

## Terminal (st) — two palettes

1. **Grayscale (default in xres):** neutral grey ramp — so with the shader OFF the
   terminal is still monochrome MMD.  *(historical; replaced below)*
2. **Selenized (current):** a real colourful palette so that with the **shader off**
   the terminal has usable colour, and with the **shader on** it greys to MMD.
   - Light = **Selenized white** on `#fff`, Dark = **Selenized black** on `#000`.
   - Only `st.color0..15` differ; dwm/dmenu/rofi stay monochrome.
   - Accents are the official Selenized values; greys tuned for pure `#000`/`#fff`.

Selenized dark accents: red `#ed4a46` green `#70b433` yellow `#dbb32d`
blue `#368aeb` magenta `#eb6eb7` cyan `#3fc5b7`.
Selenized light accents: red `#d6000c` green `#1d9700` yellow `#c49700`
blue `#0064e4` magenta `#dd0f9d` cyan `#00ad9c`.

## Typography

- UI everywhere: **Lato** (forced via fontconfig, see `fonts.md`).
- Terminal / monospace: **IBM Plex Mono** (humanist mono that pairs with Lato; monospace so columns align).
- dwm bar: `IBM Plex Mono:size=12` (same monospace as st, for a consistent
  bar↔terminal look); dmenu: `Lato:size=14`.
