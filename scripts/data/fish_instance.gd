class_name FishInstance
extends RefCounted
## ============================================================================
## FishInstance — one physical fish. Runtime only, never saved as a resource.
##
## The chain that decides what a plate is worth:
##   species.base_price  (content, data/species/*.tres)
##   x size multiplier   (skill: the reel bar decides 3/4/6/8 slices)
##   x modifier mult     (gacha: golden, chroma, ... data/modifiers/*.tres)
##   x aging multiplier  (freezer timing — peaks at 2 days, then rots)
##
## Also owns plate count: one fish yields 1-2 plates, a "double serving"
## modifier adds one. Each plate is a separate serving to a table.
##
## WHO EDITS THIS
##   Framework owner. Designers change the numbers in RunState / the .tres
##   files, not here. If you want a new modifier behaviour, add it to
##   ModifierDef and read it here.
## ============================================================================

# Skill outcome -> value. Slices are the fishing bar's reward tier.
const SIZE_MULTIPLIERS := {3: 0.75, 4: 1.0, 6: 1.25, 8: 1.5}
# Slices -> how many plates the fish can serve.
const SIZE_PLATES := {3: 1, 4: 1, 6: 2, 8: 2}

# Aging curve indexed by days held: peak at 2 days, rot after 3.
# Edomae-style: curing improves the fish, then it turns. Ice cold skips this.
const AGING_MULTIPLIERS: Array[float] = [1.0, 1.25, 1.4, 1.15, 0.8, 0.5]

var species: SpeciesDef
var size_slices := 3
var modifier: ModifierDef = null
var age_days := 0
var plates_left := 1
var spoiled := false
## Set at the cutting board. Raw fish cannot be served; the evening scene
## enforces it, RunState stays policy-free.
var prepared := false


func _init(p_species: SpeciesDef, p_size_slices: int, p_modifier: ModifierDef = null) -> void:
	species = p_species
	size_slices = p_size_slices
	modifier = p_modifier
	plates_left = SIZE_PLATES.get(size_slices, 1)
	if modifier != null:
		plates_left += modifier.extra_plates


## What one plate from this fish sells/serves for right now.
func value() -> int:
	if spoiled or species == null:
		return 0
	var mult := float(SIZE_MULTIPLIERS.get(size_slices, 1.0))
	if modifier != null:
		mult *= modifier.sale_mult
	mult *= aging_multiplier()
	return int(round(species.base_price * mult))


func aging_multiplier() -> float:
	if modifier != null and modifier.never_spoils:
		return 1.0
	var idx := clampi(age_days, 0, AGING_MULTIPLIERS.size() - 1)
	return AGING_MULTIPLIERS[idx]


## True when this fish fits what a table asked for. One definition, used by
## both RunState (money) and the evening scene (ticket feedback).
func matches(preference: String) -> bool:
	return species != null and species.preference == preference


## For UI: "Golden Tuna (8 slices, age 2)". Keep display text in one place.
func display_name() -> String:
	var prefix := ""
	if modifier != null:
		prefix = modifier.display_name + " "
	return "%s%s (%d slices%s)" % [
		prefix,
		species.display_name if species != null else "???",
		size_slices,
		", age %d" % age_days if age_days > 0 else "",
	]


func debug_state() -> String:
	return "%s value=%d plates=%d age=%d spoiled=%s" % [
		display_name(), value(), plates_left, age_days, str(spoiled)
	]
