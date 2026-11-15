class_name ModifierDef
extends Resource
## ============================================================================
## ModifierDef — the rare crate outcome. CONTENT, not code.
##
## The crate has one rare slot: ~8% of casts, split between these. That is
## ~3 rares per week, so each one should visibly change a decision.
##
## HOW TO ADD ONE: right-click data/modifiers/ -> New Resource... ->
## ModifierDef. Set the fields, save as data/modifiers/<id>.tres, add it to
## the crate's modifier pool.
## ============================================================================

@export var id := ""
@export var display_name := "Golden"

## Multiplies the plate value. 1.75 is a real jackpot; stay under 2.0.
@export var sale_mult := 1.0

## Permanent luck for this run (chroma is the only one that grants it).
@export var luck_bonus := 0

## Ice cold: ignores aging loss and hot-day spoilage. The tank-safety pick.
@export var never_spoils := false

## Double serving: +1 plate from the same fish.
@export var extra_plates := 0

## Tint the sprite in the tank/stock so the player can see a rare at a
## glance. White = no tint.
@export var tint: Color = Color.WHITE

@export_multiline var notes := ""
