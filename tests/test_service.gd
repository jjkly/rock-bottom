extends RefCounted
## ============================================================================
## Service tests — the table contract. These are the rules the evening scene
## depends on, so they stay tested even before the scene exists.
## ============================================================================

const TableScript := preload("res://scripts/systems/table.gd")
const TableDefScript := preload("res://scripts/data/table_def.gd")


static func run(t) -> void:
	_test_patience(t)
	_test_serving(t)
	_test_preference(t)


static func _table(plates: int = 2, preference: String = "lean", patience: float = 45.0):
	var def = TableDefScript.new()
	def.id = "test_table"
	def.seats = 2
	def.plates_wanted = plates
	def.preference = preference
	def.patience_seconds = patience
	var node = TableScript.new()
	node.setup(def)
	return node


static func _test_patience(t) -> void:
	var tbl = _table()
	var flags := {"angry": false}
	tbl.left_angry.connect(func(): flags["angry"] = true)
	tbl.seat()
	t.eq(tbl.hearts, 3, "table starts with 3 hearts")

	tbl.tick(15.0)
	t.eq(tbl.hearts, 2, "one heart lost at 15s")
	tbl.tick(14.0)
	t.eq(tbl.hearts, 2, "no heart lost before 30s")
	tbl.tick(1.1)
	t.eq(tbl.hearts, 1, "one heart left at 30s")

	tbl.tick(14.0)
	t.eq(flags["angry"], false, "still waiting at 44s")
	tbl.tick(1.0)
	t.eq(flags["angry"], true, "leaves angry at 45s")
	t.eq(tbl.closed, true, "angry table is closed")
	tbl.free()


static func _test_serving(t) -> void:
	var tbl = _table(2)
	var flags := {"finished": false}
	tbl.finished.connect(func(satisfied): flags["finished"] = satisfied)
	tbl.seat()
	tbl.serve_plate(40, "lean")
	t.eq(tbl.plates_served, 1, "first plate counted")
	t.eq(tbl.closed, false, "table still open after one of two plates")
	tbl.serve_plate(40, "lean")
	t.eq(tbl.closed, true, "table closes after the second plate")
	t.eq(flags["finished"], true, "finished fires satisfied")
	tbl.free()


static func _test_preference(t) -> void:
	var tbl = _table(2, "fatty")
	var got := {"matched": false, "value": 0}
	tbl.served.connect(func(value, matched):
		got["matched"] = matched
		got["value"] = value
	)
	tbl.seat()
	tbl.serve_plate(50, "fatty")
	t.eq(got["matched"], true, "matching preference is flagged")
	t.eq(got["value"], 60, "matching preference pays +20%")

	var other = _table(2, "fatty")
	var got2 := {"matched": true, "value": 0}
	other.served.connect(func(value, matched):
		got2["matched"] = matched
		got2["value"] = value
	)
	other.seat()
	other.serve_plate(50, "lean")
	t.eq(got2["matched"], false, "wrong preference is flagged")
	t.eq(got2["value"], 50, "wrong preference pays base")
	tbl.free()
	other.free()
