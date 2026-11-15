extends Node2D
## ============================================================================
## EVENING — two-player, Overcooked-style service.
##
## P1: WASD + E      P2: arrows + Enter
## Workflow per player: stand at the cutting board -> press interact to take a
## plate (the fish is prepared automatically for now) -> stand at a table ->
## press interact to serve it. `hold idle` / `hold walk` animations play while
## a plate is carried.
##
## Node tree lives in scenes/evening.tscn. The stock panel picks which fish the
## next plate comes from; plates are per-player (`Player.carrying`).
## ============================================================================

const TABLE_SCENE := preload("res://scenes/table.tscn")
const TABLE_SLOTS: Array[Vector2] = [
	Vector2(430, 300), Vector2(830, 300),
	Vector2(430, 560), Vector2(830, 560),
	Vector2(1080, 430), Vector2(300, 300),
]
const SPAWN_MARKS: Array[float] = [0.0, 7.0, 14.0, 21.0, 28.0, 35.0]
const SERVICE_WINDOW := 55.0
const BOARD_RANGE := 110.0
const TABLE_RANGE := 120.0

@onready var _players: Array[Player] = [$Players/Player1, $Players/Player2]
@onready var _tables_node: Node2D = $Tables
@onready var _stock_box: VBoxContainer = $UI/StockPanel/StockList
@onready var _msg: Label = $UI/Message
@onready var _timer_label: Label = $UI/TimerLabel
@onready var _continue: Button = $UI/ContinueButton
@onready var _board_pos: Vector2 = $Props/CuttingBoard.position

var _tables: Array[Table] = []
var _table_defs: Array[TableDef] = []
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
	for player in _players:
		player.interact_requested.connect(_on_interact.bind(player))
	RunState.stock_changed.connect(_rebuild_stock)
	_rebuild_stock()
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
	var t: Table = TABLE_SCENE.instantiate()
	t.position = TABLE_SLOTS[index % TABLE_SLOTS.size()]
	t.setup(definition)
	_tables_node.add_child(t)
	_tables.append(t)
	t.seat()


func _on_interact(player: Player) -> void:
	if _ended:
		return
	if player.position.distance_to(_board_pos) < BOARD_RANGE:
		_take_plate(player)
	else:
		_serve(player)


func _take_plate(player: Player) -> void:
	if player.carrying != null:
		_msg.text = "%s is already carrying a plate — serve it first." % player.player_prefix.to_upper()
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
	player.set_carrying(fish)
	_next_fish = null
	_msg.text = "%s takes %s — $%d per plate" % [
		player.player_prefix.to_upper(), fish.species.display_name, fish.value()
	]
	_rebuild_stock()


func _pick_fish() -> FishInstance:
	if _next_fish != null and RunState.stock.has(_next_fish) and _next_fish.plates_left > 0:
		return _next_fish
	for fish in RunState.stock:
		if fish.plates_left > 0:
			return fish
	return null


func _serve(player: Player) -> void:
	if player.carrying == null:
		_msg.text = "%s has empty hands — take a plate at the board." % player.player_prefix.to_upper()
		return
	var t := _nearest_table(player)
	if t == null:
		_msg.text = "No table in reach."
		return
	var fish := player.carrying
	var matched := fish.matches(t.definition.preference)
	var value := RunState.pay_plate(fish, t.definition.preference)
	t.serve_plate(value, matched)
	player.set_carrying(null)
	_msg.text = "%s served +$%d%s" % [
		player.player_prefix.to_upper(), value, "  (preference match)" if matched else ""
	]
	_rebuild_stock()


func _nearest_table(player: Player) -> Table:
	var best: Table = null
	var best_d := TABLE_RANGE
	for t in _tables:
		if not t.seated or t.closed:
			continue
		var d := player.position.distance_to(t.position)
		if d < best_d:
			best_d = d
			best = t
	return best


func _rebuild_stock() -> void:
	for child in _stock_box.get_children():
		child.queue_free()
	if RunState.stock.is_empty():
		_stock_box.add_child(UI.label("(empty)", 15, Color(0.6, 0.6, 0.65)))
		return
	for fish in RunState.stock:
		var b := UI.button("%s  $%d  ×%d" % [_short_name(fish), fish.value(), fish.plates_left], 230, 15)
		b.custom_minimum_size.y = 34
		if fish.species.sprite != null:
			b.icon = fish.species.sprite
			b.expand_icon = true
			b.add_theme_constant_override("icon_max_width", 24)
		b.pressed.connect(func():
			_next_fish = fish
			_msg.text = "Next plate: %s" % fish.display_name()
		)
		_stock_box.add_child(b)


func _short_name(fish: FishInstance) -> String:
	var tag := " (raw)" if not fish.prepared else ""
	return "%s%s" % [fish.species.display_name, tag]


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
