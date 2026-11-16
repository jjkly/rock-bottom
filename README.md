# Rock Bottom

**One week. One debt. One shot.**

A quota-driven sashimi restaurant roguelite. You lost everything at the
tables; a loan shark gives you seven days and a run-down counter. Fish the
food yourself, serve it, and pay what you can before dawn on day eight.

## Summary

You are a chef with a gambling debt and a knife. Each day runs in three
phases: read the weather and go fishing, then cut and serve in the evening,
then face the ledger at night. The same crate that ruined you is the only way
to land the fish that make premium plates — it has negative expected value, and
you still have to use it in measured doses.

One run is one week, about **20–30 minutes**. The score is the share of the
debt you cleared. Seven installments are charged automatically when you sleep;
miss one and the week ends. Cash is always contested: pay the minimum, buy
gear, or save for the $700 balloon on night seven.

| | |
|---|---|
| Genre | Restaurant management roguelite, top-down pixel art |
| Players | Single player |
| Input | Keyboard + mouse |
| Session | One week, ~20–30 minutes |
| Technology | Godot 4.7.2, GDScript |
| Targets | Windows and Web |
| Current build | v0.9, in development |

## The week

| Phase | What you do | Pressure |
|---|---|---|
| **Morning** | Read weather and news, plan the day | Weather changes the catch and spoilage |
| **Fishing** | Reel bar decides size, crate decides species and rares | Casts are limited; the crate is a gamble |
| **Evening** | Cut at the board, carry plates, serve 4–6 tables | 45-second patience per table; preference matching |
| **Night** | Pay the installment, buy gear or training, sleep | Miss the minimum and the run ends |

Rares: **Golden** (+75% value), **Chroma** (+30%, +1 Luck), **Ice Cold**
(never spoils), **Double Serving** (+1 plate). Eleven species, one rain-only.
Selling raw pays 60%; serving pays full value and +20% when the fish matches
the table's preference — that gap is the reason to cook.

Three difficulties change the debt, rare odds and replay rules. Easy and
Medium allow a rewind to the morning of a missed day; Hard does not.

## Features

- Seven-day run with auto-charged installments and a final-day balloon.
- Skill reel + CS:GO-style crate reveal with four rare modifiers.
- Eleven fish species with preferences, sizes, plates and aging.
- Evening service: movement, carrying, cutting, patience, preference bonuses.
- Fish tank with one-day freshness; heat spoils everything except Ice Cold.
- Shop with three gear tracks (rod, knife, tank) and a 3-of-N training draft.
- Three difficulties, replay rewind, pause, settings and a day-1 tutorial.
- Menu, results screen, music and event SFX.
- Fully data-driven content: species, modifiers, gear and tables are `.tres` files.

## Design pillars

1. **Every dollar is a bet against the week.** Pay, upgrade or save — never all three.
2. **The addiction is the only road to the best plates.** The crate loses on average and is still mandatory in doses.
3. **A day has three tempos.** Plan, hunt, panic; none borrows the others' pacing.
4. **Relief, not mastery, is the win.** Days should end with the minimum scraped together.

## Status

Playable end to end: menu → one week → score. In development as v0.9.

Not built yet: bestiary, meta unlocks, customer walk-in animation, directional
player art, the angry-table flow penalty, and a mid-run save. Current gaps are
tracked in [`docs/GDD.md`](docs/GDD.md).

## Repository

| Path | Contents |
|---|---|
| `scenes/` | One scene per phase, plus menu, pause, settings, tutorial and results |
| `scripts/` | Phase logic, `Player`/`Table` systems, UI |
| `addons/framework/` | Autoloads: `RunState`, `Settings`, `Audio` |
| `data/` | Content: species, modifiers, gear, tables |
| `assets/` | Sprites, audio and the composed restaurant interior |
| `tests/` | Headless logic and scene tests |
| `tools/` | Art and data generators |
| `docs/` | Design, architecture, credits and the itch.io page guide |

## Documentation

- [`docs/GDD.md`](docs/GDD.md) — design, numbers, feature status, decisions.
- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) — runtime map, state API, signals, data, asset and audio pipelines.
- [`docs/CREDITS.md`](docs/CREDITS.md) — third-party art, music and SFX licences.
- [`docs/ITCH_PAGE.md`](docs/ITCH_PAGE.md) — every store page field with the value to paste.

## Credits

Art, design and code: the Rock Bottom team. Interior kit by **Bitglow**
(pixelinterior_LRK v1.1). Music by **Leonardo Paz**; sound effects from
Freesound and Pixabay contributors. Full licence details are in
[`docs/CREDITS.md`](docs/CREDITS.md) and in the in-game Settings → Credits
panel.

Have Fun!
