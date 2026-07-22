#!/usr/bin/env python3
"""Desaturate every colour in a CSS file to grayscale (luminance).

Turns links/focus/progress/warning accents into greys so a GTK theme is fully
monochrome. Greys (bg/fg/selection you already set) are luminance-preserving,
so they stay put. Usage: desaturate-css.py FILE...
"""
import re, sys


def lum(r, g, b):
    return max(0, min(255, round(0.299 * r + 0.587 * g + 0.114 * b)))


def hex_repl(m):
    h = m.group(1)
    if len(h) == 3:
        h = "".join(c * 2 for c in h)
    y = lum(int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16))
    return "#%02x%02x%02x" % (y, y, y)


def rgb_repl(m):
    y = lum(int(m.group(1)), int(m.group(2)), int(m.group(3)))
    alpha = m.group(4)  # e.g. ", 0.2" or None
    if alpha:
        return "rgba(%d, %d, %d%s)" % (y, y, y, alpha)
    return "rgb(%d, %d, %d)" % (y, y, y)


for path in sys.argv[1:]:
    s = open(path).read()
    s = re.sub(r"#([0-9a-fA-F]{6}|[0-9a-fA-F]{3})\b", hex_repl, s)
    s = re.sub(r"rgba?\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*(,[^)]*)?\)", rgb_repl, s)
    open(path, "w").write(s)
    print(path, "desaturated")
