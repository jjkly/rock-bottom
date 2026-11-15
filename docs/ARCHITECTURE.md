# Architecture

How the running game is wired. Design lives in [GDD.md](GDD.md); licences in
[CREDITS.md](CREDITS.md). If a name here changes, update every caller in the
same commit.

## Runtime map

`scenes/main.tscn` is the permanent shell: phase router, HUD, main menu, pause
and tutorial overlays. Exactly one phase scene is mounted at a time under
`PhaseHolder`.

```
scenes/main.tscn
  MORNING  -> scenes/morning.tscn
  FISHING  -> scenes/fishing.tscn
  EVENING  -> scenes/evening.tscn
  NIGHT    -> scenes/shop.tscn
  run_ended -> scenes/results.tscn

overlays: scenes/menu.tscn, scenes/pause.tscn, scenes/settings.tscn, scenes/tutorial.tscn
```

Autoloads (`project.godot`):

| Autoload | File | Owns |
|---|---|---|
| `RunState` | `addons/framework/run_state.gd` | The week: day, phase, cash, debt, stock, tank, gear, weather, difficulty |
| `Settings` | `addons/framework/settings.gd` | `user://settings.cfg`, Music/SFX buses, fullscreen |
| `Audio` | `addons/framework/audio.gd` | Music tracks, one-shot SFX pool, signal-driven sounds |

Phases change only through `RunState.advance_phase()` / `end_day()`; scenes
never write `phase`. The router reacts to `phase_changed` and `run_ended`.

## RunState API

| Call | Use |
|---|---|
| `set_difficulty(value)` | Before `start_run`; minimums, rare odds, replays |
| `start_run(seed)` | New week from the menu |
| `advance_phase()` | MORNING → FISHING → EVENING → NIGHT |
| `end_day()` | NIGHT only; charges the installment, returns false when the run ends |
| `installment_today()` / `installment_number()` | Today's charge and its index |
| `pay_extra(amount)` | Voluntary overpayment, capped at the debt |
| `earn(n)` / `spend(n)` | Money in/out |
| `add_to_stock(fish)` | After the crate resolves |
| `take_plate(fish)` | Remove one plate from stock and carry it |
| `pay_plate(fish, pref)` | Pay for a carried plate; applies preference and knife bonuses |
| `serve_plate(fish, pref)` | Convenience one-shot: pay + take a plate |
| `freeze(fish)` / `take_from_tank(fish)` | Move fish into / out of the tank |
| `sell(fish, from_tank)` | Raw sale at 60% |
| `upgrade_gear(slot, cost)` | Shop; recomputes tank capacity |
| `add_stat(name, n)` | Nightly training (luck / fishing / speed) |
| `debug_state()` | One-line state dump used by tests |

Slots: `rod`, `knife`, `tank`. Stats: `luck`, `fishing`, `speed`.
`serve_plate` is for tests and one-shot callers; the evening scene uses the
carry path (`take_plate` → `pay_plate`).

## Signals

| Signal | Fired when |
|---|---|
| `phase_changed(from, to)` | Phase advances |
| `day_started(day)` | A day begins, including day 1 |
| `cash_changed(cash)` | Cash earned or spent |
| `debt_changed(remaining)` | Debt paid or settled |
| `stock_changed` / `tank_changed` | Fish moved between stock and tank |
| `gear_changed(slot, tier)` | Shop upgrade |
| `quota_paid(day, amount)` | Installment charged successfully |
| `quota_missed(day)` | Installment could not be paid |
| `weather_changed(weather)` | Morning weather roll |
| `run_ended(ratio, remaining)` | Week over, score screen |

Connect to these; never poll for state changes.

## Content

All tuning is in `.tres` under `data/`; the game loads by `id`. Duplicate an
existing resource to add content.

| Folder | Schema | Knobs |
|---|---|---|
| `data/species/` | `SpeciesDef` | `base_price`, `preference`, `rain_only`, `sprite`, `raw_sprite` |
| `data/modifiers/` | `ModifierDef` | `sale_mult`, `luck_bonus`, `never_spoils`, `extra_plates`, `tint` |
| `data/gear/` | `GearDef` | `slot`, `costs[]`, `values[]`, `effect` |
| `data/tables/` | `TableDef` | `seats`, `plates_wanted`, `patience_seconds`, preferences |

`tools/make_starter_data.gd` generated the first set once; do not re-run it
over tuned content.

## Scene and system contracts

- **Scenes own their node trees.** Phase scripts fill text and connect signals;
  do not build permanent UI with `add_child()` in a phase script.
- **Player** (`scripts/systems/player.gd`): `CharacterBody2D`, `player_prefix`,
  emits `interact_requested`, carries plates with a 0.3 m attach / 0.55 m
  detach band. Displayed at 3× on the 32 px grid.
- **Table** (`scripts/systems/table.gd`): one node per table; `setup(def)` then
  `seat()`. `Table.serve_plate(value, matched)` only records satisfaction and
  emits `served` / `left_angry` / `finished`; all money is `RunState`'s job.
- **Settings** (`scenes/settings.tscn`): shared by menu, pause and the back
  button; also shows the third-party audio credits.
- **Tutorial** (`scenes/tutorial.tscn`): one popup per phase on day 1; pauses
  the tree while open.
- **Y-sort** the restaurant container; collision layers are named in
  `project.godot`.

## Audio

`Audio` builds the `Music` and `SFX` buses; volumes come from `Settings`.
Music loops by replaying on `finished`. Missing files are ignored so the game
runs before a sound exists.

- Tracks: `main`, `restaurant`.
- SFX: `click`, `spin`, `inventory`, `plate`, `knock`, `rare`, `chime`.
- Signal-driven: `quota_paid` → chime, `quota_missed` → knock.
- To add a sound: put the file in `assets/audio/sfx/`, add a key to `SFX`, call
  `Audio.play("key")` (or `UI.sfx("key")` from UI code), and record its licence
  in [CREDITS.md](CREDITS.md).

## Art pipeline

- 1280×720 viewport, `canvas_items` stretch, integer scaling; 32 px tile grid.
- Nearest filtering, mipmaps off, lossless; no fractional sprite scale.
- Fish PNG names must equal `SpeciesDef.id`; tables/stations keep fixed names
  referenced by scenes.
- Player frames are generated from source sheets in `assets/art_source/characters/`
  by `tools/build_character.py`; customers by `tools/build_customers.py`;
  the interior by `tools/build_interior.py`. Do not hand-edit generated frames.
- `assets/art_source/` is `.gdignore`d so Godot never imports source files.
- Folder-level READMEs document source sheets, sizes, and rebuild commands.
- `tools/apply_sushi_art.gd` and `tools/apply_raw_art.gd` are historical
  one-shots that wired art into the `.tres` files; do not re-run them over
  tuned content.

## Tests and export

```bash
godot --headless --path . -s res://tests/run_tests.gd   # logic, 0 failures
godot --headless --path . res://tests/smoke_flow.tscn   # full-week smoke
```

Export presets: `Windows Desktop` (single embedded-PCK exe) and `Web`
(single-threaded, Compatibility renderer). Output goes to ignored `build/`.

## Collaboration rules

1. One owner per `.tscn`; never two editors in one scene.
2. `project.godot` changes land alone, after a heads-up.
3. No renames after a scene references a path; `.uid` files break silently.
4. Shared systems live in `addons/framework/` or `scripts/data/` and get a test
   in the same commit.
5. `main` stays runnable; work on `feat/<thing>` and merge after tests pass.
