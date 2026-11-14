# Godot 4 + Team Create rules

## Run it

```bash
godot --headless --path . -s res://tests/run_tests.gd   # before every push; must be 0 failures
godot --headless --path . res://tests/smoke_flow.tscn   # drives a day through every phase
godot --path .
```

Full task order and file ownership: [docs/PLAN.md](docs/PLAN.md).

## Read in this order

1. [docs/SETUP.md](docs/SETUP.md) — **new teammate?** install, clone, play, push (no terminal)
2. [docs/PLAN.md](docs/PLAN.md) — what to do next, where, done-when
3. [docs/GDD.md](docs/GDD.md) — the design and every design number
4. [docs/contract.md](docs/contract.md) — names, RunState API, signals, scene contract
5. [docs/art.md](docs/art.md) — pixel grid, import, folder map

## Working together

- **One owner per `.tscn`.** Asked by name in `docs/PLAN.md` § Who does what.
  If you need a change in someone else's scene, ask — don't open it.
- **`project.godot` changes land alone**, after a heads-up in the group chat.
- **Balance lives in `data/*.tres`**, not in scripts. Tuning is a data commit.
- **A new rule gets a test** in the same commit (`tests/`).
- Never rename a file another scene references — Godot `.uid` files break
  other people's work silently.

## Branches

`main` stays runnable. Work on `feat/<thing>`, open a PR, run the tests in the
PR description, merge once green.
