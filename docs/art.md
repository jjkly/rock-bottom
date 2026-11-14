# Art pipeline

Pixel art, top-down, Stardew-ish. The project already enforces the important
settings; this page is what the art owner needs so nothing fights the engine.

## Canvas and scale

- 1280×720 viewport, `canvas_items` stretch, **integer scaling** (set in
  `project.godot`). Never scale sprites by fractional values.
- Tile size: **32×32**. One tile = 32 px in the source, 32 px on screen.
- Character sprites: 32×48 (body) with a 32×32 feet tile for collision.
- Tables: 64×64 (2-seat) / 96×64 (4-seat). Stations: 32×48 or 64×64.

## Import settings (per texture)

- Filter: **Nearest** — already the project default, don't override per sprite.
- Mipmaps off, compression off (lossless), repeat off.
- Crop empty space off; keep the origin at the bottom-centre for props.

## Where things go

```
assets/
  sprites/fish/          species sprites, named by SpeciesDef.id (lean_tuna.png)
  sprites/characters/    player_<dir>_<frame>.png (down/up/side, 0-3), customers
  sprites/restaurant/    tiles_floor.png, table_2/4.png, cutting_board.png,
                         stove.png, sink.png, freezer.png, tank.png
  sprites/ui/            heart_full/empty.png, weather_clear/hot/rain.png,
                         crate_frame.png, coin.png, ticket_bubble.png
  audio/sfx/             serve.ogg, angry.ogg, coin.ogg, crate_open.ogg, reel_tick.ogg
  audio/music/
```

Every folder above ships with a **magenta-grid placeholder at the final size**.
Overwrite the file in place, or drop a larger PNG and update the scene's
scale — never rename it, the scenes and `.tres` files reference these paths.
Anything without art yet keeps its placeholder; nothing in the game crashes on
a missing image.

Source files (`.aseprite`, `.psd`) do **not** go in the project; export PNGs.
If a source must live in the repo, put it under `art_source/` and `.gdignore`
that folder so Godot never imports it.

## Wiring a sprite to content

1. Drop the PNG in `assets/sprites/fish/`.
2. Open the matching `data/species/<id>.tres` and set `sprite`.
3. Nothing else — the fishing tank and freezer read `sprite` and fall back to
   a debug rectangle when it's null.

Modifiers tint the sprite via `ModifierDef.tint`, so draw fish in neutral
colours and let the data tint Golden/Chroma/Ice Cold.

## Rendering and sorting

- One `Node2D` with **Y Sort Enabled** for the restaurant; all characters,
  tables, and props are its direct children.
- Character origin at the feet. Tables' origin at the floor contact point.
- Player and customers share the same Y-sort container so depth is automatic.
- Shadows: a separate sprite at the feet, no shadow in the character sheet.

## Animation — the minimum

- Player: **4 frames × 3 directions** (`down`, `up`, `side`) at 32×48. Left is
  the side frames flipped. Idle is frame `_0`. Total 12 PNGs, no sprite sheet.
- Fish: **one still image** per species. The tank bob is a tween on the
  sprite — do not author bob frames.
- Tables, stations, props, UI: static, one image each.
- Only add numbered frames when something genuinely animates (a sizzle, a
  crate spin), and add them then, not in advance.

## Priority order (so placeholders never block systems)

1. Species silhouettes (5 fish) + tank background
2. Player 4-dir walk
3. Table + chair + ticket bubble
4. Cutting board, stove, sink
5. Customer variants
6. UI: hearts, weather icons, crate reel

Everything above ships as flat-colour rectangles first; the systems don't wait
on art and art doesn't wait on a "final" system.

## Do not

- Don't use the editor's import overrides for filtering per texture.
- Don't put art in `addons/` or `scripts/`.
- Don't add fonts/SFX until the audio owner wires a bus; loose imports slow
  the first `--import` for everyone.
