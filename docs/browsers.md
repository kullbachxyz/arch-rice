# Browsers

## Chromium — Qt mode (follows the Qt monochrome palette)
Chromium (Arch build has Qt support: `CreateQtInterface`) can render its native UI
via **Qt**. Set:
```
extensions.theme.system_theme = 2   # in ~/.config/chromium/Default/Preferences  (0=classic,1=GTK,2=Qt)
```
Then Chromium uses the **qt6ct monochrome palette** like KeePassXC — pure
white-on-black, no restart needed for the built-in mode.

Alternatively a custom Chrome *theme extension* is pure `#fff`/`#000` (static).
The dark manifest in `../config/chromium-themes/` is the one we use as a
copy/modify base.

## LibreWolf — no Qt mode, use userChrome.css
Firefox/LibreWolf is GTK/XUL — **no Qt mode**. But it's more themable:

Profile: `~/.config/librewolf/librewolf/<id>.default-default/` (**not** `~/.librewolf`).

- `chrome/userChrome.css` — dark chrome (`@media (prefers-color-scheme: dark)`)
  forced to **pure black** (bars `#141414`, active tab / url `#000`, popups `#0a0a0a`).
- `chrome/userContent.css` — styles `about:` pages (settings): black background,
  blue accent → monochrome, checkboxes `accent-color` mono.
- `user.js`: `toolkit.legacyUserProfileCustomizations.stylesheets = true`
  (required to load userChrome/userContent).

The desktop runs dark, so LibreWolf renders its dark chrome; the userChrome only
fixes "dark grey → pure black". Fully quit & restart to apply.
