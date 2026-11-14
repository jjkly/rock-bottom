class_name Player
extends CharacterBody2D
## ============================================================================
## The player during evening service. Movement only.
##
## Built entirely in code so the scene file stays trivial and merge-safe.
## Sprite direction swaps on the dominant axis; left is the side frame flipped.
## Carrying plates is handled by the evening scene (selection + serve), not here.
## ============================================================================

const SPEED := 215.0

var _sprite: Sprite2D
var _tex := {}


func _ready() -> void:
	collision_layer = 2
	collision_mask = 0  # tables are walk-through; only world geometry blocks

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(18, 12)
	shape.shape = rect
	shape.position = Vector2(0, 18)
	add_child(shape)

	for dir in ["down", "up", "side"]:
		_tex[dir] = load("res://assets/sprites/characters/player_%s_0.png" % dir)
	_sprite = Sprite2D.new()
	_sprite.texture = _tex["down"]
	_sprite.position = Vector2(0, -22)
	add_child(_sprite)


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
