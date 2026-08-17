# Flappy Kart Godot Playable Ad

Microproyecto Godot 3.6 para una version HTML5 ligera del gameplay principal.

## Contenido

- `TAP TO PLAY` al inicio.
- Ronda rapida de aproximadamente 20 segundos.
- Flap con tap/click, obstaculos, monedas, cajas de power-up, boost, laser y flomb.
- Pantalla final con `MULTIPLAYER`, `POWER-UPS + RACES` e `INSTALL FREE`.
- ExitApi de Google Ads inyectado en el HTML exportado.

## Export

```bash
/home/sergiolozano/Downloads/Godot_v3.6.2-stable_x11.64 --no-window --path godot-playable-ad --export google_ads_html5 build/index.html
```

## Peso medido

El `.pck` del playable pesa poco, pero el runtime oficial de Godot 3.6 HTML5 domina el paquete:

- `build/index.wasm`: 19,796,835 bytes sin comprimir.
- `flappy-kart-godot-google-ads-noicon.zip`: 5,600,437 bytes.

Con la plantilla HTML5 oficial instalada, el export Godot no baja de 5 MB. Para cumplir ese limite usando Godot hace falta compilar una plantilla HTML5 custom/minimal del engine con Emscripten, desactivando modulos no usados. En esta maquina no hay `emcc` instalado.
