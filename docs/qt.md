# Qt (KeePassXC & all Qt apps)

Qt apps go monochrome via **qt6ct/qt5ct** with the **Fusion** style and a custom
grayscale colour palette. Chromium rides on this too (its Qt mode).

## Setup
- `QT_QPA_PLATFORMTHEME=qt6ct` (already in the environment).
- `~/.config/qt6ct/qt6ct.conf` + `~/.config/qt5ct/qt5ct.conf`: `[Appearance]`
  `style=Fusion`, `custom_palette=true`, `color_scheme_path=…/mmd-mono-<mode>.conf`.
- Palettes: `~/.config/qt{6,5}ct/colors/mmd-mono-{light,dark}.conf` — 21 QPalette
  roles per state, pure `#fff`/`#000`, **inverted selection** (Highlight = fg,
  HighlightedText = bg).
- Font: `[Fonts] general = Lato,11,…` (the `fixed=`/mono slot left alone).

## KeePassXC
The green headers / blue selection / green OK button came from KeePassXC's **own**
stylesheet. Set `ApplicationTheme=classic` in `~/.config/keepassxc/keepassxc.ini` →
it uses the Qt platform theme (qt6ct) instead → monochrome.

## Switching
`theme` rewrites `color_scheme_path` to `mmd-mono-<mode>.conf` in both confs +
`gsettings … color-scheme`. Qt has **no live-push** protocol → Qt apps apply on
**next launch** (restart the app). GTK is live; Qt is not.
