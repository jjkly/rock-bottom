extends Node
## ============================================================================
## Audio — music tracks + one-shot SFX on the Music/SFX buses.
##
## Settings owns the bus volumes; this autoload only plays. Music loops by
## replaying on `finished`. Missing files are ignored so the game runs before
## every sound exists.
## ============================================================================

const TRACKS := {
	"main": "res://assets/audio/music/02_seaside_village (main theme).wav",
	"restaurant": "res://assets/audio/music/alex-morgan-restaurant-dinner-table-ambience-578503(restraunt theme).mp3",
}

const SFX := {
	"click": "res://assets/audio/sfx/213148__complex_waveform__click.wav",
	"spin": "res://assets/audio/sfx/244774__door15studio__spin-tick.mp3",
	"inventory": "res://assets/audio/sfx/580825__obrymec__inventory_combine.wav",
	"plate": "res://assets/audio/sfx/614246__meklips__iron_plates_flick.wav",
	"bell": "res://assets/audio/sfx/810323__mokasza__bright-bell.mp3",
	"knock": "res://assets/audio/sfx/847234__cpfcfan10__wooden-door-knock.wav",
}

const SFX_VOICES := 8

var _music: AudioStreamPlayer
var _music_key := ""
var _voices: Array[AudioStreamPlayer] = []


func _ready() -> void:
	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	add_child(_music)
	_music.finished.connect(_loop_music)
	for i in SFX_VOICES:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_voices.append(p)

	RunState.quota_paid.connect(func(_d, _a): play("bell"))
	RunState.quota_missed.connect(func(_d): play("knock"))


func play_music(key: String) -> void:
	if key == _music_key and _music.playing:
		return
	var path: String = TRACKS.get(key, "")
	if path.is_empty() or not ResourceLoader.exists(path):
		return
	_music.stream = load(path)
	_music_key = key
	_music.play()


func play(sfx_name: String) -> void:
	var path: String = SFX.get(sfx_name, "")
	if path.is_empty() or not ResourceLoader.exists(path):
		return
	for p in _voices:
		if not p.playing:
			p.stream = load(path)
			p.play()
			return


func _exit_tree() -> void:
	if _music != null:
		_music.stop()
		_music.stream = null


func _loop_music() -> void:
	if _music.stream != null:
		_music.play()
