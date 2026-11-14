# Sashimi Debt — Game Design Document

**Version:** 0.1 · **Updated:** 2026-11-14 · [Features](#feature-index) · [Decisions](#decisions) · [Change log](#change-log)

## Summary

You are a chef who lost everything at the tables. A loan shark gives you one
week and a run-down sashimi counter: fish for the food yourself, serve it, and
pay what you can before dawn on day eight. The same gamble that ruined you —
the crate — is the only way to land the fish that make premium plates. A run is
one week; the score is the share of the debt you cleared.

| | |
|---|---|
| Genre and camera | Restaurant management roguelite, top-down 2D pixel art |
| Audience | Core players who like run-based pressure; 16+ (gambling theme) |
| Platforms and input | PC, keyboard; gamepad later. Godot 4.7, GL Compatibility |
| Session | One week ≈ 20–30 min; no mid-run save yet (open question) |
| Engine | Godot 4.7.2, GDScript, `addons/framework` owns state |
| Scope | Small release: 3-person team, 1 vertical slice first |
| References | Stardew Valley (reel bar, pixel town), CS:GO cases (crate reveal), Lethal Company / REPO (quota), Overcooked (evening service), Dave the Diver (fish then serve) |

## Pillars

1. **Every dollar is a bet against the week.** Cash can pay the minimum, buy
   gear, or become score. There is never enough for all three, so each night
   is a real choice — and paying early is deliberately the weakest option.
2. **The addiction is the only road to the best plates.** The crate has
   negative expected value, but Golden and Chroma fish are the only premium
   plates. You must use the thing that ruined you, in measured doses.
3. **A day has three tempos.** Plan in the morning, hunt in the afternoon,
   panic in the evening. The contrast is the point; none of the three may
   borrow the others' pacing.
4. **Relief, not mastery, is the win condition.** Days should end with the
   minimum scraped together, not comfortably beaten. The final screen is the
   number, and it is allowed to be short.

## Synopsis

A gambling addict with a debt and a knife. The loan shark's terms: one week,
one counter, no excuses. Mornings are the newspaper, the weather and the
delivery crates. Afternoons are the boat: a Stardew reel bar decides how big
the fish is, then a crate decides what it is. Evenings are the restaurant:
four tables, shared plates, omakase — the chef chooses what each table gets.
Nights are the ledger: pay the minimum, spend the rest on a better rod, a
sharper knife, another freezer slot, or a little more luck. On day eight the
remaining cash is taken and the week is scored. The story is told by the
numbers, not cutscenes.

## Core loop

```
morning: news + weather  ->  fishing: casts (reel -> size) -> crate (species + rare)
						 ->  stock
evening: prep (cut)      ->  service (plates, preferences, patience) -> cash
night:   pay minimum     ->  shop (gear / training) -> end_day()
day 7:   all cash settles the debt -> score = paid_total / 2000
```

- **Seconds:** reel bar, crate reveal, a plate carried to a table.
- **Minutes:** one day: ~1 min fishing, ~90 s service, ~25 s shop.
- **Session:** seven days, then the score screen; meta unlocks persist.

## Day structure

| Phase | Player does | Clock | Output |
|---|---|---|---|
| Morning | reads weather + news, opens shipments | none | today's plan |
| Fishing | casts, reel bar, crate reveal | cast count (6→8 by day 7) | stock |
| Evening | prep, cook, carry, serve, wash | table patience (45 s each) | cash |
| Night | pays minimum, buys gear/training | none | next day, or score |

## Weather

| State | Effect | Announced |
|---|---|---|
| Clear | baseline catch table | morning |
| Hot | every freezer fish spoils at end of day | morning (before casting) |
| Rain | swaps two species for rain-only ones (eel) | morning |

Weights 50/25/25; day 1 is always clear. No forecast system: hot resolves at
end of day, so the morning warning is enough to drain the freezer into service.

## Fish, plates and the crate

Value chain: `species.base_price × size × modifier × aging`.

- Reel bar success → size → 3/4/6/8 slices → 1/1/2/2 plates.
- Crate → species, plus one rare slot at ~8% per cast (~3 rares per week).
- Rares: **Golden** ×1.75 value · **Chroma** ×1.3 and +1 Luck · **Ice Cold**
  never ages or spoils · **Double Serving** +1 plate.
- Aging: ×1.00 / ×1.25 / **×1.40 at 2 days** / ×1.15 / ×0.80 / ×0.50.
- Serving pays full value, +20% when the fish matches the table's preference.
  Selling raw pays 60% — the gap is the reason to cook and serve.
- Odds are hidden until a species is caught, then logged in the bestiary.

## Evening service

Overcooked with one player: walk, carry, plate, serve.

| Rule | Value |
|---|---|
| Tables | 4 on day 1 → 6 by day 7 |
| Ticket | 2–3 plates, shared, one preference tag |
| Patience | 45 s, 3 hearts (15 s each), telegraphed by ring + audio |
| Angry tables | every 2 → −1 table tomorrow (floor 3) |
| Stations | cut (per fish), cook (optional), wash (end-of-day batch) |
| Upgrade effect | dishwasher deletes the wash phase; tray carries 2 plates |

Customers are a 4-state FSM (arriving → seated → eating → leaving); six
agents, so tile A* or pre-baked seat paths, not a navmesh.

## Economy

- Start debt $2,000. Minimums: 60 / 75 / 90 / 110 / 130 / 150 / 180 = $795
  (≈40% of the debt). Missing one ends the run.
- Daily income ≈ 1.4× that day's minimum; gear costs ≈ 0.5–1.5× daily income.
- Minimums are fixed; overpaying never lowers them. Paying early is a trap —
  settlement is automatic at the end of day 7, so the only decision is
  gear-vs-cash, and the final number is whatever survived.
- Difficulty: Easy = unlimited free replays, −20% minimums, ~100% clearable.
  Medium = one replay costing the day's earnings, baseline, ~85%. Hard = no
  replay, +15% minimums, ~70%.
- Night shop: Equipment (rod, knife, dishwasher, freezer, tray; durable,
  3 tiers each) and Training (one 3-of-N offer of Luck / Fishing / Speed,
  Luck may discount one). Both run-scoped.
- Meta unlocks at 50/70/90% repaid: species, prep methods, bait, starting
  freezer slot. Pool-widening only — never power.

## Screens and flow

```
Boot -> Title -> Run: Morning -> Fishing -> Evening -> Night -> ... -> Results -> Title
```

Fishing is a screen, the night shop is a menu, and the evening is the only
scene with movement and physics. That split is a scope decision, not a
presentation one.

## Feature index

| Feature | Status | Scope | Summary | Docs |
|---|---|---|---|---|
| Run and debt | implemented | MVP | One week, fixed minimums, automatic settlement, score | `addons/framework/run_state.gd` |
| Freezer and aging | implemented | MVP | 3 slots (+2/tier), edomae aging peak, hot spoilage | `scripts/data/fish_instance.gd` |
| Tables and patience | implemented | MVP | 45 s, 3 hearts, preference bonus, angry flow penalty | `scripts/systems/table.gd` |
| Fishing reel | designed | MVP | Stardew bar sets fish size (3/4/6/8 slices) | this doc |
| Crate and rares | designed | MVP | Species + one rare slot; odds hidden until caught | this doc |
| Weather and news | designed | MVP | Clear / hot / rain, announced each morning | this doc |
| Evening service | designed | MVP | Overcooked movement over 4–6 tables | this doc |
| Stations and minigames | designed | MVP | Cut, cook, wash; one input each | `scripts/systems/station.gd` |
| Shop and draft | designed | MVP | Equipment tabs + 3-of-N training offers | this doc |
| Bestiary | idea | later | Logs species and observed odds after first catch | — |
| Meta unlocks | idea | later | Milestone pool-widening across runs | — |
| Audio pass | idea | later | Service diegetics, crate reveal, debt sting | — |

## Milestones and work checklist

Step-by-step order, exact file names and per-owner tasks are in
[PLAN.md](PLAN.md) — phases 1 to 5. Milestones only, here:

**M1 — one playable day (greybox).** Fishing returns a fish, evening serves
four tables, night pays and advances. Done when a 7-day run reaches the score
screen with placeholder art and `tests/` is green. Tasks: PLAN.md phases 1–3.

| Owner | Task | Done when |
|---|---|---|
| Evening | Player CharacterBody2D, carry (0.3/0.55 m band), seat assignment, Table spawn/serve, Station hookup, end-of-day wash | One table seated, served, satisfied; one table starves and fires `left_angry` |
| Fishing | Reel bar minigame → `size_slices`, crate reveal → species + rare, stock handoff | A cast produces a `FishInstance` in `RunState.stock` |
| Run/UI | Morning news, night shop + draft, phase scene flow, HUD (cash, debt, day, weather), difficulty presets | Seven days advance without touching a debug key |
| Art | Species silhouettes, player 4-dir walk, table + ticket bubble, stations | Placeholders replaced in the evening scene |
| Everyone | A test per new rule; run `run_tests.gd` before pushing | Exit 0 |

**M2 — the week has teeth.** Shop and training, weather in the catch table,
freezer/hot-day loop, bestiary, 3 species + 1 rain-only, gear effects wired.

**M3 — presentation.** Art pass, audio, crate juice, score screen, meta
milestones. Only after M2 is fun.

## Where things live

| Path | What it is |
|---|---|
| `docs/PLAN.md` | **Start here.** Phase-by-phase tasks: what to do, where, done-when |
| `docs/contract.md` | Ownership, RunState API, signals, scene contract, Team Create rules |
| `docs/art.md` | 32 px grid, import settings, y-sort, sprite folders |
| `addons/framework/run_state.gd` | The only state authority; live tuning constants |
| `scripts/data/` | Resource schemas (species, modifier, gear, table, fish) |
| `data/` | Content `.tres` files — edit these, not code, to tune |
| `scripts/systems/` | `Table` and `Station` contracts for the evening scene |
| `tests/run_tests.gd` | Headless suite; the line to run before every push |
| `tools/make_starter_data.gd` | One-shot generator (already run; don't re-run over tuning) |
| `scenes/main.tscn` + `scripts/game.gd` | Temporary dev harness; replace with real scenes |
| `assets/sprites/{fish,characters,restaurant,ui}/` | Art drop folders with correctly-sized placeholders; see PLAN.md phase 0 |
| `assets/audio/{sfx,music}/` | Sound drop folders |

## Decisions

| ID | Date | Decision | Alternatives considered | Why | Affects |
|---|---|---|---|---|---|
| D-001 | 2026-11-14 | Seven days, score = share of debt repaid | endless tycoon; 10–12 day run | fits 20–30 min; the week is the story | run and debt |
| D-002 | 2026-11-14 | Minimums fixed; overpay only moves the score | overpay lowers future minimums; interest | simpler; keeps the gear-vs-debt tension at settlement | economy |
| D-003 | 2026-11-14 | Reel bar → size; crate → species + rare | two RNG rolls; crate decides tier | skill and luck get separate jobs; no double-random volume | fishing |
| D-004 | 2026-11-14 | Odds hidden until caught, then bestiary | fully visible; fully hidden | discovery without the "game cheats" feeling | crate |
| D-005 | 2026-11-14 | Crate EV negative, but necessary for premium plates | crate as a valid strategy | mechanics must argue against the addiction, not for it | economy, theme |
| D-006 | 2026-11-14 | Hot resolves at end of day, announced in the morning | resolve at start; forecast system | warning makes it a plan, not a mugging; no extra UI | weather |
| D-007 | 2026-11-14 | Evening = movement; fishing = screen; shop = menu | all screens; all movement | one expensive scene, two cheap ones, on a 3-person team | scope |
| D-008 | 2026-11-14 | Freezer capacity 3 + aging curve | storage only | makes holding a decision, Ice Cold a job | freezer |
| D-009 | 2026-11-14 | Run-scoped gear/stats; meta unlocks pool only | meta power progression | keeps the week honest across runs | shop, meta |
| D-010 | 2026-11-14 | Difficulty changes replays and minimums | difficulty changes odds | odds must stay a read, not a setting | run |

## Open questions

- **Mid-run save:** none yet. A 25-minute run may not need one; quitting on
  day 4 currently loses the week. Decide before the first external build.
- **Crate pacing:** ~3 rares per week is a guess; playtest casts 8% vs 12%.
- **Solo Overcooked load:** 6 tables × 3 stations needs a stopwatch, not an
  opinion. Measure a day-7 service; cut to 5 tables if it exceeds 2 minutes.
- **Angry penalty:** "−1 table per 2 angry" may cascade. Watch a run that
  loses two tables on day 3.
- **Team Create:** concurrent `.tscn` edits remain the top production risk;
  the contract says one owner per scene, and that has to be enforced socially.

## Change log

**0.1 (2026-11-14):** first draft — summary, pillars, loop, weather, service,
economy, feature map, M1 checklist, decisions D-001…D-010.
