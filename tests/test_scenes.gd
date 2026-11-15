extends RefCounted
## ============================================================================
## Scene load tests — catch parse/resource errors in every phase before a run.
## They do NOT call _ready(): that needs the autoload and a live tree, which
## the boot check (`godot --headless --path . --quit-after 5`) covers instead.
## ============================================================================

const SCENES := [
	"res://scenes/main.tscn",
	"res://scenes/morning.tscn",
	"res://scenes/fishing.tscn",
	"res://scenes/evening.tscn",
	"res://scenes/shop.tscn",
	"res://scenes/results.tscn",
	"res://scenes/player.tscn",
	"res://scenes/table.tscn",
	"res://scenes/tutorial.tscn",
]


static func run(t) -> void:
	for path in SCENES:
		var packed := load(path) as PackedScene
		t.check(packed != null, "scene loads: " + path)
		if packed == null:
			continue
		var node := packed.instantiate()
		t.check(node != null, "scene instantiates: " + path)
		if node == null:
			continue
		# A scene still instantiates when its root script fails to parse —
		# assert the script is actually attached, or parse errors pass silently.
		t.check(node.get_script() != null, "scene script attached: " + path)
		# Regression: phases used to build every node in code, leaving the
		# editor's Scene tab with only the root.
		t.check(node.get_child_count() > 0, "scene has nodes: " + path)
		node.free()
