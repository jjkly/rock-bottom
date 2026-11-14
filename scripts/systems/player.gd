class_name Player
extends CharacterBody2D
## ============================================================================
## The player during evening service. Movement only.
##
## The node tree lives in scenes/player.tscn (Sprite + CollisionShape2D), so
## the sprite can be swapped in the editor. Left is the side frame flipped.
## Carrying plates is the evening scene's job, not this one.
## ============================================================================

const SPEED := 215.0

@onready var _sprite: Sprite2D = $Sprite
var _tex := {}


func _ready() -> void:
	for dir in ["down", "up", "side"]:
		_tex[dir] = load("res://assets/sprites/characters/player_%s_0.png" % dir)


func _physics_process(_delta: float) -> void:
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = dir * SPEED
	move_and_slide()

	if dir.length() > 0.01:
		if absf(dir.x) > absf(dir.y):
			_sprite.texture = _tex["side"]
			_sprite.flip_h = dir.x < 0.0
		else:
			_sprite.texture = _tex["up"] if dir.y < 0.0 else _tex["down"]
			_sprite.flip_h = false
