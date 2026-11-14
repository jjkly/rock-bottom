class_name Station
extends Node2D
## ============================================================================
## Station — the seam between the service scene and the three minigames.
##
## The service loop only needs to know three things:
##   interact()  -> start a minigame (the player pressed E at this station)
##   plate_ready -> a prepared plate (FishInstance) is ready to carry
##   busy        -> the station is occupied, others must wait
##
## The minigame team owns everything inside _run_minigame(): cut, cook, wash.
## Keep the minigame as a child scene and emit plate_ready when it finishes,
## so the service scene never imports minigame code and this file stays small.
##
## SUGGESTED SPLIT (avoids Team Create conflicts)
##   cut  -> CuttingBoard scene, outputs 1-3 plates from one fish
##   cook -> Stove scene, consumes a plate and returns it cooked (+value)
##   wash -> Sink scene, end-of-day batch, removed by the dishwasher upgrade
##
## DO NOT put patience, cash or table logic in here. One station, one job.
## ============================================================================

signal minigame_started(minigame_id: String)
signal plate_ready(fish: FishInstance)
signal state_changed(new_state: int)

enum State { IDLE, BUSY }

## Which minigame scene to instantiate. Set in the scene inspector.
@export var minigame_id := "cut"
## Seconds a perfect run should take; the minigame may read this.
@export var base_duration := 3.0

var state: State = State.IDLE
## Fish currently being processed (null when idle).
var held_fish: FishInstance = null
## Result of the last minigame, 0..1. Kept for the per-plate quality bonus;
## do not mutate the fish's size here — plates_left is derived at construction.
var last_quality := 1.0


## Called by the player interaction Area2D when they press E next to it.
func interact() -> void:
	if state != State.IDLE:
		return
	_start_minigame()


## The minigame scene calls this when it finishes. quality 0..1 scales the
## plate value (+10% at perfect). Leave the math in one place: RunState/tests.
func complete(quality: float = 1.0) -> void:
	if state != State.BUSY:
		return
	state = State.IDLE
	state_changed.emit(state)
	last_quality = clampf(quality, 0.0, 1.0)
	if held_fish != null:
		# TODO(minigame owner): decide the quality payoff. Either scale the
		# plate value where it is served, or add a per-plate bonus field to
		# FishInstance. Do NOT rewrite size_slices — plates_left is derived.
		plate_ready.emit(held_fish)
	held_fish = null


func _start_minigame() -> void:
	state = State.BUSY
	state_changed.emit(state)
	minigame_started.emit(minigame_id)
	# TODO(minigame owner): instantiate the minigame scene here and await it.
	# The placeholder completes instantly so the service loop is testable.
	complete(1.0)


func debug_state() -> String:
	return "station=%s state=%s held=%s" % [
		minigame_id, State.keys()[state], held_fish.debug_state() if held_fish != null else "-"
	]
