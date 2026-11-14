class_name TableDef
extends Resource
## ============================================================================
## TableDef — how a table behaves during service. CONTENT, not code.
##
## HOW TO ADD: right-click data/tables/ -> New Resource... -> TableDef.
## The evening scene spawns one Table node per TableDef and calls setup().
##
## Difficulty knobs: fewer plates + longer patience early, more tables later.
## RunState does not spawn tables; the evening scene decides how many.
## ============================================================================

@export var id := ""
@export var seats := 2
## How many plates this table will order in total (shared, omakase).
@export var plates_wanted := 2
## What they enjoy; matching plates get +20%. Must match SpeciesDef.preference.
@export_enum("lean", "fatty", "rare", "cheap") var preference := "lean"
## Total time before they leave angry. 45s with 3 hearts = 15s per heart.
@export var patience_seconds := 45.0
