# Contract

Everything the three of us code against. If a name in here changes, the person
changing it updates every caller and says so. This file is the source of truth
for names, not for design — the design lives in [GDD.md](GDD.md) and the task
order in [PLAN.md](PLAN.md).

## Ownership

| Path | Owner | Rule |
|---|---|---|
| `addons/framework/run_state.gd` | framework | only the framework owner edits; everyone else calls it |
| `scripts/data/*.gd` | framework | schema; add a field + tell the team |
| `scripts/systems/*.gd` | framework stubs | after handoff, whoever implements owns it |
| `data/**/*.tres` | whoever tunes | content, no code changes needed |
| `scenes/**` | scene owner | **one owner per `.tscn`**, never two Team Create cursors in one file |
| `project.godot` | framework | changes land alone, with a heads-up |
| `tests/**` | framework | add tests freely; keep them scene-free |
| `assets/**` | art owner | see `docs/art.md` |

Rule of thumb: the framework owns what scenes **import**; scenes own what they
**show**. That is why we can work at the same time.

## Run it

```bash
# first clone / after pulling new assets
godot --headless --path . --import

# generate starter .tres once (already done; don't re-run over tuning)
godot --headless --path . -s res://tools/make_starter_data.gd

# tests — must be green before a push
godot --headless --path . -s res://tests/run_tests.gd

# play
godot --path .
```

The dev harness (`scripts/game.gd` + `scenes/main.tscn`) is temporary: Enter
advances the phase; at NIGHT it pays the minimum and ends the day.

## The week

```
MORNING  news/weather -> FISHING (reel bar + crate) -> EVENING (service) -> NIGHT
NIGHT    pay minimum -> shop -> end_day() -> next morning  (7 days, then settle)
```

Phases live in `RunState` only. A scene changing phase calls
`RunState.advance_phase()`; it never writes `phase`.

Every night the minimum from `RunState.minimum_today()` must be paid or the run
ends. Cash left over at the end of day 7 is applied to the debt automatically;
the score is `paid_total / debt_start`.

## RunState API (autoload)

| Call | Use |
|---|---|
| `start_run(seed)` | once, from the boot scene |
| `advance_phase()` | MORNING → FISHING → EVENING → NIGHT |
| `end_day()` | NIGHT only; returns false on a missed minimum |
| `minimum_today()` | the `$` due tonight |
| `pay_minimum()` | false if wrong phase / already paid / short |
| `earn(n)` / `spend(n)` | money in/out (service pays through `serve_plate`) |
| `add_to_stock(fish)` | fishing scene, after the crate resolve |
| `serve_plate(fish, pref)` | returns cash; handles the +20% match |
| `freeze(fish)` / `sell(fish, from_freezer)` | freezer capacity / raw sale (60%) |
| `upgrade_gear(slot, cost)` | shop; recomputes freezer slots |
| `add_stat(name, n)` | nightly draft (luck / fishing / speed) |
| `debug_state()` | one-line readout; every test prints it on failure |

Slots: `rod`, `knife`, `dishwasher`, `freezer`, `tray`.
Stats: `luck`, `fishing`, `speed`.

## Signals (connect, don't poll)

`phase_changed(from, to)` · `day_started(day)` · `cash_changed(cash)` ·
`debt_changed(remaining)` · `stock_changed` · `freezer_changed` ·
`gear_changed(slot, tier)` · `quota_paid(day, amount)` · `quota_missed(day)` ·
`weather_changed(weather)` · `run_ended(ratio, remaining)`

## Content (no code)

Duplicate an existing `.tres` and edit it; the game loads by `id`.

- **Species** (`data/species/`): `base_price` is per plate, `preference` must
  match a `TableDef` preference for the bonus, `rain_only` keeps it out of
  clear/hot days, `sprite` waits for art.
- **Modifier** (`data/modifiers/`): the crate's rare slot. `sale_mult`,
  `luck_bonus`, `never_spoils`, `extra_plates`, `tint`.
- **Gear** (`data/gear/`): `slot` must exist in `RunState.gear`; `costs[i]`
  buys tier `i+1`; `values[i]` is the effect at tier `i`.
- **Table** (`data/tables/`): `plates_wanted` and `patience_seconds` are the
  difficulty knobs.

## Scene contract

- One `Table` node per table, `setup(def)` then `seat()`; call `tick(delta)`
  via `_process` (the node does it itself once seated).
  `Table.serve_plate(value, matched)` only records satisfaction — money and the
  +20% match are `RunState.serve_plate`'s job. Never multiply twice.
- One `Station` node per station; the player's interaction calls `interact()`
  and the station emits `plate_ready(fish)`.
- Player carries plates with a 0.3 m attach / 0.55 m detach band (no flicker).
- Y-sort the restaurant container; collision layers are named in
  `project.godot` (world/player/stations/tables/customers).
- Every custom system gets `debug_state() -> String`. No exceptions.

## Team Create rules

1. Scene owner only. If you need a change in someone's scene, ask; don't open it.
2. `project.godot` changes are announced before they land.
3. No renames after something references a path — Godot `.uid` files will
   break other people's scenes.
4. New shared systems go in `scripts/data` or `addons/framework` and get a
   test on the same day.

## Done means

`godot --headless --path . -s res://tests/run_tests.gd` exits 0, and every
number you touched still matches the doc that states it.
