extends SceneTree
## ============================================================================
## apply_raw_art.gd — one-shot: wire the whole-fish art to SpeciesDef.raw_sprite.
##
##   godot --headless --path . --import
##   godot --headless --path . -s res://tools/apply_raw_art.gd
##
## Raw art is shown until the fish is cut (crate reel, raw stock rows); the
## nigiri in `sprite` takes over after preparation.
## ============================================================================

const RAW := {
	"lean_tuna": "tuna.png",
	"toro": "tuna.png",          # same fish; toro is the belly cut
	"salmon": "Salmon2.png",
	"sea_bream": "flounder.png",
	"mackerel": "Mackeral.png",
	"cured_saba": "Mackeral.png", # cured mackerel
	"eel": "eel2.png",
	"hokkigai": "surfclam.png",
	"ebi": "Shrimp.png",
	"tako": "octopus.png",
}


func _initialize() -> void:
	for id in RAW:
		var path := "res://data/species/%s.tres" % id
		var def := load(path) as SpeciesDef
		if def == null:
			printerr("missing species: ", path)
			continue
		var art: String = "res://assets/sprites/fish/" + String(RAW[id])
		if not ResourceLoader.exists(art):
			printerr("missing art: ", art)
			continue
		def.raw_sprite = load(art)
		var err := ResourceSaver.save(def, path)
		if err != OK:
			printerr("save failed: ", path, " error ", err)
		else:
			print("  ok ", path, " <- ", RAW[id])
	quit(0)
