extends Node
## ============================================================================
## game.gd — DEV HARNESS ONLY. Delete when real scenes exist.
##
## It exists so the team can open the project, press Play, and see the week
## move: Enter advances the phase, and at NIGHT it pays the minimum then ends
## the day. The label is a debug readout, not UI.
##
## WHAT TO BUILD INSTEAD
##   scenes/morning.tscn  -> news + weather, calls RunState.advance_phase()
##   scenes/fishing.tscn  -> reel bar + crate, calls RunState.add_to_stock()
##   scenes/evening.tscn  -> Overcooked service, calls RunState.serve_plate()
##   scenes/shop.tscn     -> pay_minimum() + upgrade_gear() + end_day()
## The phase transition lives in RunState; scenes never change phase vars.
## ============================================================================

var _label: Label


func _ready() -> void:
	RunState.start_run()
	_build_hud()

	# Every state change refreshes the readout. Real UI should subscribe the
	# same way instead of polling.
	RunState.cash_changed.connect(func(_v): _refresh())
	RunState.debt_changed.connect(func(_v): _refresh())
	RunState.stock_changed.connect(_refresh)
	RunState.freezer_changed.connect(_refresh)
	RunState.gear_changed.connect(func(_s, _t): _refresh())
	RunState.phase_changed.connect(func(_a, _b): _refresh())
	RunState.day_started.connect(func(_d): _refresh())
	RunState.weather_changed.connect(func(_w): _refresh())
	RunState.quota_paid.connect(func(_d, _a): _refresh())
	RunState.quota_missed.connect(func(_d): _refresh())
	RunState.run_ended.connect(func(_r, _d): _refresh())

	_refresh()
	print("[dev] run started — ", RunState.debug_state())


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_label = Label.new()
	_label.position = Vector2(16, 16)
	_label.add_theme_font_size_override("font_size", 18)
	layer.add_child(_label)
	var help := Label.new()
	help.position = Vector2(16, 48)
	help.text = "ENTER: next phase  |  at NIGHT: pay minimum, then end day"
	help.add_theme_font_size_override("font_size", 12)
	layer.add_child(help)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_accept"):
		return
	_dev_advance()


func _dev_advance() -> void:
	if RunState.run_over:
		RunState.start_run()
		return
	if RunState.phase == RunState.Phase.NIGHT:
		if not RunState.minimum_paid_today:
			if not RunState.pay_minimum():
				print("[dev] cannot pay minimum: need %d, have %d" % [
					RunState.minimum_today(), RunState.cash
				])
				RunState.earn(RunState.minimum_today())
				RunState.pay_minimum()
		else:
			RunState.end_day()
	else:
		RunState.advance_phase()


func _refresh() -> void:
	if _label != null:
		_label.text = RunState.debug_state()
