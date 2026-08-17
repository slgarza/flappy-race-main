# Flappy Kart Bare Godot Playable

Version Godot 3.6 para Google Ads con template HTML5 custom.

Esta variante no usa PNG, TTF, audio ni escenas del juego original. Dibuja todo con `CanvasItem` y un texto bitmap propio en GDScript para permitir una plantilla de engine mucho mas chica.

## Template custom

Source:

```bash
/home/sergiolozano/Downloads/godot-3.6.2-custom
```

Toolchain usado:

```bash
/home/sergiolozano/Downloads/emsdk
emscripten 3.1.39
```

Build command funcional:

```bash
source /home/sergiolozano/Downloads/emsdk/emsdk_env.sh
scons platform=javascript tools=no target=release optimize=size lto=none production=no -j10 verbose=no
```

Template:

```bash
/home/sergiolozano/Downloads/godot-3.6.2-custom/bin/godot.javascript.opt.zip
```

Nota: `lto=full` se intento con Emscripten 3.1.64 y 3.1.39, pero fallo en `wasm-ld` con `attempt to add bitcode file after LTO`.

## Export

```bash
/home/sergiolozano/Downloads/Godot_v3.6.2-stable_x11.64 --no-window --path godot-playable-ad-bare --export google_ads_html5_bare build/index.html
```

## Peso

- `flappy-kart-godot-bare-custom.zip`: 2,951,049 bytes.
- `flappy-kart-godot-bare-custom-min.zip`: 2,948,741 bytes.
- `build/index.wasm`: 11,812,358 bytes sin comprimir, 2,864,473 bytes dentro del zip.
- `build/index.pck`: 20,064 bytes sin comprimir, 7,875 bytes dentro del zip.

El zip con `index.audio.worklet.js` incluido es el recomendado para compatibilidad, aunque el playable no reproduce audio.
