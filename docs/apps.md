# Other apps (dunst, rofi, zathura, Claude Code)

Neutral dark, dark-only.

## dunst
`~/.config/dunst/dunstrc` — `background`/`foreground`/`frame_color` per urgency.
Dark values: `#222222`/`#e0e0e0`/`#444444`. Critical urgency uses a red frame
`#cc241d`.

## rofi
- `~/.config/rofi/dark.rasi` — neutral dark grey theme: sharp edges
  (border-radius 0), **3px window border** `#666666`, translucent panels, grey
  selection bar `#3a3a3a`, `Lato` font.
- `~/.config/rofi/config.rasi` — sets modi/icons/font and `@theme
  "~/.config/rofi/dark.rasi"`.

## zathura
`~/.config/zathura/zathurarc` — UI colours + PDF `recolor`.
- `recolor true` → inverts PDFs to a light-on-dark render, UI dark.
- Font: `Lato 11`.
Applies to **newly opened** PDFs (zathura reads config at start; in a running
instance press `i` / `Ctrl+r`).

## Claude Code
`~/.claude/settings.json` sets the `theme` key to `dark`.

## htop
`~/.config/htop/htoprc`: `color_scheme=1` (Monochromatic) — no ANSI colours, just
the terminal fg/bg, so it stays clean on the dark terminal.
(Edit while htop is closed — it rewrites htoprc on exit.)
