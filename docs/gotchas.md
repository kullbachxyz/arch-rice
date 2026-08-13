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

## GTK live reload needs an XSETTINGS daemon
On bare dwm there is no XSETTINGS provider, so GTK apps read `settings.ini`
**only at startup**. `xsettingsd` (SIGHUP to reload) broadcasts theme/icon/font
changes → running GTK apps switch live. xsettingsd is the authoritative runtime
source and overrides `settings.ini` for running apps. Qt has no equivalent
live-push → next launch.

## Serif wasn't forced to Lato
A plain `<alias>` for `serif` lost to the system `66-noto-serif.conf`. Fix: a
high-numbered user file `~/.config/fontconfig/conf.d/99-force-lato.conf` (loads
**after** the system aliases) with `<match target="pattern">` prepends.
