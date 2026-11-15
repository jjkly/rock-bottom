extends Node2D
## ============================================================================
## EVENING — single-player, Overcooked-style service.
##
## Workflow: stand at the cutting board -> E takes a plate (the fish is prepared
## automatically for now) -> stand at a table -> E serves it. `hold idle` /
## `hold walk` play while a plate is carried.
##
## Layout is tuned for money-making, not walking: the three stations sit along
## the top wall and tables are within ~500 px of the board. Player speed is
## 300 px/s.
##
## Node tree lives in scenes/evening.tscn. The stock panel (scrollable) picks
## which fish the next plate comes from.
## ============================================================================

const TABLE_SCENE := preload("res://scenes/table.tscn")
const TABLE_SLOTS: Array[Vector2] = [
	Vector2(400, 330), Vector2(880, 330),
	Vector2(400, 540), Vector2(760, 540),
	Vector2(1080, 440), Vector2(340, 610),
]
const SPAWN_MARKS: Array[float] = [0.0, 7.0, 14.0, 21.0, 28.0, 35.0]
const SERVICE_WINDOW := 55.0
const BOARD_RANGE := 120.0
const TABLE_RANGE := 120.0

@onready var _player: Player = $Players/Player1
@onready var _tables_node: Node2D = $Tables
@onready var _stock_box: VBoxContainer = $UI/StockPanel/Scroll/StockList
@onready var _msg: Label = $UI/Message
@onready var _timer_label: Label = $UI/TimerLabel
@onready var _continue: Button = $UI/ContinueButton
@onready var _tank_panel: ColorRect = $UI/TankPanel
@onready var _tank_items: VBoxContainer = $UI/TankPanel/TankList/TankItems
@onready var _preview: Control = $UI/PlatePreview
@onready var _preview_fish: TextureRect = $UI/PlatePreview/FishIcon
@onready var _board_pos: Vector2 = $Props/CuttingBoard.position
@onready var _tank_pos: Vector2 = $Props/Tank.position

var _tables: Array[Table] = []
var _table_defs: Array[TableDef] = []
var _slots: Array[Vector2] = []
const PREFERENCES := ["lean", "fatty", "cheap"]
var _next_fish: FishInstance = null
var _service_time := 0.0
var _spawned := 0
var _table_total := 4
var _service_over := false
var _ended := false


func _ready() -> void:
	_load_tables()
	_table_total = clampi(4 + int((RunState.day - 1) / 2.0), 4, 6)
	_continue.visible = false
	_continue.pressed.connect(func(): RunState.advance_phase())
	_player.interact_requested.connect(_on_interact)
	# Fresh table layout every service: unique slots, random preferences.
	# Never place a table under the stock panel.
	var panel_rect := Rect2(20, 90, 270, 380)
	_slots = TABLE_SLOTS.filter(func(p): return not panel_rect.has_point(p))
	_slots.shuffle()
	RunState.stock_changed.connect(_rebuild_stock)
	RunState.tank_changed.connect(_rebuild_tank)
	_rebuild_stock()
	_rebuild_tank()
	set_process(true)


func _load_tables() -> void:
	for f in DirAccess.get_files_at("res://data/tables"):
		if f.ends_with(".tres"):
			var d := load("res://data/tables/" + f) as TableDef
			if d != null:
				_table_defs.append(d)
	if _table_defs.is_empty():
		_table_defs.append(TableDef.new())


func _process(delta: float) -> void:
	if _ended:
		return
	_service_time += delta
	_timer_label.text = "Service  %ds" % int(SERVICE_WINDOW - _service_time)
	_tank_panel.visible = _player.position.distance_to(_tank_pos) < 160.0

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
	# Duplicate the def so the shared resource's preference is never mutated.
	var definition: TableDef = _table_defs[index % _table_defs.size()].duplicate()
	var prefs := PREFERENCES.duplicate()
	if RunState.weather == 2:  # expensive only makes sense when eel is around
		prefs.append("expensive")
	definition.preference = prefs[RunState.rng.randi_range(0, prefs.size() - 1)]
	var t: Table = TABLE_SCENE.instantiate()
	t.position = _slots[index % _slots.size()]
	t.setup(definition)
	_tables_node.add_child(t)
	_tables.append(t)
	t.seat()


func _on_interact() -> void:
	# After service you can still walk to the tank and store fish.
	if _player.position.distance_to(_tank_pos) < 160.0:
		_store_selected()
		return
	if _ended:
		_msg.text = "Service is over - store fish at the tank, then close the doors."
		return
	if _player.position.distance_to(_board_pos) < BOARD_RANGE:
		_take_plate()
	else:
		_serve()


## Select a stock fish, stand at the tank, press E to store it.
func _store_selected() -> void:
	if _next_fish == null or not RunState.stock.has(_next_fish):
		_msg.text = "Select a fish in stock first, then E at the tank."
		return
	var stored_name := _next_fish.species.display_name
	if RunState.freeze(_next_fish):
		UI.sfx("inventory")
		_msg.text = "Stored %s in the fish tank." % stored_name
		_next_fish = null
		_show_preview(null)
		_rebuild_stock()
		_rebuild_tank()
	else:
		_msg.text = "The fish tank is full."


func _take_plate() -> void:
	if _player.carrying != null:
		_msg.text = "Already carrying a plate — serve it first."
		return
	var fish := _pick_fish()
	if fish == null:
		_msg.text = "No fish in stock. Go fishing."
		return
	if not fish.prepared:
		fish.prepared = true  # cutting minigame is still a stub
	if not RunState.take_plate(fish):
		_msg.text = "That fish has no plates left."
		return
	_player.set_carrying(fish)
	UI.sfx("plate")
	_next_fish = null
	_show_preview(null)
	_msg.text = "Took %s — $%d per plate" % [fish.species.display_name, fish.value()]
	_rebuild_stock()


func _pick_fish() -> FishInstance:
	if _next_fish != null and RunState.stock.has(_next_fish) and _next_fish.plates_left > 0:
		return _next_fish
	for fish in RunState.stock:
		if fish.plates_left > 0:
			return fish
	return null


func _serve() -> void:
	if _player.carrying == null:
		_msg.text = "Empty hands — take a plate at the board."
		return
	var t := _nearest_table()
	if t == null:
		_msg.text = "No table in reach."
		return
	var fish := _player.carrying
	var matched := fish.matches(t.definition.preference)
	var value := RunState.pay_plate(fish, t.definition.preference)
	t.serve_plate(value, matched)
	_player.set_carrying(null)
	_msg.text = "Served +$%d%s" % [value, "  (preference match)" if matched else ""]
	_rebuild_stock()


func _nearest_table() -> Table:
	var best: Table = null
	var best_d := TABLE_RANGE
	for t in _tables:
		if not t.seated or t.closed:
			continue
		var d := _player.position.distance_to(t.position)
		if d < best_d:
			best_d = d
			best = t
	return best


func _rebuild_stock() -> void:
	if _next_fish != null and not RunState.stock.has(_next_fish):
		_next_fish = null
		_show_preview(null)
	for child in _stock_box.get_children():
		child.queue_free()
	if RunState.stock.is_empty():
		_stock_box.add_child(UI.label("(empty)", 15, Color(0.6, 0.6, 0.65)))
		return
	for fish in RunState.stock:
		var tag := fish.species.preference
		var b := UI.button("%s (%s)  $%d  ×%d" % [_short_name(fish), tag, fish.value(), fish.plates_left], 230, 15)
		b.add_theme_color_override("font_color", UI.tag_color(tag))
		b.custom_minimum_size.y = 34
		var icon_tex: Texture2D = fish.species.sprite if fish.prepared else fish.species.raw_sprite
		if icon_tex == null:
			icon_tex = fish.species.sprite
		if icon_tex != null:
			b.icon = icon_tex
			b.expand_icon = true
			b.add_theme_constant_override("icon_max_width", 24)
		b.pressed.connect(func():
			_next_fish = fish
			_show_preview(fish)
			UI.sfx("inventory")
			_msg.text = "Next plate: %s" % fish.display_name()
		)
		_stock_box.add_child(b)


## Selected fish sits on the plate preview under the stock panel.
func _show_preview(fish: FishInstance) -> void:
	if fish == null:
		_preview.visible = false
		_preview_fish.texture = null
		return
	var tex: Texture2D = fish.species.sprite if fish.prepared else fish.species.raw_sprite
	if tex == null:
		tex = fish.species.sprite
	_preview_fish.texture = tex
	_preview.visible = tex != null


func _short_name(fish: FishInstance) -> String:
	return fish.species.display_name + ("" if fish.prepared else " raw")


func _rebuild_tank() -> void:
	for child in _tank_items.get_children():
		child.queue_free()
	if RunState.tank.is_empty():
		_tank_items.add_child(UI.label("(empty)", 14, Color(0.6, 0.65, 0.7)))
		return
	for fish in RunState.tank:
		var tag := fish.species.preference
		var state := "spoiled" if fish.spoiled else ("today" if fish.age_days == 0 else "day %d" % fish.age_days)
		var b := UI.button("%s (%s)  $%d  %s" % [
			fish.species.display_name, tag, fish.value(), state
		], 280, 14)
		b.custom_minimum_size.y = 34
		b.add_theme_color_override("font_color", UI.tag_color(tag))
		b.pressed.connect(func():
			if RunState.take_from_tank(fish):
				UI.sfx("inventory")
				_msg.text = "Took %s out of the tank." % fish.species.display_name
			_rebuild_tank()
			_rebuild_stock()
		)
		_tank_items.add_child(b)


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
	_continue.visible = true
	_msg.text = "Service over. Cash: $%d." % RunState.cash
