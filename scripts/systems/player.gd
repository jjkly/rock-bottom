class_name Player
extends CharacterBody2D
## ============================================================================
## The player during evening service. Movement + animation state only.
##
## Art: 16px character drawn at 1x, displayed at 2x (32px tall) so it sits on
## the 32px tile grid. Animations come from player_frames.tres, sliced from
## emma's sheets by tools/build_character.py:
##   idle (7) · walk (4) · hold idle (7) · hold walk (4)
## The art is front-facing; there are no directional frames.
##
## Carrying is not wired into service yet. When it is, call set_holding(true)
## while the player holds a plate and the hold animations take over.
## ============================================================================

const SPEED := 215.0

@onready var _anim: AnimatedSprite2D = $AnimatedSprite

var _holding := false


func set_holding(value: bool) -> void:
	_holding = value


func _physics_process(_delta: float) -> void:
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = dir * SPEED
	move_and_slide()

	var moving := dir.length() > 0.01
	var next := "idle"
	if _holding:
		next = "hold walk" if moving else "hold idle"
	elif moving:
		next = "walk"
	if _anim.animation != next:
		_anim.play(next)
