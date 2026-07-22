#!/bin/sh
# Generate the "HighContrastInverse" WHITE monochrome icon theme by inverting
# the black GTK "HighContrast" icon theme (black-on-transparent -> white).
# Needs: gnome-themes-extra (HighContrast) + imagemagick.
#
# Result: ~/.local/share/icons/HighContrastInverse  (used in dark mode)
# Light mode uses the stock black "HighContrast" theme as-is.
set -e

src=/usr/share/icons/HighContrast
dst="$HOME/.local/share/icons/HighContrastInverse"

[ -d "$src" ] || { echo "install gnome-themes-extra (HighContrast icons) first"; exit 1; }
command -v magick >/dev/null || { echo "install imagemagick"; exit 1; }

echo "Copying $src -> $dst"
rm -rf "$dst"; mkdir -p "$HOME/.local/share/icons"; cp -r "$src" "$dst"
sed -i 's/^Name=.*/Name=HighContrastInverse/' "$dst/index.theme"

echo "Inverting PNGs (RGB negate, keep alpha) …"
find "$dst" -name '*.png' -print0 | xargs -0 -P4 -n150 magick mogrify -channel RGB -negate

echo "Inverting SVG fills (black -> white) …"
find "$dst" -name '*.svg' -print0 | xargs -0 sed -i \
	-e 's/#000000/#ffffff/g' -e 's/#2e3436/#ffffff/g' \
	-e 's/fill="#000"/fill="#fff"/g' -e 's/fill:#000\b/fill:#fff/g'

gtk-update-icon-cache -f "$dst" 2>/dev/null || true
echo "Done -> $dst"
