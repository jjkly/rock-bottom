# Missing sprites

What art the game still needs, where it is used, and the size to draw it.
Everything here currently renders as a magenta placeholder (or text) and does
not block play.

## Blocking-ish (visible every run)

| Asset | Path | Size | Used by | Notes |
|---|---|---|---|---|
| Eel nigiri | `assets/sprites/fish/eel.png` | 16×16 | stock once cut, served plate | Raw eel art now exists (`eel2.png`); the nigiri is still the placeholder. Rain-only, $32. |
| Table (2 seat) | `assets/sprites/restaurant/2 table.png` | 64×64 | `scenes/table.tscn` | **Added.** Origin: floor contact, bottom-centre. |
| Table (4 seat) | `assets/sprites/restaurant/4 table.png` | 96×64 | `scenes/table.tscn` | **Added.** Swapped by `TableDef.seats`. |
| Cutting board | `assets/sprites/restaurant/cutting_board.png` | 64×64 | evening `Props/CuttingBoard` | Interaction point is its centre. |
| Tank | `assets/sprites/restaurant/tank.png` | 64×36 | evening `Props/Tank`, tank panel | **Added** from `makebead-64x36 13.png`. |
| Floor tiles | `assets/sprites/restaurant/tiles_floor.png` | 32×32 tiles in a sheet | evening `Floor` (currently a flat color) | Needs a TileMapLayer in the scene. |

## Backgrounds

Present: store (`backgrounds/makebead-99x66.png`) on the morning screen, dock
(`-2`) on fishing, and a "To Dock" sign (`-3`, unused). Backgrounds cover-fill
the 1280×720 frame (aspect-preserving crop) with mipmaps and a dim overlay.
Restaurant interior art is still missing.

## Raw fish (pre-cut)

Wired through `SpeciesDef.raw_sprite` and shown in the crate reel and raw stock rows.

| Species | Art | Present |
|---|---|---|
| Lean Tuna / Fatty Tuna | `fish/tuna.png` | yes |
| Salmon | `fish/Salmon2.png` | yes |
| Sea Bream | `fish/Sea bream.png` | yes |
| Mackerel / Cured Saba | `fish/Mackeral.png` | yes |
| Eel | `fish/eel2.png` | yes |
| Surf Clam, Shrimp, Octopus, Tamago | — | **missing** (falls back to nigiri) |

## Characters

| Asset | Size | Notes |
|---|---|---|
| Customer walk-in | 16px tall, 4 directions × 4 frames | Tables currently spawn with nobody walking to them. |
| Customer seated | 16px tall, 1 frame per direction | Eating pose would sell the service. |
| Player up/down/side walk | 16px tall | The current sheet is **front-facing only**, so facing never changes. |
| Player carrying, directional | 16px tall | Hold frames exist front-on only. |
| Chef idle variant | 16px | Optional; idle currently loops on 7 near-identical frames. |

## UI / feedback

| Asset | Path | Size | Notes |
|---|---|---|---|
| Hearts | `assets/sprites/ui/heart_full.png` / `heart_empty.png` | 16×16 | Table patience is drawn as text `♥` today. |
| Weather | `weather_clear/hot/rain.png` | 16×16 | Weather is text on the morning screen and HUD. |
| Coin | `coin.png` | 16×16 | Cash popups / HUD. |
| Ticket bubble | `ticket_bubble.png` | 32×32 | Table order bubble. |
| Crate filler | `crate_frame.png` | 16×16 | Used for species without art (eel) — currently the magenta placeholder, which is actually the intended "unknown" look. |
| Plate | — | 16×16 | Hold animations bake the plate in; a separate plate sprite is needed if plates become physical items. |
| Fish whole-body | — | 16×16 per species | Nigiri in a tank reads wrong; needed if the tank shows live fish. |

## Environment

| Asset | Notes |
|---|---|
| Restaurant walls / counter | The room is a flat rectangle with a floor color; no walls, no counter geometry. |
| Chairs | Tables have no chairs; parties are implied. |
| Door | No entrance; customers have nowhere to come from. |
| Decor | Optional: lanterns, menu board, plants — the room is very empty at 1280×720. |

## Rules

- Fish: file name must equal `SpeciesDef.id`; set `SpeciesDef.sprite` (the `.tres`
  already points at the file, so overwriting in place is enough).
- Tables/stations: overwrite the PNG in place; `scenes/table.tscn` and
  `scenes/evening.tscn` already reference the paths.
- Character frames: regenerate with `python tools/build_character.py` after
  replacing a source sheet; do not hand-edit generated frames.
- Keep pixel art on the 32px grid, nearest filter, origin bottom-centre for
  props and characters.
