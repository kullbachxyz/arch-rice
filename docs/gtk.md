# GTK (Thunar & all GTK apps) + live reload

GTK uses the stock **Adwaita-dark** theme. On bare dwm there's no XSETTINGS
provider, so a small daemon (**xsettingsd**) supplies it and enables live reload.

## Theme
- Theme: `Adwaita-dark`, icons: `Adwaita` (both stock).
- `~/.config/gtk-3.0/settings.ini` **and** `~/.config/gtk-4.0/settings.ini`:
  ```
  gtk-theme-name=Adwaita-dark
  gtk-icon-theme-name=Adwaita
  gtk-font-name=Lato 11
  gtk-application-prefer-dark-theme=1
  ```
- These files are read at app **startup** only. The authoritative runtime source
  is xsettingsd (below), which overrides `settings.ini` for running apps.

## Live reload — xsettingsd
On bare dwm there's no XSETTINGS provider, so GTK reads `settings.ini` only at
startup. **`xsettingsd`** broadcasts `Net/ThemeName` / `Net/IconThemeName` /
`Gtk/FontName` over the XSETTINGS protocol → running GTK apps switch live.

`~/.config/xsettingsd/xsettingsd.conf`:
```
Net/ThemeName "Adwaita-dark"
Net/IconThemeName "Adwaita"
Gtk/FontName "Lato 11"
Gtk/ApplicationPreferDarkTheme 1
```

- Reload live after editing: `kill -HUP $(pgrep -x xsettingsd)`.
- Autostart: `xsettingsd &` in `~/.xinitrc` (before the GTK/Qt apps).
