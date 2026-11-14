class_name GearDef
extends Resource
## ============================================================================
## GearDef — one durable upgrade line. CONTENT, not code.
##
## The shop reads costs[] and values[]. `values` has one more entry than
## `costs`: values[0] is the starter item, values[1] is after the first
## purchase, and so on. This keeps the current effect readable at any tier.
##
## Effect ids the rest of the game understands (add here + implement in the
## consumer, never invent one in a scene):
#    "bar_width"     fishing reel bar size (0.0 stock -> 0.45 at tier 3)
#    "cut_speed"     cut minigame speed multiplier
#    "auto_wash"     1.0 = dishwasher removes the end-of-day wash minigame
#    "freezer_slots" extra freezer slots (RunState already applies this)
#    "carry_slots"   plates the player can carry at once (1 stock -> 2)
##
## HOW TO ADD GEAR: right-click data/gear/ -> New Resource... -> GearDef.
## Set slot to one of RunState.gear's keys, or add the key there first.
## ============================================================================

@export var id := ""
@export var display_name := "Rod"
@export var slot := "rod"                  # must exist in RunState.gear
@export var effect := "bar_width"          # see list above
@export var costs: Array[int] = []         # cost of tier 1, 2, 3...
@export var values: Array[float] = []      # tier 0, 1, 2, 3...
@export_multiline var description := ""

## Convenience for shop UI: cost of the next tier, or -1 if maxed.
func next_cost(current_tier: int) -> int:
	if current_tier >= costs.size():
		return -1
	return costs[current_tier]

## Effect value at a given tier, clamped to the authored array.
func value_at(tier: int) -> float:
	if values.is_empty():
		return 0.0
	return values[clampi(tier, 0, values.size() - 1)]
