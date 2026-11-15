class_name SpeciesDef
extends Resource
## ============================================================================
## SpeciesDef — one kind of fish. THIS IS CONTENT, NOT CODE.
##
## HOW TO ADD A FISH (no script changes needed):
##   1. In the FileSystem dock, right-click data/species/ -> New Resource...
##      -> SpeciesDef.
##   2. Fill the fields below, set sprite (32x32 PNG recommended, see
##      docs/ARCHITECTURE.md), save as data/species/<id>.tres.
##   3. Drop it into the crate's species pool (the fishing scene's export).
##
## Keep ids snake_case and unique; save files are matched by id, not path.
## ============================================================================

## Unique key. Never rename after a run structure depends on it.
@export var id := ""

## Shown on tickets, the bestiary, and the shop.
@export var display_name := "Fish"

## Base price of ONE plate before size, modifier and aging. Money is whole
## numbers; keep base prices in 10-40 for the current economy.
@export var base_price := 20

## What this table likes. Must match TableDef.preference for the +20% bonus.
## lean / fatty / expensive / cheap
@export_enum("lean", "fatty", "expensive", "cheap") var preference := "lean"

## Rain-only species never appear on clear or hot days. The bestiary logs
## them the first time they are caught, which is the point of rain.
@export var rain_only := false

## Nigiri art: what the fish looks like once cut and served.
@export var sprite: Texture2D

## Whole-fish art: shown before cutting (crate reel, raw stock rows).
## Falls back to the nigiri, then the filler tile, when null.
@export var raw_sprite: Texture2D

## Free text for the team (tuning notes, where the art came from).
@export_multiline var notes := ""
