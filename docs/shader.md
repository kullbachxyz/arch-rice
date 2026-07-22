# E-paper grayscale shader (picom)

Turns the whole screen into a monochrome e-ink panel — grayscale + gentle contrast
+ warm-paper tint + optional quantization. Independent of the desktop theming
(a separate axis — the desktop is dark-only; the shader just greys what's on screen).

## Files
- `~/.config/picom/epaper.glsl` — the shader (see `../config/picom/`).
- `~/.local/bin/epaper-toggle` — start/stop picom with the shader.

## How it works
picom **v13** window shader. Entry point is **`vec4 window_shader()`** (returns the
colour) — *not* `void main()` (picom provides its own). `texcoord` is in pixels →
divide by `textureSize(tex,0)`.

Applied to windows **and** the wallpaper:
```
picom --backend glx \
      --window-shader-fg  ~/.config/picom/epaper.glsl \
      --root-pixmap-shader ~/.config/picom/epaper.glsl
```
picom must use `backend = "glx"` (shaders need GLX).

## Tunables (top of `epaper.glsl`)
- `CONTRAST` — contrast around mid-grey (`1.0` = off).
- `LEVELS` — e-ink grey steps (`16` = crisp e-ink, `256` = smooth).
- `PAPER` — warm white point (`vec3(1.0)` = neutral grey).

## Toggle
`epaper-toggle` kills picom and relaunches it with/without the shader flags
(detects the `window-shader-fg` flag on the running process), `setsid -f` so it
survives, `notify-send` for feedback. The normal login start is plain `picom &`
in `~/.xinitrc` — the toggle owns the shader on/off.

## Why it composes with the theme
The shader greys **whatever is underneath**. So: themed monochrome apps stay
monochrome; colourful things (photos, Selenized terminal, web content) get greyed
only while the shader is on. Toggle it off to see real colour again.
