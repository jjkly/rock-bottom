# Characters

Emmy's 16px character. Source sheets are packed horizontally with a 1px gap
between frames; `tools/build_character.py` slices them into individual PNGs and
regenerates the `SpriteFrames` resources. **Do not hand-edit the generated
frames** — edit the sheet and re-run the script.

## Source sheets (edit these — in `assets/art_source/characters/`)

| File | Frames | Frame size | Used for |
|---|---|---|---|
| `idle.png` | 7 | 7×16 (8px pitch) | standing |
| `walk.png` | 4 | 7×18 (8px pitch) | walking |
| `hold.png` | 1 | 10×16 | carried item, static |
| `holdidle.png` | 7 | 10×18 (11px pitch) | standing with a plate |
| `hold walk.png` | 4 | 10×18 (11px pitch) | walking with a plate |
| `fishing idle.png` | 5 | 28×16 (29px pitch) | fishing screen |
| `fishing bite v2.png` | 2 | 28×16 (29px pitch) | fishing bite |
| `fishing1.png` | 1 | 16×16 | fishing initiate |

The character is front-facing; there are no up/down/side variants.

## Customers

`customer_1..6.png` are generated from `player/idle_0.png` by
`tools/build_customers.py` (hair, eyes, shirt recoloured). Static seated
sprites; tables pick one at random.

## Generated (do not edit)

```
player/
  idle_0..6.png           12x18 padded, feet at bottom
  walk_0..3.png
  hold_idle_0..6.png
  hold_walk_0..3.png
  player_frames.tres      animations: idle, walk, hold idle, hold walk
fishing/
  fishing_idle_0..4.png   28x16
  fishing_bite_0..1.png
  fishing_initiate_0.png  16x16
  fishing_frames.tres     animations: fishing idle, fishing bite, fishing initiate
```

Player frames share a 12×18 canvas so the feet stay planted when the animation
changes. `scenes/player.tscn` shows it at **2×** (32px tall), which matches the
32px tile grid.

## Rebuild after editing a sheet

```bash
pip install pillow            # once, for the slicing script
python tools/build_character.py
godot --headless --path . --import
godot --headless --path . -s res://tests/run_tests.gd
```

Animation names contain spaces (`hold walk`); `player.gd` uses them verbatim.
Speeds live in the `.tres` (idle 5 fps, walk 8 fps) — change them there, not in
code.
