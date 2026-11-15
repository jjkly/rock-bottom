extends Node
## ============================================================================
## Settings — persisted user options (user://settings.cfg).
##
## Owns: skip fishing animations, music/SFX volume, fullscreen.
## Creates Music/SFX audio buses if missing so the volume sliders have targets
## before audio assets exist.
## ============================================================================

const PATH := "user://settings.cfg"

var skip_animations := false
var music_volume := 80
var sfx_volume := 80
var fullscreen := false


func _ready() -> void:
	_ensure_buses()
	load_settings()
	apply_all()


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	skip_animations = bool(cfg.get_value("game", "skip_animations", skip_animations))
	music_volume = int(cfg.get_value("audio", "music", music_volume))
	sfx_volume = int(cfg.get_value("audio", "sfx", sfx_volume))
	fullscreen = bool(cfg.get_value("video", "fullscreen", fullscreen))


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("game", "skip_animations", skip_animations)
	cfg.set_value("audio", "music", music_volume)
	cfg.set_value("audio", "sfx", sfx_volume)
	cfg.set_value("video", "fullscreen", fullscreen)
	cfg.save(PATH)


func apply_all() -> void:
	apply_bus_volumes()
	apply_fullscreen()


func apply_bus_volumes() -> void:
	_ensure_buses()
	_set_bus("Music", music_volume)
	_set_bus("SFX", sfx_volume)


func apply_fullscreen() -> void:
	if DisplayServer.get_name() == "headless":
		return
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	)


func set_skip_animations(value: bool) -> void:
	skip_animations = value
	save_settings()


func set_music_volume(value: int) -> void:
	music_volume = clampi(value, 0, 100)
	apply_bus_volumes()
	save_settings()


func set_sfx_volume(value: int) -> void:
	sfx_volume = clampi(value, 0, 100)
	apply_bus_volumes()
	save_settings()


func set_fullscreen(value: bool) -> void:
	fullscreen = value
	apply_fullscreen()
	save_settings()


func _ensure_buses() -> void:
	for bus_name in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)


func _set_bus(bus_name: String, volume: int) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(volume / 100.0, 0.0001)))
	AudioServer.set_bus_mute(idx, volume <= 0)
