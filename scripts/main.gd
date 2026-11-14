extends Node
## ============================================================================
## main.gd — phase router + permanent HUD.
##
## Replaces the old dev harness. One phase scene is alive at a time:
##   MORNING -> morning.tscn      (news, weather, start the day)
##   FISHING -> fishing.tscn      (reel bar + crate)
##   EVENING -> evening.tscn      (walk, cut, serve)
##   NIGHT   -> shop.tscn         (pay minimum, gear, sleep)
##   run_ended -> results.tscn     (score, restart)
##
## The phase itself is owned by RunState. Scenes call advance_phase() /
## end_day(); this router only reacts to signals. Never set RunState.phase here.
## ============================================================================

var _holder: Node
var _current: Node
var _shown := -1  # -2 = results, -1 = nothing yet, else RunState.Phase
var _hud_day: Label
var _hud_money: Label
var _hud_weather: Label


func _ready() -> void:
	_holder = Node.new()
	_holder.name = "PhaseHolder"
	add_child(_holder)
	_build_hud()

	RunState.phase_changed.connect(func(_a, to): _show_phase.call_deferred(to))
	RunState.day_started.connect(func(_d): _show_phase.call_deferred(RunState.phase))
	RunState.run_ended.connect(func(_r, _d): _show_results.call_deferred())
	RunState.cash_changed.connect(func(_v): _refresh_hud())
	RunState.debt_changed.connect(func(_v): _refresh_hud())
	RunState.weather_changed.connect(func(_w): _refresh_hud())

	RunState.start_run()  # emits day_started; the deferred call shows MORNING


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)

	var bar := UI.panel()
	bar.position = Vector2(12, 10)
	layer.add_child(bar)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 22)
	bar.add_child(row)

	_hud_day = UI.label("Day 1/7", 18)
	_hud_money = UI.label("$0", 18)
	_hud_weather = UI.label("CLEAR", 18, Color(0.7, 0.9, 1.0))
	row.add_child(_hud_day)
	row.add_child(_hud_money)
	row.add_child(_hud_weather)

	_refresh_hud()


func _refresh_hud() -> void:
	if _hud_day == null:
		return
	_hud_day.text = "Day %d/7" % RunState.day
	_hud_money.text = "$%d  ·  debt $%d" % [RunState.cash, RunState.debt]
	_hud_day.text += "  ·  due $%d" % RunState.minimum_today()
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
