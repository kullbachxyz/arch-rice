#!/bin/sh
# Build the "MMD-Dark" GTK3 theme: extract the built-in HighContrastInverse CSS
# from GTK's gresource and recolour it to PURE black/white.
#
# Why a custom on-disk theme with a UNIQUE name (not "HighContrastInverse"):
#   - GTK's built-in HighContrastInverse is dark GREY (#303030) with a BLUE
#     selection (#0f3b71) — not pure MMD black.
#   - Naming our theme "HighContrastInverse" worked at startup but on a LIVE
#     xsettingsd reload GTK loaded the built-in (grey) one instead. A unique
#     name ("MMD-Dark") has no built-in to collide with -> wins always.
#
# Result: ~/.themes/MMD-Dark  (gtk-theme-name=MMD-Dark in dark mode)
set -e

lib=$(ldconfig -p | awk -F'=> ' '/libgtk-3.so.0/{print $2; exit}')
dst="$HOME/.themes/MMD-Dark"
mkdir -p "$dst/gtk-3.0" "$dst/gtk-4.0"

cat > "$dst/index.theme" <<'EOF'
[Desktop Entry]
Type=X-GNOME-Metatheme
Name=MMD-Dark
Comment=Pure black/white monochrome (MMD dark)

[X-GNOME-Metatheme]
GtkTheme=MMD-Dark
IconTheme=HighContrastInverse
EOF

echo "Extracting built-in HighContrastInverse CSS …"
gresource extract "$lib" \
	/org/gtk/libgtk/theme/HighContrast/gtk-contained-inverse.css > "$dst/gtk-3.0/gtk.css"

echo "Recolouring palette -> pure black/white (selection = grey + white text) …"
sed -i \
 -e 's/^@define-color theme_bg_color .*/@define-color theme_bg_color #000000;/' \
 -e 's/^@define-color theme_base_color .*/@define-color theme_base_color #000000;/' \
 -e 's/^@define-color theme_fg_color .*/@define-color theme_fg_color #ffffff;/' \
 -e 's/^@define-color theme_text_color .*/@define-color theme_text_color #ffffff;/' \
 -e 's/^@define-color theme_selected_bg_color .*/@define-color theme_selected_bg_color #505050;/' \
 -e 's/^@define-color theme_selected_fg_color .*/@define-color theme_selected_fg_color #ffffff;/' \
 -e 's/^@define-color insensitive_bg_color .*/@define-color insensitive_bg_color #000000;/' \
 -e 's/^@define-color insensitive_base_color .*/@define-color insensitive_base_color #000000;/' \
 -e 's/^@define-color theme_unfocused_bg_color .*/@define-color theme_unfocused_bg_color #000000;/' \
 -e 's/^@define-color theme_unfocused_base_color .*/@define-color theme_unfocused_base_color #000000;/' \
 -e 's/^@define-color theme_unfocused_selected_bg_color .*/@define-color theme_unfocused_selected_bg_color #3a3a3a;/' \
 -e 's/^@define-color theme_unfocused_selected_fg_color .*/@define-color theme_unfocused_selected_fg_color #ffffff;/' \
 -e 's/^@define-color content_view_bg .*/@define-color content_view_bg #000000;/' \
 -e 's/^@define-color text_view_bg .*/@define-color text_view_bg #000000;/' \
 -e 's/^@define-color borders .*/@define-color borders #444444;/' \
 "$dst/gtk-3.0/gtk.css"
# hardcoded greys -> black; the blue selection -> the same grey as above
sed -i -e 's/#303030/#000000/g' -e 's/#2d2d2d/#000000/g' -e 's/#2f2f2f/#000000/g' \
       -e 's/#353535/#000000/g' -e 's/#1e1e1e/#000000/g' -e 's/#0f3b71/#505050/g' \
       "$dst/gtk-3.0/gtk.css"

# Desaturate every remaining colour (links/focus/progress/warning accents) to
# grey — otherwise e.g. the GTK file-chooser shows blue filenames.
python3 "$(dirname "$0")/desaturate-css.py" "$dst/gtk-3.0/gtk.css"

# Places-sidebar (file chooser left pane): the theme uses a lighter grey by
# default — flatten it to pure black.
sed -i \
  -e 's/\.sidebar { border-style: none; background-color: #2e2e2e; }/.sidebar { border-style: none; background-color: #000000; }/' \
  -e 's/\.sidebar:backdrop { background-color: #323232;/.sidebar:backdrop { background-color: #000000;/' \
  "$dst/gtk-3.0/gtk.css"

# gtk-dark.css copy (prefer-dark looks for it first)
cp "$dst/gtk-3.0/gtk.css" "$dst/gtk-3.0/gtk-dark.css"
printf '@import url("resource:///org/gtk/libgtk/theme/HighContrast/gtk-contained-inverse.css");\n' \
	> "$dst/gtk-4.0/gtk.css"

echo "Done -> $dst"
