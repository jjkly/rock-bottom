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
@onready var _hud_day: Label = $HUD/Row/DayLabel
@onready var _hud_money: Label = $HUD/Row/MoneyLabel
@onready var _hud_weather: Label = $HUD/Row/WeatherLabel

var _current: Node
var _shown := -1  # -2 = results, -1 = nothing yet, else RunState.Phase


func _ready() -> void:
	RunState.phase_changed.connect(func(_a, to): _show_phase.call_deferred(to))
	RunState.day_started.connect(func(_d): _show_phase.call_deferred(RunState.phase))
	RunState.run_ended.connect(func(_r, _d): _show_results.call_deferred())
	RunState.cash_changed.connect(func(_v): _refresh_hud())
	RunState.debt_changed.connect(func(_v): _refresh_hud())
	RunState.weather_changed.connect(func(_w): _refresh_hud())

	RunState.start_run()  # emits day_started; the deferred call shows MORNING
	_refresh_hud()


func _refresh_hud() -> void:
	if _hud_day == null:
		return
	_hud_day.text = "Day %d/7  ·  due $%d" % [RunState.day, RunState.minimum_today()]
	_hud_money.text = "$%d  ·  debt $%d" % [RunState.cash, RunState.debt]
	_hud_weather.text = RunState.weather_name(RunState.weather)


func _show_phase(phase: int) -> void:
	if phase == _shown:
		return
	_shown = phase
	_clear_current()

	var packed: PackedScene
	match phase:
		0: packed = preload("res://scenes/morning.tscn")
		1: packed = preload("res://scenes/fishing.tscn")
		2: packed = preload("res://scenes/evening.tscn")
		3: packed = preload("res://scenes/shop.tscn")
		_:
			return
	_current = packed.instantiate()
	_holder.add_child(_current)


func _show_results() -> void:
	if _shown == -2:
		return
	_shown = -2
	_clear_current()
	_current = preload("res://scenes/results.tscn").instantiate()
	_holder.add_child(_current)


func _clear_current() -> void:
	if is_instance_valid(_current):
		_current.queue_free()
	_current = null
