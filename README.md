# Rock Bottom

A quota-driven sashimi restaurant roguelite. One week, seven installments,
one loan shark. Fish, gamble, cook, serve, survive the debt.

Godot **4.7.2**, GDScript, 2D pixel art, single player.

## Run

```bash
godot --path .                                          # play
godot --headless --path . -s res://tests/run_tests.gd   # logic suite, must be 0 failures
godot --headless --path . res://tests/smoke_flow.tscn   # drives a full week through every phase
```

First open after a clone: `godot --headless --path . --import` (or just open the editor once).

## Build

Export templates for 4.7.2, then:

```bash
godot --headless --path . --export-release "Windows Desktop" build/windows/RockBottom.exe
godot --headless --path . --export-release "Web"           build/web/index.html
```

`build/` is ignored. Both presets live in `export_presets.cfg`; the Web preset
is single-threaded, so it needs no COOP/COEP headers.

## Repository map

| Path | Contents |
|---|---|
| `scenes/main.tscn` | Router, HUD, menu/pause/tutorial overlays |
| `scenes/{morning,fishing,evening,shop,results}.tscn` | One scene per phase |
| `scripts/phases/` | Phase logic; scenes own their node trees |
| `scripts/systems/` | `Player`, `Table` components |
| `scripts/ui/` | Menu, pause, settings, tutorial, shared style helpers |
| `addons/framework/` | Autoloads: `RunState`, `Settings`, `Audio` |
| `data/` | Content `.tres`: species, modifiers, gear, tables |
| `scenes/settings.tscn` | Settings + credits panel |
| `assets/` | Sprites, audio, composed interior; `art_source/` is `.gdignore`d |
| `tools/` | Art/data generators (run only when regenerating) |
| `tests/` | Headless logic and scene tests |

## Docs

- [`docs/GDD.md`](docs/GDD.md) — design, numbers, feature status, decisions.
- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) — runtime map, RunState API, signals, data, asset and audio pipelines.
- [`docs/CREDITS.md`](docs/CREDITS.md) — third-party art, music and SFX licences.
- [`docs/ITCH_PAGE.md`](docs/ITCH_PAGE.md) — every itch.io page field with the value to paste.
- Folder-level `README.md` files next to generated art explain that folder's sources and sizes.

## Working rules

- **State lives in `RunState`.** Scenes call its public functions and connect to its signals; they never write its fields.
- **Balance lives in `data/*.tres`**, not in scripts. Tuning is a data commit.
- **One owner per `.tscn`.** Do not open a scene someone else owns; ask for the change.
- **Writes go to `user://`**, never `res://` (the exported pack is read-only).
- **A new rule gets a test** in `tests/`; run the suite before pushing.
- **Audio goes through `Audio.play("key")` / `Audio.play_music("key")`**; add the key to `addons/framework/audio.gd`.
