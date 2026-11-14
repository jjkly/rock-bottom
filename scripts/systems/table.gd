class_name Table
extends Node2D
## ============================================================================
## Table — one party during evening service. Contract for the service scene.
##
## The evening scene: spawn a Table node, call setup(definition), seat() when
## the party walks in, and pass it plates via serve_plate(). Everything else
## (patience, angry, finished) is handled here. Do NOT read patience from a
## scene; connect to patience_changed.
##
## WHAT THE SERVICE SCENE MUST DO
##   - one Table node per TableDef, parented under a Y-sorted container
##   - call tick(delta) from _process (or let this node's own _process do it)
##   - on left_angry: count it; every 2 angry tables = -1 table tomorrow
##   - on finished(true): nothing, the cash was already added by RunState
##
## THE FEEDBACK CONTRACT (do not remove)
##   patience_changed fires only when the heart count changes, so UI can
##   animate once instead of every frame. Three hearts is the ceil: more is
##   unreadable at 32px.
## ============================================================================

signal served(plate_value: int, matched: bool)
signal left_angry
signal finished(satisfied: bool)
signal patience_changed(hearts: int)

const HEARTS := 3

var definition: TableDef
var seated := false
var closed := false
var elapsed := 0.0
var plates_served := 0
var hearts := HEARTS


## Call before seat(). The evening scene owns the TableDef resource.
func setup(p_definition: TableDef) -> void:
	definition = p_definition


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
	# Money is RunState's job (it already applied the +20% match); the table
	# only records satisfaction. Never multiply here again.
	served.emit(plate_value, matched)
	plates_served += 1
	if plates_served >= definition.plates_wanted:
		_close(true)


## Driven by _process in the real scene; tests call it directly with a delta.
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


func debug_state() -> String:
	return "table=%s seated=%s hearts=%d plates=%d/%d elapsed=%.1f" % [
		definition.id if definition != null else "?",
		str(seated), hearts, plates_served,
		definition.plates_wanted if definition != null else 0, elapsed,
	]
