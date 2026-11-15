extends Node
## ============================================================================
## smoke_flow.gd — runtime smoke test for the whole playable loop.
##
##   godot --headless --path . res://tests/smoke_flow.tscn
##
## Drives real scenes in a live tree: morning -> fishing (cast + settle) ->
## evening (cut + serve) -> shop (pay + sleep) -> results (force week end).
## It calls underscore methods on purpose: this is a smoke test, not a unit
## test. Any SCRIPT ERROR in the output is a failure even if the exit is 0.
## ============================================================================

var _failed := false


func _ready() -> void:
	var main := preload("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _frames(3)
	_expect("Morning")

	# --- fishing: one perfect cast -----------------------------------------
	RunState.advance_phase()
	await _frames(3)
	_expect("Fishing")
	var fishing: Node = _phase()
	fishing._on_cast()
	fishing._reel_t = 0.0          # marker at centre -> 8 slices
	fishing._stop_reel()
	await get_tree().create_timer(2.2).timeout   # reel scroll + settle
	if RunState.stock.size() != 1:
		_fail("cast did not add a fish to stock")
	elif RunState.stock[0].size_slices != 8:
		_fail("perfect stop did not produce 8 slices")
	else:
		print("  ok   cast: %s" % RunState.stock[0].display_name())

	# --- evening: cut and serve one plate ----------------------------------
	RunState.advance_phase()
	await _frames(3)
	_expect("Evening")
	await get_tree().create_timer(1.0).timeout   # first table has spawned
	var evening: Node = _phase()
	if evening._tables.is_empty():
		_fail("no table spawned during service")
	else:
		var p1: Player = evening._player
		var fish: FishInstance = RunState.stock[0]
		p1.position = evening._board_pos
		evening._on_interact()
		if p1.carrying == null:
			_fail("taking a plate did not fill the player's hands")
		elif not fish.prepared:
			_fail("taking a plate did not prepare the fish")
		var table = evening._tables[0]
		p1.position = table.position
		var before := RunState.cash
		evening._on_interact()
		if RunState.cash <= before:
			_fail("serving did not pay")
		elif table.plates_served < 1:
			_fail("table did not record the plate")
		elif p1.carrying != null:
			_fail("hands not cleared after serving")
		else:
			print("  ok   served $%d, table %d/%d" % [
				RunState.cash - before, table.plates_served, table.definition.plates_wanted
			])

	# --- shop: pay the minimum and sleep into day 2 -------------------------
	RunState.advance_phase()
	await _frames(3)
	_expect("Shop")
	RunState.earn(500)
	if not RunState.pay_minimum():
		_fail("could not pay the day minimum")
	if not RunState.end_day():
		_fail("end_day refused after paying")
	await _frames(3)
	_expect("Morning")
	if RunState.day != 2:
		_fail("expected day 2, got %d" % RunState.day)

	# --- results: force the week's end --------------------------------------
	RunState.day = 7
	RunState.phase = 3  # NIGHT
	RunState.minimum_paid_today = true
	RunState.end_day()
	await _frames(3)
	_expect("Results")

	if _failed:
		print("SMOKE FAIL")
		get_tree().quit(1)
	else:
		print("SMOKE PASS — day %d, cash %d, debt %d" % [RunState.day, RunState.cash, RunState.debt])
		get_tree().quit(0)


func _phase() -> Node:
	return get_node("Main/PhaseHolder").get_child(0)


func _expect(scene_name: String) -> void:
	var holder := get_node_or_null("Main/PhaseHolder")
	if holder == null or holder.get_child_count() == 0:
		_fail("no phase scene for " + scene_name)
		return
	var actual: String = holder.get_child(0).name
	if not actual.to_lower().begins_with(scene_name.to_lower()):
		_fail("expected %s, found %s" % [scene_name, actual])
	else:
		print("  ok   phase: %s" % actual)


func _fail(msg: String) -> void:
	_failed = true
	printerr("  FAIL ", msg)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
