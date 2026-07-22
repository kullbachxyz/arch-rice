# Other apps (dunst, rofi, zathura, Claude Code)

Dark-only monochrome, white-on-black.

## dunst
`~/.config/dunst/dunstrc` — uniform `background`/`foreground`/`frame_color`.
Dark values: `#000`/`#fff`/`#444`.

## rofi
- `~/.config/rofi/mmd-dark.rasi` — MMD theme: sharp edges (border-radius 0),
  **3px window border** in the focus colour (matches dwm `borderpx=3`), 1px divider
  under the input, inverted selection bar, `Lato` font, **no `drun` prompt**.
- `~/.config/rofi/config.rasi` — `@theme "~/.config/rofi/mmd-dark.rasi"`.

## zathura
`~/.config/zathura/zathurarc` — UI colours + PDF `recolor`.
- `recolor true` → inverts PDFs to white-on-black
  (`recolor-lightcolor #000`, `recolor-darkcolor #fff`), UI black/white.
- Font: `Lato 11`.
Applies to **newly opened** PDFs (zathura reads config at start; in a running
instance press `i` / `Ctrl+r`).

## Claude Code
`~/.claude/settings.json` sets the `theme` key to `dark`.

## htop
`~/.config/htop/htoprc`: `color_scheme=1` (Monochromatic) — no ANSI colours, just
the terminal fg/bg, so it stays clean/monochrome on the black terminal.
(Edit while htop is closed — it rewrites htoprc on exit.)
