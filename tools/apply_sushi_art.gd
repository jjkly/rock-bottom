extends SceneTree
## ============================================================================
## apply_sushi_art.gd — one-shot: wire the 10 kawaii nigiri sprites to species.
##
##   godot --headless --path . --import
##   godot --headless --path . -s res://tools/apply_sushi_art.gd
##
## Existing species keep their rules and only gain `sprite`. The six extra
## nigiri become new species so all ten sprites are actually used. Eel stays
## without art (no eel in the pack) — see docs/GDD.md.
## ============================================================================

const SpeciesDefScript := preload("res://scripts/data/species_def.gd")

const EXISTING := {
	"lean_tuna": "lean_tuna.png",
	"salmon": "salmon.png",
	"sea_bream": "sea_bream.png",
	"mackerel": "mackerel.png",
}

const NEW_SPECIES := [
	# id, display, price, preference, art
	["toro", "Fatty Tuna", 44, "fatty", "toro.png"],
	["hokkigai", "Surf Clam", 30, "fatty", "hokkigai.png"],
	["ebi", "Sweet Shrimp", 24, "lean", "ebi.png"],
	["tako", "Octopus", 20, "lean", "tako.png"],
	["cured_saba", "Cured Saba", 18, "cheap", "cured_saba.png"],
	["tamago", "Tamago", 12, "cheap", "tamago.png"],
]


func _initialize() -> void:
	for id in EXISTING:
		var path := "res://data/species/%s.tres" % id
		var def := load(path) as SpeciesDef
		if def == null:
			printerr("missing species: ", path)
			continue
		def.sprite = load("res://assets/sprites/fish/" + EXISTING[id])
		_save(def, path)

	for row in NEW_SPECIES:
		var id: String = row[0]
		var path := "res://data/species/%s.tres" % id
		var def := SpeciesDefScript.new()
		def.id = id
		def.display_name = row[1]
		def.base_price = row[2]
		def.preference = row[3]
		def.sprite = load("res://assets/sprites/fish/" + row[4])
		_save(def, path)

	quit(0)


func _save(res: Resource, path: String) -> void:
	var err := ResourceSaver.save(res, path)
	if err != OK:
		printerr("save failed: ", path, " error ", err)
	else:
		print("  ok ", path)
