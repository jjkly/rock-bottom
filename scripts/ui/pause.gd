extends CanvasLayer
## ============================================================================
## Pause menu — ESC during a run. Pauses the tree; settings opens on top.
## ============================================================================

signal main_menu_requested

const SETTINGS_SCENE := preload("res://scenes/settings.tscn")

@onready var _resume: Button = $Root/Panel/ResumeButton
@onready var _settings_btn: Button = $Root/Panel/SettingsButton
@onready var _menu_btn: Button = $Root/Panel/MenuButton

var _settings: Control


func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	UI.style_button(_resume)
	UI.style_button(_settings_btn)
	UI.style_button(_menu_btn)
	_resume.pressed.connect(_close)
	_settings_btn.pressed.connect(func(): _settings.open())
	_menu_btn.pressed.connect(_to_menu)
	_settings = SETTINGS_SCENE.instantiate()
	add_child(_settings)


func open() -> void:
	visible = true
	get_tree().paused = true


func _close() -> void:
	visible = false
	get_tree().paused = false


func _to_menu() -> void:
	_close()
	main_menu_requested.emit()
