extends Control
## ============================================================================
## Main menu — Rock Bottom.
##
## Play -> three difficulty cards (green / amber / red) with debt, installment,
## rare-odds and replay specifics. Settings opens the shared settings panel.
##
## Title: drop 7 sprites at assets/sprites/ui/title/1.png ... 7.png. They are
## laid out in a row and bob; indices 0 and 4 (R and B) are 25% larger. Without
## the files, a text title is shown instead.
## ============================================================================

signal start_requested(difficulty: int)

const SETTINGS_SCENE := preload("res://scenes/settings.tscn")
const TITLE_DIR := "res://assets/sprites/ui/title/"
const TITLE_COUNT := 7

@onready var _title_label: Label = $TitleLabel
@onready var _title_root: Node2D = $TitleRoot
@onready var _play: Button = $PlayButton
@onready var _settings_btn: Button = $SettingsButton
@onready var _difficulty_panel: Control = $DifficultyPanel
@onready var _cards: Control = $DifficultyPanel/Cards
@onready var _back: Button = $DifficultyPanel/BackButton
@onready var _tagline: Label = $Tagline

var _settings: Control
var _sprites: Array[Sprite2D] = []
var _t := 0.0


func _ready() -> void:
	UI.style_button(_play)
	UI.style_button(_settings_btn)
	_play.pressed.connect(_open_difficulty)
	_back.pressed.connect(_close_difficulty)
	_settings_btn.pressed.connect(_open_settings)

	_settings = SETTINGS_SCENE.instantiate()
	add_child(_settings)

	_build_cards()
	_build_title()
	_difficulty_panel.visible = false


func _process(delta: float) -> void:
	_t += delta
	for i in _sprites.size():
		_sprites[i].position.y = sin(_t * 2.2 + i * 0.55) * 6.0
	if not _sprites.is_empty():
		return
	if _title_label.visible:
		_title_label.scale = Vector2.ONE * (1.0 + sin(_t * 1.6) * 0.012)


func _build_title() -> void:
	var textures: Array[Texture2D] = []
	for i in range(1, TITLE_COUNT + 1):
		var path := TITLE_DIR + "%d.png" % i
		if ResourceLoader.exists(path):
			textures.append(load(path))
	if textures.size() != TITLE_COUNT:
		return
	_title_label.visible = false
	var total := 0.0
	var heights: Array[float] = []
	for i in textures.size():
		var h := 96.0 if i != 0 and i != 4 else 120.0
		heights.append(h)
		total += h * textures[i].get_width() / textures[i].get_height()
	var x := -total * 0.5
	for i in textures.size():
		var s := Sprite2D.new()
		s.texture = textures[i]
		var h := heights[i]
		s.scale = Vector2.ONE * (h / textures[i].get_height())
		s.position = Vector2(x + h * textures[i].get_width() / textures[i].get_height() * 0.5, 0)
		x += h * textures[i].get_width() / textures[i].get_height()
		_title_root.add_child(s)
		_sprites.append(s)


func _build_cards() -> void:
	var rows := [
		{"name": "Easy", "color": Color(0.35, 0.9, 0.5), "rec": "Recommended for beginners"},
		{"name": "Medium", "color": Color(1.0, 0.78, 0.3), "rec": "Recommended if you know the game"},
		{"name": "Hard", "color": Color(0.95, 0.35, 0.35), "rec": "Recommended for a challenge"},
	]
	for d in rows.size():
		var panel := PanelContainer.new()
		panel.position = Vector2(70 + d * 380, 40)
		panel.custom_minimum_size = Vector2(350, 330)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.07, 0.08, 0.11, 0.97)
		sb.border_color = rows[d]["color"]
		sb.set_border_width_all(4)
		sb.set_corner_radius_all(6)
		sb.content_margin_left = 18
		sb.content_margin_right = 18
		sb.content_margin_top = 16
		sb.content_margin_bottom = 16
		panel.add_theme_stylebox_override("panel", sb)

		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 10)
		panel.add_child(box)
		box.add_child(UI.label(rows[d]["name"], 30, rows[d]["color"]))
		box.add_child(UI.label(rows[d]["rec"], 15, Color(0.8, 0.85, 0.9)))
		box.add_child(UI.label(_details(d), 16, Color(0.85, 0.85, 0.85)))
		var pick := UI.button("Choose", 200, 18)
		pick.pressed.connect(func(): start_requested.emit(d))
		box.add_child(pick)
		_cards.add_child(panel)


func _details(d: int) -> String:
	var debt := int(RunState.DIFFICULTY_DEBT[d])
	var mult := float(RunState.DIFFICULTY_MULT[d])
	var rare := float(RunState.DIFFICULTY_RARE[d])
	var replays := int(RunState.DIFFICULTY_REPLAYS[d])
	var rare_text := "baseline"
	if rare > 1.0:
		rare_text = "+%d%%" % int(round((rare - 1.0) * 100.0))
	elif rare < 1.0:
		rare_text = "%d%%" % int(round((rare - 1.0) * 100.0))
	var replay_text := "unlimited" if replays < 0 else ("none" if replays == 0 else str(replays))
	return "Debt: $%d\nInstallments: ×%.1f\nRare fish odds: %s\nReplays: %s" % [
		debt, mult, rare_text, replay_text
	]


func _open_difficulty() -> void:
	_set_menu_visible(false)
	_difficulty_panel.visible = true


func _close_difficulty() -> void:
	_difficulty_panel.visible = false
	_set_menu_visible(true)


func _set_menu_visible(value: bool) -> void:
	_title_label.visible = value and _sprites.is_empty()
	_title_root.visible = value and not _sprites.is_empty()
	_tagline.visible = value
	_play.visible = value
	_settings_btn.visible = value


func _open_settings() -> void:
	_settings.open()
