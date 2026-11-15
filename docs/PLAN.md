# The Plan — what to do, in order, and where

This is the only file you need open while working. It says, phase by phase,
exactly where to put a file, what to type, and how to know it is done.

- **Design decisions and numbers** live in [GDD.md](GDD.md).
- **Names and APIs** (RunState calls, signals, node names) live in
  [contract.md](contract.md).
- **Art rules** live in [art.md](art.md).
- This file turns the three into a checklist.

Rules that apply to every phase:

- **New teammate, no coding experience?** Send them
  [SETUP.md](SETUP.md) — install, clone, open, play, push, all with buttons.

```bash
cd C:/Users/admin/Desktop/sashimi-debt

# before you push
godot --headless --path . -s res://tests/run_tests.gd   # must print "0 failures"

# to play
godot --path .
```

Do not edit a `.tscn` that another person owns, and do not edit
`project.godot` without saying so in the group chat.

## Playable now (2026-11-14)

The whole week runs: morning news -> fishing (reel + crate) -> evening (cut,
serve, patience) -> night (shop, pay) -> results.
Art is the character sheets + nigiri; tables and stations are still placeholders.

Every phase is a real scene tree in `scenes/` (open one and the Scene tab
shows its labels, panels and sprites); scripts only fill text and wire
signals. `scenes/player.tscn` and `scenes/table.tscn` are reusable pieces.

Controls: `WASD` + `E`. Stand at the cutting board to take a plate, at a table
to serve it. Fishing and shop use the mouse / Space.

```bash
godot --path .                                        # play
godot --headless --path . res://tests/smoke_flow.tscn # drives one day + results
```

Still stubbed: bestiary, meta unlocks, difficulty presets, audio, and all real art. Everything below still describes the target.

---

## Balance pass (2026-11-15, from balance.txt)

- [x] Debt is installments: 100/150/200/250/300/300/700 = $2,000, auto-charged; day 7 is a balloon
- [x] Single player: Player2 and `p2_*` input removed
- [x] Stations moved to the top wall; tables pulled within ~500 px of the board
- [x] Player speed 215 -> 300; stock list scrolls so a full inventory can't cover the room
- [x] Bar has four zones; centre = 8 slices and biases the loot roll
- [x] Crate is a CS:GO-style scrolling reel with rarity frames, name below
- [x] Missing art: see [SPRITES.md](SPRITES.md)
- [x] Fish tank replaces the freezer (one day safe, heat still spoils, click to take)
- [x] Preference tags + colours; tables shuffle position and preference per service
- [x] Day-1 tutorial popups (pause, More, HUD "?")
- [x] Store/dock backgrounds cover-fill with dim; "Go to dock"
- [x] 5x fisherman, E skips the crate, 2.16s reel, catch "!"
- [x] Shop confirm when a purchase would break the installment; confirm before a short sleep
- [ ] Customer walk-in / seated sprites
- [ ] Angry tables actually reduce tomorrow's flow
- [ ] Audio

## Phase 0 — the place to put art (done, use it)

The folders exist now and every placeholder file is in place with the right
size, so the game can load art before art exists.

| Folder | Put here | Naming rule |
|---|---|---|
| `assets/sprites/fish/` | one PNG per species — **one image, no frames** | name **must** equal `SpeciesDef.id`: `lean_tuna.png`, `mackerel.png`, `eel.png` |
| `assets/sprites/characters/` | player and customers | `player_<dir>_<frame>.png`, `<dir>` = `down`/`up`/`side`, `<frame>` = 0–3 (12 files total; left = flipped side, idle = frame 0) |
| `assets/sprites/restaurant/` | tables, cutting board, tank, tileset | fixed names: `2 table.png`, `4 table.png`, `cutting_board.png`, `tank.png`, `tiles_floor.png` |
| `assets/sprites/ui/` | 16×16 icons | fixed names: `heart_full.png`, `heart_empty.png`, `weather_clear.png`, `weather_hot.png`, `weather_rain.png`, `crate_frame.png`, `coin.png` |
| `assets/audio/sfx/`, `assets/audio/music/` | sound | `sfx/<event>.ogg` (`serve.ogg`, `angry.ogg`, `crate_open.ogg`, `coin.ogg`, `reel_tick.ogg`) |

The magenta-grid PNGs currently in `assets/sprites/` are **placeholders**. To
replace one, overwrite it with the same filename and size, or larger by a
multiple of the grid. Never rename a placeholder; scenes will point at these
paths.

Sizes: fish 32×24-ish (any, origin bottom-centre), player 32×48, tables 64×64
and 96×64, props 64×64, tiles 32×32 inside a 128×128 sheet, icons 16×16.

After dropping a fish PNG: open the matching `data/species/<id>.tres` in
Godot, set **sprite** to the PNG, save. That is the only wiring step.

---

## Phase 1 — the evening scene (the big one)

**Status:** playable. Player movement, stock panel, instant cut, serve,
preferences, patience, tank storage, auto-end. No cooking or washing.

**Owner:** one person. **You own `scenes/evening.tscn`; nobody else opens it.**

Create in this order, saving after each step:

1. `scenes/evening.tscn`: `Background`, `Floor`, `Props` (CuttingBoard, Tank),
   `Tables`, `Players/Player1`, and a `UI` CanvasLayer (stock, tank panel,
   timer, message, continue).
2. `Player` reads `p1_*` actions, `MOTION_MODE_FLOATING`, speed 300, and emits
   `interact_requested`; the evening scene decides what E means.
3. Tables: instantiate `scenes/table.tscn`, duplicate the `TableDef` so the
   shared resource is never mutated, and reroll slot + preference per service.
   Slots are filtered so none sit under the stock panel.
4. Cut: click a stock fish to select it, stand at the board, press E. The fish
   is marked `prepared` and a plate goes into the player's hands
   (`RunState.take_plate`). Hold animations play while carrying.
5. Serve: stand at a table, press E. `RunState.pay_plate` pays (with the +20%
   preference match) and `Table.serve_plate` records satisfaction.
6. Tank: select a stock fish + E to store; click a fish in the tank panel to
   move it back to stock. One day safe, then spoils.
7. Service ends when every table is closed or the 55 s window expires; the
   Continue button calls `RunState.advance_phase()`.
8. Cooking and washing do **not** exist; there is no stove/sink station.

**Done when:** four tables seat, two get served and close satisfied, one
starves and fires `left_angry`, and the day advances — all with magenta
placeholders.

**Test to add:** `tests/test_evening.gd` — spawn a table, serve it via
RunState, assert cash rose. Register it in `tests/run_tests.gd`.

---

## Phase 2 — the fishing screen

**Status:** playable. Reel bar, size roll, crate reveal, rare slot, rain-only
pool, stock handoff. Bestiary/odds log is not built.

**Owner:** one person. **You own `scenes/fishing.tscn`.**

1. Root `Control` (it is a screen, not a world). One `Button` or `interact`
   press = one cast, `RunState.gear["rod"]` widens the bar
   (`GearDef.effect == "bar_width"`, value from `data/gear/rod.tres`).
2. Reel bar: Stardew-style moving marker inside a zone. Success → pick a size
   from `{3, 4, 6, 8}` slices (perfect = highest).
3. Crate: build the species pool from `data/species/*.tres`, skipping
   `rain_only` species unless `RunState.weather == Weather.RAIN`. Roll one rare
   from `data/modifiers/*.tres` at 8% (Golden 2.5 / Chroma 1.5 / Ice Cold 2 /
   Double Serving 2).
4. Build `FishInstance.new(species, slices, modifier)` and call
   `RunState.add_to_stock(fish)`.
5. Repeat for however many casts; then `RunState.advance_phase()`.

**Done when:** a cast puts a fish in `RunState.stock` with the right value, and
`RunState.debug_state()` shows the stock count rising.

**Test to add:** `tests/test_fishing.gd` — a rain day never yields a non-rain
species; a golden fish's value matches `FishInstance.value()`.

---

## Phase 3 — morning, shop, phases (glue)

**Status:** playable. Router, morning, HUD, shop, results, difficulty presets
not started (replay rules are unimplemented).

**Owner:** one person, can be the same person as Phase 2.

1. `scenes/morning.tscn`: shows `RunState.weather` and tomorrow's weight, a
   "Start fishing" button → `RunState.advance_phase()`.
2. `scenes/shop.tscn` (menu): list `data/gear/*.tres`, show
   `GearDef.next_cost(RunState.gear[slot])`, buy with
   `RunState.upgrade_gear(slot, cost)`. Second tab: the 3-of-N training offer
   calling `RunState.add_stat()`.
3. `scenes/hud.tscn`: cash, debt, day/7, weather icon. Connect
   `cash_changed`, `debt_changed`, `day_started`, `weather_changed` — never poll.
4. `scenes/main.tscn` → route by `RunState.phase`: MORNING→morning scene,
   FISHING→fishing, EVENING→evening, NIGHT→shop. Replace `scripts/game.gd`
   (the dev harness) — delete it when the routing works.
5. Night: "Pay extra" calls `RunState.pay_extra()`, "Sleep" calls
   `RunState.end_day()`, which charges the installment; if it returns false the
   run ends and `run_ended` shows the score.

**Done when:** Enter is no longer needed to play; a full week runs from the
morning screen to the score screen.

**Test to add:** extend `tests/test_economy.gd` with a scripted 7-day run that
asserts the score and that a missed minimum ends it.

---

## Phase 4 — art and audio pass

1. Replace every placeholder listed in Phase 0; the game should look finished
   without any code change. If something is missing, the scene keeps the
   placeholder and nothing crashes.
2. Add the character directions to the player: `player_down_0..3`,
   `player_up_0..3`, `player_side_0..3` (32×48), 8 fps in an
   `AnimatedSprite2D`. Left = `flip_h` on the side frames; idle = frame 0.
3. Audio: `assets/audio/sfx/*.ogg` played from the scene that owns the event
   (serve, angry, crate open, coin). Do not add an autoload for audio yet.
4. Crate reveal: this is the game's signature moment — do it once, well, in
   `scenes/fishing.tscn`.

**Done when:** no magenta pixels remain, and a day plays with sound.

---

## Phase 5 — meta and polish (after the week is fun)

Bestiary (log species + observed odds on first catch), meta unlocks at
50/70/90% repaid, difficulty presets from GDD § Economy, title screen, pause.

---

## Who does what

| Role | Owns | Never touches |
|---|---|---|
| Evening owner | `scenes/evening.tscn`, `scenes/table.tscn`, `scripts/systems/player.gd`, minigame scenes | `scenes/fishing.tscn`, `data/*.tres` |
| Fishing owner | `scenes/fishing.tscn`, `tests/test_fishing.gd` | `scenes/evening.tscn` |
| Run/UI owner | `scenes/morning.tscn`, `scenes/shop.tscn`, `scenes/hud.tscn`, `scenes/main.tscn` | scenes of the other two |
| Art owner | `assets/**` | anything under `scripts/`, `scenes/` |
| Anyone | `tests/**`, `data/**/*.tres` (say when you tune) | `project.godot` |

## If you are blocked

1. Read the header comment of the script you are calling — every one explains
   its rule.
2. Run the tests; a red test names the rule that broke.
3. Call `RunState.debug_state()` in a `print()` and look at the whole week.
4. Only then ask the others, and say what you already tried.
