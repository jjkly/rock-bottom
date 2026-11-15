extends Node
## ============================================================================
## main.gd — phase router + permanent HUD.
##
## The HUD nodes live in scenes/main.tscn; this script only fills them.
## One phase scene is alive at a time:
##   MORNING -> morning.tscn   FISHING -> fishing.tscn
##   EVENING -> evening.tscn   NIGHT   -> shop.tscn
##   run_ended -> results.tscn
##
## The phase itself is owned by RunState. Scenes call advance_phase() /
## end_day(); this router only reacts to signals.
## ============================================================================

@onready var _holder: Node = $PhaseHolder
@onready var _hud: CanvasLayer = $HUD
@onready var _hud_day: Label = $HUD/Row/DayLabel
@onready var _hud_money: Label = $HUD/Row/MoneyLabel
@onready var _hud_weather: Label = $HUD/Row/WeatherLabel
@onready var _help_btn: Button = $HUD/HelpButton

const TUTORIAL_SCENE := preload("res://scenes/tutorial.tscn")
const MENU_SCENE := preload("res://scenes/menu.tscn")
const PAUSE_SCENE := preload("res://scenes/pause.tscn")

var _current: Node
var _tutorial: CanvasLayer
var _menu: Control
var _pause: CanvasLayer
var _current_phase := -1
var _seen := {}
var _headless := false
var _shown := -1  # -2 = results, -1 = nothing yet, else RunState.Phase


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_headless = DisplayServer.get_name() == "headless"
	_tutorial = TUTORIAL_SCENE.instantiate()
	add_child(_tutorial)
	_help_btn.pressed.connect(func(): _tutorial.open(clampi(RunState.phase, 0, 3)))

	_menu = MENU_SCENE.instantiate()
	add_child(_menu)
	_menu.start_requested.connect(_start_game)

	_pause = PAUSE_SCENE.instantiate()
	add_child(_pause)
	_pause.main_menu_requested.connect(_return_to_menu)

	_hud.visible = false

	RunState.day_started.connect(func(d): if d == 1: _seen.clear())
	RunState.phase_changed.connect(func(_a, to): _show_phase.call_deferred(to))
	RunState.day_started.connect(func(_d): _show_phase.call_deferred(RunState.phase))
	RunState.run_ended.connect(func(_r, _d): _show_results.call_deferred())
	RunState.cash_changed.connect(func(_v): _refresh_hud())
	RunState.debt_changed.connect(func(_v): _refresh_hud())
	RunState.weather_changed.connect(func(_w): _refresh_hud())

	_refresh_hud()


func _start_game(difficulty: int) -> void:
	_menu.visible = false
	_hud.visible = true
	RunState.set_difficulty(difficulty)
	RunState.start_run()


func _return_to_menu() -> void:
	get_tree().paused = false
	_pause.visible = false
	_shown = -1
	_current_phase = -1
	_clear_current()
	_hud.visible = false
	_menu.visible = true


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if _menu.visible:
		return
	if _tutorial != null and _tutorial._root.visible:
		return
	if _pause.visible:
		_pause._close()
	else:
		_pause.open()
	get_viewport().set_input_as_handled()


func _refresh_hud() -> void:
	if _hud_day == null:
		return
	_hud_day.text = "Day %d/7  ·  due $%d" % [RunState.day, RunState.installment_today()]
	_hud_money.text = "$%d  ·  debt $%d" % [RunState.cash, RunState.debt]
	_hud_weather.text = RunState.weather_name(RunState.weather)


func _show_phase(phase: int) -> void:
	if phase == _shown:
		return
	_shown = phase
	_hud.visible = true
	_clear_current()

	var packed: PackedScene
	match phase:
		0: packed = preload("res://scenes/morning.tscn")
		1: packed = preload("res://scenes/fishing.tscn")
		2: packed = preload("res://scenes/evening.tscn")
		3: packed = preload("res://scenes/shop.tscn")
		_:
			return
	_menu.visible = false
	_current = packed.instantiate()
	_holder.add_child(_current)
	_current_phase = phase
	# Day 1: explain each phase once. Headless tests/smoke would stall on the
	# pause, so they skip it.
	if not _headless and RunState.day == 1 and not _seen.has(phase):
		_seen[phase] = true
		_tutorial.open(phase)


func _show_results() -> void:
	if _shown == -2:
		return
	_shown = -2
	_current_phase = -1
	_hud.visible = false
	_clear_current()
	_current = preload("res://scenes/results.tscn").instantiate()
	_holder.add_child(_current)
	_current.main_menu_requested.connect(_return_to_menu)


func _clear_current() -> void:
	if is_instance_valid(_current):
		_current.queue_free()
	_current = null
