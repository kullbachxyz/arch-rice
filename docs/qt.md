# Qt (KeePassXC & all Qt apps)

Qt apps go dark via **qt6ct/qt5ct** with the **Fusion** style and the stock
`darker.conf` colour scheme. Chromium rides on this too (its Qt mode).

## Setup
- `QT_QPA_PLATFORMTHEME=qt6ct` (set in `~/.zprofile`).
- `~/.config/qt6ct/qt6ct.conf` + `~/.config/qt5ct/qt5ct.conf`: `[Appearance]`
  `style=Fusion`, `custom_palette=true`,
  `color_scheme_path=/usr/share/qt6ct/colors/darker.conf` (qt5ct points at the
  matching `/usr/share/qt5ct/colors/darker.conf`).
- Font: `[Fonts] general = Lato,11,…` (the `fixed=`/mono slot left alone).

## KeePassXC
Its own stylesheet (green headers / blue selection) overrides the platform theme.
Set `ApplicationTheme=classic` in `~/.config/keepassxc/keepassxc.ini` → it uses
the Qt platform theme (qt6ct) instead → the stock dark scheme.

## No live push
Qt has **no live-push** protocol → Qt apps apply the scheme on **next launch**
(restart the app). GTK is live via xsettingsd; Qt is not.
