class_name Player
extends CharacterBody2D
## ============================================================================
## One of the two evening players. Movement, carry state and animation only.
##
## Input is chosen by `player_prefix` ("p1" or "p2"), so the same scene serves
## both: P1 = WASD/E, P2 = arrows/Enter (see project.godot [input]).
## The root emits interact_requested; the evening scene decides whether that
## means "cut/take a plate" or "serve", because it owns the stations.
##
## Art: 16px character at 3x. Animations: idle, walk, hold idle, hold walk.
## Carrying a plate switches to the hold animations. body_tint distinguishes P2.
## ============================================================================

signal interact_requested

const SPEED := 300.0

@export var player_prefix := "p1"
@export var body_tint := Color.WHITE

@onready var _anim: AnimatedSprite2D = $AnimatedSprite

## The fish this player is currently carrying a plate from (null = empty hands).
var carrying: FishInstance = null


func _ready() -> void:
	# Top-down: no floor, no walls; move_and_slide still resolves collisions.
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	_anim.modulate = body_tint


func set_carrying(fish: FishInstance) -> void:
	carrying = fish


func _physics_process(_delta: float) -> void:
	var dir := Input.get_vector(
		player_prefix + "_left", player_prefix + "_right",
		player_prefix + "_up", player_prefix + "_down"
	)
	velocity = dir * SPEED
	move_and_slide()

	var moving := dir.length() > 0.01
	var next := "idle"
	if carrying != null:
		next = "hold walk" if moving else "hold idle"
	elif moving:
		next = "walk"
	if _anim.animation != next:
		_anim.play(next)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(player_prefix + "_interact"):
		interact_requested.emit()
		get_viewport().set_input_as_handled()
