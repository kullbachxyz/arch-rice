# Gotchas / hard-won lessons

The non-obvious things that cost time. Read before touching anything.

## `pkill` must be exact (`-x`) — it killed the X session
`pkill -USR1 st` matches by **substring** → also hits `startx`, `systemd`, …
Sending them SIGUSR1 terminated `startx` and killed the whole session.
**Always `pkill -USR1 -x st`.** Same for `dwm`, `dunst`, `xsettingsd`.

## Nerd-Font glyphs came out blank in the bar
Attempted Nerd-Font icons in dwmblocks rendered as *nothing* (a hexdump showed the
scripts emitted no glyph at all — the PUA chars were swallowed). Reverted to plain
text labels (`VOL 35%` …) with a `│` divider. Text is robust; glyphs weren't worth it.

## picom v13 shader entry point
picom v13 provides its own `main()`. A shader must define **`vec4 window_shader()`**
(returns the colour), *not* `void main()` — else: `error: function 'main' is
multiply defined`. `texcoord` is in **pixels**, divide by `textureSize(tex,0)`.

## GTK ignores `@define-color` on Adwaita
Overriding `theme_bg_color` etc. via `~/.config/gtk-3.0/gtk.css` does **nothing** on
modern Adwaita (colours are baked into its CSS). You need a real theme →
`HighContrast` / a custom one. (HighContrast *does* honour named colours.)

## GTK theme name resolution needs an on-disk directory
`gtk-theme-name=HighContrastInverse` fell back to Adwaita because there is **no**
`/usr/share/themes/HighContrastInverse` dir — GTK looks up themes by name on disk.
Fix: an on-disk shim in `~/.themes/`. The real CSS lives in GTK's gresource:
`gresource extract libgtk-3.so.0 /org/gtk/libgtk/theme/HighContrastInverse/gtk.css`.
`@import url("resource://…")` from a user theme did **not** load — extract the full
CSS into the file instead.

## Built-in theme wins on LIVE reload → rename to a unique name
Even with the on-disk shim named `HighContrastInverse`, it loaded correctly at
**startup** but on an **xsettingsd live reload** GTK loaded the **built-in** (grey
`#303030` + blue) one instead. Renaming our theme to a **unique** name (`MMD-Dark`)
removes the collision → our pure-black CSS wins both at startup and live.

## GTK CSS has no `!important`
`color:#000 !important;` → *"Junk at end of value"*. You can't force-override the
base theme's `color:#fff` on `:selected`. That's why the GTK **dark selection is
grey `#505050` with white text** (works with the theme's assumptions) instead of a
white bar with black text.

## GTK live reload needs an XSETTINGS daemon
On bare dwm there is no XSETTINGS provider, so GTK apps read `settings.ini`/gsettings
**only at startup**. `xsettingsd` (SIGHUP to reload) broadcasts theme/icon/font
changes → GTK apps switch live. Qt has no equivalent live-push → next launch.

## Custom Chrome themes are static
A Chromium theme *extension* is static (fine — the desktop is dark-only, so we
just ship the dark manifest). The alternative is **Chromium's Qt mode**
(`extensions.theme.system_theme=2`) → it uses the qt6ct monochrome palette.

## LibreWolf has no Qt mode — but userChrome.css
Firefox/LibreWolf is GTK/XUL. No Qt mode, **but** `userChrome.css` +
`toolkit.legacyUserProfileCustomizations.stylesheets=true` lets you force the dark
chrome to pure black (`@media (prefers-color-scheme: dark)`), and `userContent.css`
styles `about:` pages. Profile lives under `~/.config/librewolf/…`, *not* `~/.librewolf`.

## Serif wasn't forced to Lato
A plain `<alias>` for `serif` lost to the system `66-noto-serif.conf`. Fix: a
high-numbered user file `~/.config/fontconfig/conf.d/99-force-lato.conf` (loads
**after** the system aliases) with `<match target="pattern">` prepends.
