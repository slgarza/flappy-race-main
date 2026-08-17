# Flappy Kart Playable Ad

Lightweight HTML5 playable ad for Google Ads App campaigns. The mini-game shows a short race with three rival players, wall collisions, coins, item boxes, a finish line, and strong power-ups revealed from boxes: boost, flomb, and laser.

The end card reports the player's finishing place instead of an item count.

Rivals actively race: they collect coins, chase item boxes, use boost rockets, fire lasers, and launch flomb bombs toward the player. The player's first item box always demonstrates the rocket transformation.

Movement constants are tuned from the Godot `CommonPlayer` values: flap strength, gravity, max fall speed, rotation toward velocity, and wall knockback/respawn feel.

## Files

- `index.html`: standalone canvas mini-game.
- `assets/`: local images used by the ad.
- `flappy-kart-playable.zip`: upload package with `index.html` at the zip root.

## CTA

The install button calls `ExitApi.exit()` for Google Ads. Outside Google Ads, it falls back to:

```text
https://play.google.com/store/apps/details?id=com.slgdeveloper.flappyrace
```

## Rebuild Zip

Run this from `playable-ad/`:

```bash
zip -r flappy-kart-playable.zip index.html assets
```

## Google Ads Notes

For App campaign HTML5/playable assets, Google Ads currently expects a `.zip` upload, responsive HTML5, a valid orientation meta tag, local bundled assets, and a maximum package size of 5 MB.
