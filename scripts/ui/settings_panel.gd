extends Control
## ============================================================================
## Settings panel — used by the main menu and the pause menu.
## Values persist through the Settings autoload (user://settings.cfg).
## ============================================================================

signal closed

@onready var _skip: CheckButton = $Panel/SkipCheck
@onready var _music: HSlider = $Panel/MusicSlider
@onready var _sfx: HSlider = $Panel/SfxSlider
@onready var _fullscreen: CheckButton = $Panel/FullscreenCheck
@onready var _back: Button = $Panel/BackButton
@onready var _music_value: Label = $Panel/MusicValue
@onready var _sfx_value: Label = $Panel/SfxValue


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	UI.style_button(_back)
	_skip.toggled.connect(func(v): Settings.set_skip_animations(v))
	_music.value_changed.connect(func(v):
		Settings.set_music_volume(int(v))
		_music_value.text = "%d" % int(v)
	)
	_sfx.value_changed.connect(func(v):
		Settings.set_sfx_volume(int(v))
		_sfx_value.text = "%d" % int(v)
	)
	_fullscreen.toggled.connect(func(v): Settings.set_fullscreen(v))
	_back.pressed.connect(_close)
	visible = false


func open() -> void:
	_skip.set_pressed_no_signal(Settings.skip_animations)
	_music.set_value_no_signal(Settings.music_volume)
	_sfx.set_value_no_signal(Settings.sfx_volume)
	_fullscreen.set_pressed_no_signal(Settings.fullscreen)
	_music_value.text = "%d" % Settings.music_volume
	_sfx_value.text = "%d" % Settings.sfx_volume
	visible = true


func _close() -> void:
	visible = false
	closed.emit()
