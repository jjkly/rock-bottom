extends Node2D
## ============================================================================
## EVENING — Overcooked-style service, solo.
##
## Loop: select a fish in the stock panel -> walk to the cutting board (E) ->
## walk to a table (E) to serve a plate. Tables have preferences; matching pays
## +20% (RunState does the money, Table only tracks satisfaction).
##
## Service runs on a 55 s window with tables seated on a stagger. When every
## table is closed, a Continue button advances to the night.
##
## Deliberate simplifications for the first playable: cutting is instant,
## cooking and the wash phase are not wired yet, and tables can be walked
## through. See docs/PLAN.md Phase 1 for the full target.
## ============================================================================

const BOARD_POS := Vector2(170, 470)
const STOVE_POS := Vector2(170, 570)
const SINK_POS := Vector2(170, 670)
const PLAYER_START := Vector2(640, 330)
const TABLE_SLOTS: Array[Vector2] = [
	Vector2(430, 300), Vector2(830, 300),
	Vector2(430, 560), Vector2(830, 560),
	Vector2(1080, 430), Vector2(300, 300),
]
const SPAWN_MARKS: Array[float] = [0.0, 7.0, 14.0, 21.0, 28.0, 35.0]
const SERVICE_WINDOW := 55.0

var _tables: Array[Table] = []
var _table_defs: Array[TableDef] = []
var _player: Player
var _selected: FishInstance = null
var _stock_box: VBoxContainer
var _msg: Label
var _timer_label: Label
var _service_time := 0.0
var _spawned := 0
var _table_total := 4
var _service_over := false
var _ended := false


func _ready() -> void:
	set_process(true)
	_load_tables()
	_build_world()
	_build_ui()
	RunState.stock_changed.connect(_rebuild_stock)
	_rebuild_stock()


func _load_tables() -> void:
	for f in DirAccess.get_files_at("res://data/tables"):
		if f.ends_with(".tres"):
			var d := load("res://data/tables/" + f) as TableDef
			if d != null:
				_table_defs.append(d)
	if _table_defs.is_empty():
		_table_defs.append(TableDef.new())


func _build_world() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.10, 0.09, 0.08)
	bg.size = Vector2(1280, 720)
	bg.z_index = -10
	add_child(bg)

	var floor := ColorRect.new()
	floor.color = Color(0.16, 0.14, 0.12)
	floor.position = Vector2(60, 200)
	floor.size = Vector2(1160, 500)
	floor.z_index = -9
	add_child(floor)

	_add_prop("res://assets/sprites/restaurant/cutting_board.png", BOARD_POS)
	_add_prop("res://assets/sprites/restaurant/stove.png", STOVE_POS)
	_add_prop("res://assets/sprites/restaurant/sink.png", SINK_POS)
	_add_prop("res://assets/sprites/restaurant/tank.png", Vector2(1180, 640))

	var board_label := UI.label("CUT", 14, Color(1.0, 0.9, 0.5))
	board_label.position = BOARD_POS + Vector2(-18, -60)
	add_child(board_label)
	var stove_label := UI.label("STOVE", 14, Color(0.6, 0.6, 0.6))
	stove_label.position = STOVE_POS + Vector2(-24, -60)
	add_child(stove_label)
	var sink_label := UI.label("SINK", 14, Color(0.6, 0.6, 0.6))
	sink_label.position = SINK_POS + Vector2(-20, -60)
	add_child(sink_label)

	_player = Player.new()
	_player.position = PLAYER_START
	add_child(_player)

	_table_total = clampi(4 + int((RunState.day - 1) / 2.0), 4, 6)


func _add_prop(path: String, pos: Vector2) -> void:
	var s := Sprite2D.new()
	s.texture = load(path)
	s.position = pos
	add_child(s)


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)

	var panel := UI.panel()
	panel.position = Vector2(20, 90)
	layer.add_child(panel)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	panel.add_child(col)

	col.add_child(UI.label("STOCK", 16, Color(0.7, 0.8, 0.9)))
	_stock_box = VBoxContainer.new()
	_stock_box.add_theme_constant_override("separation", 4)
	col.add_child(_stock_box)

	_timer_label = UI.label("", 18, Color(0.9, 0.9, 0.6))
	_timer_label.position = Vector2(1080, 90)
	layer.add_child(_timer_label)

	_msg = UI.label("Select a fish, cut it, serve it.", 18, Color(0.85, 0.85, 0.85))
	_msg.position = Vector2(360, 680)
	layer.add_child(_msg)

	var help := UI.label("WASD move  ·  E: cut at board / serve at table", 15, Color(0.55, 0.6, 0.65))
	help.position = Vector2(360, 655)
	layer.add_child(help)


func _process(delta: float) -> void:
	if _ended:
		return
	_service_time += delta
	_timer_label.text = "Service  %ds" % int(SERVICE_WINDOW - _service_time)

	while _spawned < _table_total and _service_time >= SPAWN_MARKS[_spawned]:
		_spawn_table(_spawned)
		_spawned += 1

	if not _service_over:
		if _service_time >= SERVICE_WINDOW:
			_close_remaining()
		elif _spawned >= _table_total and _all_closed():
			_service_over = true
	if _service_over and _all_closed():
		_ended = true
		_show_continue()


func _spawn_table(index: int) -> void:
	var definition := _table_defs[index % _table_defs.size()]
	var t := Table.new()
	t.position = TABLE_SLOTS[index % TABLE_SLOTS.size()]
	t.setup(definition)

	var sprite := Sprite2D.new()
	sprite.texture = load("res://assets/sprites/restaurant/table_%d.png" % (4 if definition.seats >= 4 else 2))
	t.add_child(sprite)

	var info := UI.label("", 14, Color(0.95, 0.95, 0.9))
	info.position = Vector2(-55, -92)
	info.size = Vector2(110, 40)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_child(info)

	var refresh := func(_a = null, _b = null): _refresh_table_label(t, info)
	t.served.connect(refresh)
	t.patience_changed.connect(refresh)
	t.finished.connect(func(_ok): refresh.call())
	t.left_angry.connect(func(): refresh.call())

	_tables.append(t)
	add_child(t)
	t.seat()
	_refresh_table_label(t, info)


func _refresh_table_label(t: Table, info: Label) -> void:
	if t.closed:
		info.text = "closed"
		info.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		return
	var hearts := ""
	for i in Table.HEARTS:
		hearts += "♥" if i < t.hearts else "·"
	info.text = "%s  %s\n%d/%d plates" % [
		t.definition.preference, hearts, t.plates_served, t.definition.plates_wanted
	]


func _rebuild_stock() -> void:
	for child in _stock_box.get_children():
		child.queue_free()
	if RunState.stock.is_empty():
		_stock_box.add_child(UI.label("(empty)", 15, Color(0.6, 0.6, 0.65)))
		return
	for fish in RunState.stock:
		var b := UI.button("%s  $%d  ×%d" % [
			_short_name(fish), fish.value(), fish.plates_left
		], 250, 15)
		b.pressed.connect(func():
			_selected = fish
			_msg.text = "Selected %s" % fish.display_name()
		)
		_stock_box.add_child(b)


func _short_name(fish: FishInstance) -> String:
	var tag := ""
	if not fish.prepared:
		tag = " (raw)"
	return "%s%s" % [fish.species.display_name, tag]


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		_interact()
		get_viewport().set_input_as_handled()


func _interact() -> void:
	if _ended:
		return
	if _player.position.distance_to(BOARD_POS) < 110.0:
		_cut()
		return
	_serve()


func _cut() -> void:
	if _selected == null:
		_msg.text = "Pick a fish in the stock panel first."
		return
	if _selected.prepared:
		_msg.text = "Already cut."
		return
	_selected.prepared = true
	_msg.text = "Cut %s — ready to serve." % _selected.species.display_name
	_rebuild_stock()


func _serve() -> void:
	if _selected == null:
		_msg.text = "Pick a fish first."
		return
	if not _selected.prepared:
		_msg.text = "It is raw — cut it at the board."
		return
	var t := _nearest_table()
	if t == null:
		_msg.text = "No table in reach."
		return

	var matched := _selected.matches(t.definition.preference)
	var value := RunState.serve_plate(_selected, t.definition.preference)
	if value <= 0:
		_msg.text = "That table is done."
		return
	t.serve_plate(value, matched)
	_msg.text = "+$%d%s" % [value, "  (preference match)" if matched else ""]
	if _selected.plates_left <= 0:
		_selected = null
	_rebuild_stock()


func _nearest_table() -> Table:
	var best: Table = null
	var best_d := 120.0
	for t in _tables:
		if not t.seated or t.closed:
			continue
		var d := _player.position.distance_to(t.position)
		if d < best_d:
			best_d = d
			best = t
	return best


func _close_remaining() -> void:
	_service_over = true
	for t in _tables:
		if t.seated:
			t.tick(9999.0)


func _all_closed() -> bool:
	if _spawned < _table_total:
		return false
	for t in _tables:
		if not t.closed:
			return false
	return true


func _show_continue() -> void:
	var b := UI.button("Close the doors", 260, 22)
	b.position = Vector2(960, 620)
	b.pressed.connect(func(): RunState.advance_phase())
	add_child(b)
	_msg.text = "Service over. Cash earned: $%d." % RunState.cash
