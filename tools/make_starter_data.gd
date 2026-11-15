extends SceneTree
## ============================================================================
## make_starter_data.gd — generates the starter .tres content ONCE.
##
## Run from the project root:
##   godot --headless --path . -s res://tools/make_starter_data.gd
##
## After that, the .tres files under data/ are CONTENT: edit them in the
## Godot inspector or overwrite them by hand. This script only exists so the
## team starts with valid, complete resources instead of empty templates.
##
## It is safe to re-run (it overwrites), but don't: it will discard tuning.
## ============================================================================

const SpeciesDefScript := preload("res://scripts/data/species_def.gd")
const ModifierDefScript := preload("res://scripts/data/modifier_def.gd")
const GearDefScript := preload("res://scripts/data/gear_def.gd")
const TableDefScript := preload("res://scripts/data/table_def.gd")


func _initialize() -> void:
	_make_dirs()
	_make_species()
	_make_modifiers()
	_make_gear()
	_make_tables()
	print("[data] starter resources written to res://data/")
	quit(0)


func _make_dirs() -> void:
	for dir in ["data/species", "data/modifiers", "data/gear", "data/tables"]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://" + dir))


func _save(res: Resource, path: String) -> void:
	var err := ResourceSaver.save(res, path)
	if err != OK:
		printerr("[data] failed to save %s (error %d)" % [path, err])
	else:
		print("  wrote ", path)


# --- Species: 4 baseline + 1 rain-only. ------------------------------------
# Sprites point at the placeholder PNGs in assets/sprites/fish/ so the tank
# shows something from the first run. Overwrite the PNG; keep the name.
func _make_species() -> void:
	_species("lean_tuna", "Lean Tuna", 28, "lean", false)
	_species("salmon", "Salmon", 22, "fatty", false)
	_species("sea_bream", "Sea Bream", 26, "lean", false)
	_species("mackerel", "Mackerel", 14, "cheap", false)
	_species("eel", "Eel", 32, "fatty", true)
	_species("toro", "Fatty Tuna", 44, "fatty", false)
	_species("hokkigai", "Surf Clam", 30, "fatty", false)
	_species("ebi", "Sweet Shrimp", 24, "lean", false)
	_species("tako", "Octopus", 20, "lean", false)
	_species("cured_saba", "Cured Saba", 18, "cheap", false)
	_species("tamago", "Tamago", 12, "cheap", false)


func _species(id: String, display: String, price: int, preference: String, rain_only: bool) -> void:
	var s = SpeciesDefScript.new()
	s.id = id
	s.display_name = display
	s.base_price = price
	s.preference = preference
	s.rain_only = rain_only
	var art_path := "res://assets/sprites/fish/%s.png" % id
	if ResourceLoader.exists(art_path):
		s.sprite = load(art_path)
	var raw_map := {
		"lean_tuna": "tuna.png", "toro": "tuna.png", "salmon": "Salmon2.png",
		"sea_bream": "Sea bream.png", "mackerel": "Mackeral.png",
		"cured_saba": "Mackeral.png", "eel": "eel2.png",
	}
	if raw_map.has(id):
		var raw_path: String = "res://assets/sprites/fish/" + String(raw_map[id])
		if ResourceLoader.exists(raw_path):
			s.raw_sprite = load(raw_path)
	_save(s, "res://data/species/%s.tres" % id)


# --- Modifiers: the crate's rare slot. -------------------------------------
func _make_modifiers() -> void:
	_modifier("golden", "Golden", 1.75, 0, false, 0, Color(1.0, 0.84, 0.25))
	_modifier("chroma", "Chroma", 1.3, 1, false, 0, Color(0.6, 0.9, 1.0))
	_modifier("ice_cold", "Ice Cold", 1.0, 0, true, 0, Color(0.75, 0.95, 1.0))
	_modifier("double_serving", "Double Serving", 1.0, 0, false, 1, Color(1.0, 1.0, 1.0))


func _modifier(id: String, display: String, sale: float, luck: int, never: bool, extra: int, tint: Color) -> void:
	var m = ModifierDefScript.new()
	m.id = id
	m.display_name = display
	m.sale_mult = sale
	m.luck_bonus = luck
	m.never_spoils = never
	m.extra_plates = extra
	m.tint = tint
	_save(m, "res://data/modifiers/%s.tres" % id)


# --- Gear: one resource per line, costs in cash. --------------------------
# values[0] is the stock tier; costs[0] buys tier 1.
func _make_gear() -> void:
	_gear("rod", "Rod", "rod", "bar_width", [60, 140, 260], [0.0, 0.15, 0.3, 0.45],
		"Longer reel bar: easier perfect catches, which means bigger fish.")
	_gear("knife", "Knife", "knife", "cut_speed", [50, 120, 220], [0.0, 0.2, 0.4, 0.6],
		"Faster cutting at the board.")
	_gear("dishwasher", "Dishwasher", "dishwasher", "auto_wash", [80], [0.0, 1.0],
		"Removes the end-of-day wash minigame entirely.")
	_gear("freezer", "Freezer", "freezer", "freezer_slots", [90, 180], [0.0, 1.0, 2.0],
		"Two more slots for holding fish. Pairs with Ice Cold and hot days.")
	_gear("tray", "Tray", "tray", "carry_slots", [120, 240], [0.0, 1.0, 2.0],
		"Carry two plates at once; halves the trips during service.")


func _gear(id: String, display: String, slot: String, effect: String,
		costs: Array, values: Array, description: String) -> void:
	var g = GearDefScript.new()
	g.id = id
	g.display_name = display
	g.slot = slot
	g.effect = effect
	g.costs.assign(costs)
	g.values.assign(values)
	g.description = description
	_save(g, "res://data/gear/%s.tres" % id)


# --- Tables: 2-seat early, 4-seat later. ----------------------------------
func _make_tables() -> void:
	_table("table_2", 2, 2, "lean", 45.0)
	_table("table_4", 4, 3, "fatty", 45.0)


func _table(id: String, seats: int, plates: int, preference: String, patience: float) -> void:
	var td = TableDefScript.new()
	td.id = id
	td.seats = seats
	td.plates_wanted = plates
	td.preference = preference
	td.patience_seconds = patience
	_save(td, "res://data/tables/%s.tres" % id)
