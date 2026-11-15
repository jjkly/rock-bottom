class_name Table
extends Node2D
## ============================================================================
## Table — one party during evening service.
##
## The node tree lives in scenes/table.tscn (Sprite + Info label), instantiated
## by the evening scene. The table owns its own visual: patience hearts, plate
## count, preference, closed state. The evening scene only seats it and calls
## serve_plate().
##
## Money is NOT handled here. RunState pays; the table records satisfaction.
## ============================================================================

signal served(plate_value: int, matched: bool)
signal left_angry
signal finished(satisfied: bool)
signal patience_changed(hearts: int)

const HEARTS := 3

@onready var _sprite: Sprite2D = $Sprite
@onready var _info: Label = $Info

var definition: TableDef
var seated := false
var closed := false
var elapsed := 0.0
var plates_served := 0
var hearts := HEARTS


func _ready() -> void:
	served.connect(func(_v, _m): _refresh_visual())
	patience_changed.connect(func(_h): _refresh_visual())
	finished.connect(func(_ok): _refresh_visual())
	left_angry.connect(_refresh_visual)
	_apply_texture()
	_refresh_visual()


## Call before adding to the tree, or before seat().
func setup(p_definition: TableDef) -> void:
	definition = p_definition
	if is_node_ready():
		_apply_texture()
		_refresh_visual()


func seat() -> void:
	if definition == null:
		push_warning("Table.seat() without setup() — using defaults.")
		definition = TableDef.new()
	seated = true
	closed = false
	elapsed = 0.0
	plates_served = 0
	hearts = HEARTS
	set_process(true)
	patience_changed.emit(hearts)


func serve_plate(plate_value: int, matched: bool) -> void:
	if not seated or closed:
		return
	plates_served += 1
	served.emit(plate_value, matched)
	if plates_served >= definition.plates_wanted:
		_close(true)


## Driven by _process in the scene; tests call it directly with a delta.
func tick(delta: float) -> void:
	if not seated or closed:
		return
	elapsed += delta

	var ratio := elapsed / maxf(definition.patience_seconds, 0.01)
	var next_hearts := clampi(HEARTS - int(ratio * HEARTS), 0, HEARTS)
	if next_hearts != hearts:
		hearts = next_hearts
		patience_changed.emit(hearts)

	if elapsed >= definition.patience_seconds:
		_close(false)


func _process(delta: float) -> void:
	tick(delta)


func _close(satisfied: bool) -> void:
	if closed:
		return
	closed = true
	seated = false
	set_process(false)
	if satisfied:
		finished.emit(true)
	else:
		left_angry.emit()


func _apply_texture() -> void:
	if definition == null or _sprite == null:
		return
	var seats := 4 if definition.seats >= 4 else 2
	# New table art uses "2 table.png" / "4 table.png"; keep the old
	# table_N.png as a fallback so a rename can't break the scene.
	var path := "res://assets/sprites/restaurant/%d table.png" % seats
	if not ResourceLoader.exists(path):
		path = "res://assets/sprites/restaurant/table_%d.png" % seats
	if ResourceLoader.exists(path):
		_sprite.texture = load(path)


func _refresh_visual() -> void:
	if _info == null or definition == null:
		return
	if closed:
		_info.text = "closed"
		_info.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		return
	var hearts_text := ""
	for i in HEARTS:
		hearts_text += "♥" if i < hearts else "·"
	_info.add_theme_color_override("font_color", UI.tag_color(definition.preference))
	_info.text = "%s  %s\n%d/%d plates" % [
		definition.preference, hearts_text, plates_served, definition.plates_wanted
	]


func debug_state() -> String:
	return "table=%s seated=%s hearts=%d plates=%d/%d elapsed=%.1f" % [
		definition.id if definition != null else "?",
		str(seated), hearts, plates_served,
		definition.plates_wanted if definition != null else 0, elapsed,
	]
