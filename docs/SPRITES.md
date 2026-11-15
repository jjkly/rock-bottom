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

## Backgrounds

Present: store (`backgrounds/makebead-99x66.png`) on the morning screen and dock
(`-2`) on fishing (cover-fill, mipmaps, dim overlay). The evening room uses a
composed `restaurant/interior.png` built from the Bitglow interior kit
(`assets/art_source/pixelinterior`, see `docs/CREDITS.md`): wall, stone floor,
counter, cabinets, door, fridge.

## Raw fish (pre-cut)

Wired through `SpeciesDef.raw_sprite` and shown in the crate reel and raw stock rows.

| Species | Art | Present |
|---|---|---|
| Lean Tuna / Fatty Tuna | `fish/tuna.png` | yes |
| Salmon | `fish/Salmon2.png` | yes |
| Flounder | `fish/flounder.png` | yes |
| Mackerel / Cured Saba | `fish/Mackeral.png` | yes |
| Eel | `fish/eel2.png` | yes |
| Surf Clam | `fish/surfclam.png` | yes |
| Shrimp | `fish/Shrimp.png` | yes |
| Octopus | `fish/octopus.png` | yes |
| Tamago | — | falls back to nigiri (egg) |

## Characters

| Asset | Size | Notes |
|---|---|---|
| Customer seated | 12×18, 6 variants | **Added** in `characters/customers/`; hair, eyes and shirt recoloured from the chef idle frame. Static, seated behind tables. |
| Customer walk-in | 16px tall, 4 directions × 4 frames | Missing; tables currently just appear with a seated customer. |
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
| Plate | `fish/plate.png` | **Added** 260×258 | Selected fish is drawn on it in the stock preview under the panel. |
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
