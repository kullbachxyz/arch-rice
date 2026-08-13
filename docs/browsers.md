# Browsers

Both browsers use their **native dark mode** — no custom chrome CSS or theme
extensions.

## LibreWolf / Firefox
`user.js` pref `ui.systemUsesDarkTheme=1` makes it render dark chrome and honour
`prefers-color-scheme: dark`. No userChrome.css / userContent.css.

Profile: `~/.config/librewolf/librewolf/<id>.default-default/` (**not**
`~/.librewolf`).

## Thunderbird
Native dark via `user.js` pref `ui.systemUsesDarkTheme=1` only — no custom CSS.

## Chromium
Chromium (Arch build has Qt support) can render its native UI via **Qt**:
```
extensions.theme.system_theme = 2   # ~/.config/chromium/Default/Preferences  (0=classic,1=GTK,2=Qt)
```
Then it follows the qt6ct dark scheme like the other Qt apps (see `qt.md`).
