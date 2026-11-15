extends Control
## ============================================================================
## FISHING — tiered reel bar + CS:GO-style crate.
##
## Bar: four zones. The closer the marker stops to the centre, the better the
## fish (8/6/4/3 slices) AND the better the loot roll (higher-priced species,
## more rare chance). Centre is the jackpot.
##
## Crate: a horizontal strip of nigiri tiles scrolls left under a fixed centre
## marker. Each tile is framed in its rarity colour; the name of the tile under
## the marker is printed below the strip while it scrolls, then locks on the
## result. Species without art use the filler tile.
## ============================================================================

enum State { IDLE, REEL, REVEAL }

const BAR_X := 330.0
const BAR_Y := 470.0
const BAR_W := 620.0
const MARKER_W := 8.0
const VIEW_W := 700.0
const TILE_W := 84.0
const TILE_H := 132.0
const TILE_SEP := 8.0
const PITCH := TILE_W + TILE_SEP
const TILE_COUNT := 40
const WIN_INDEX := 34
const FILLER := "res://assets/sprites/ui/crate_frame.png"

@onready var _title: Label = $Title
@onready var _caught: Label = $CaughtLabel
@onready var _stock: Label = $StockLabel
@onready var _strip: HBoxContainer = $ReelViewport/Strip
@onready var _result: Label = $ResultName
@onready var _rare: Label = $RareLabel
@onready var _bar_marker: ColorRect = $BarMarker
@onready var _status: Label = $StatusLabel
@onready var _cast_btn: Button = $CastButton
@onready var _next_btn: Button = $NextButton
@onready var _fisher: AnimatedSprite2D = $Fisher

var _state: State = State.IDLE
var _casts_left := 0
var _reel_t := 0.0
var _pending_size := 3
var _pending_species: SpeciesDef = null
var _pending_mod: ModifierDef = null

var _pool: Array[SpeciesDef] = []
var _mods: Array[ModifierDef] = []
var _tile_species: Array[SpeciesDef] = []
var _filler: Texture2D
var _reel_tween: Tween


func _ready() -> void:
	_filler = load(FILLER)
	_load_content()
	_casts_left = clampi(3 + RunState.day, 5, 8)
	_title.text = "Fishing — %s" % RunState.weather_name(RunState.weather)
	_bar_marker.position.x = BAR_X + (BAR_W - MARKER_W) * 0.5

	UI.style_button(_cast_btn)
	UI.style_button(_next_btn)
	_cast_btn.pressed.connect(_on_cast)
	_next_btn.pressed.connect(func(): RunState.advance_phase())

	# Idle eye-candy: a strip already sitting there.
	_build_strip(null)
	_update_counts()


func _load_content() -> void:
	_pool.clear()
	for f in DirAccess.get_files_at("res://data/species"):
		if not f.ends_with(".tres"):
			continue
		var s := load("res://data/species/" + f) as SpeciesDef
		if s == null:
			continue
		if s.rain_only and RunState.weather != 2:
			continue
		_pool.append(s)

	for f in DirAccess.get_files_at("res://data/modifiers"):
		if f.ends_with(".tres"):
			var m := load("res://data/modifiers/" + f) as ModifierDef
			if m != null:
				_mods.append(m)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("p1_interact"):
		_on_cast()
		get_viewport().set_input_as_handled()


func _on_cast() -> void:
	if _state == State.REEL:
		_stop_reel()
	elif _state == State.IDLE and _casts_left > 0:
		_state = State.REEL
		_reel_t = 0.0
		_cast_btn.disabled = true
		_caught.text = "Stop the marker in the centre."
		_rare.text = ""
		_result.text = ""
		_fisher.play("fishing initiate")


## Stop position -> size tier and loot quality (0..1).
## Centre (<=35 px) = 8 slices + best odds; outer = 3 slices + worst.
func _stop_reel() -> void:
	var p := 0.5 + 0.5 * sin(_reel_t)
	var dist := absf(p - 0.5) * BAR_W
	var quality := 0.0
	if dist <= 35.0:
		_pending_size = 8
		quality = 1.0
	elif dist <= 110.0:
		_pending_size = 6
		quality = 0.7
	elif dist <= 210.0:
		_pending_size = 4
		quality = 0.4
	else:
		_pending_size = 3
		quality = 0.1

	_pending_species = _roll_species(quality)
	_pending_mod = null
	if RunState.rng.randf() < 0.04 + 0.11 * quality and not _mods.is_empty():
		_pending_mod = _mods[RunState.rng.randi_range(0, _mods.size() - 1)]

	_state = State.REVEAL
	_fisher.play("fishing bite")
	await _run_reel()
	_settle_catch()


## Bias the species roll toward expensive fish as quality rises.
func _roll_species(quality: float) -> SpeciesDef:
	var picks: Array[SpeciesDef] = []
	var n := 2 + int(round(quality * 2.0))
	for i in n:
		picks.append(_pool[RunState.rng.randi_range(0, _pool.size() - 1)])
	picks.sort_custom(func(a, b): return a.base_price > b.base_price)
	var idx := int(round((1.0 - quality) * float(picks.size() - 1)))
	return picks[clampi(idx, 0, picks.size() - 1)]


func _run_reel() -> void:
	_build_strip(_pending_species)
	_strip.position = Vector2.ZERO
	var target := VIEW_W * 0.5 - (WIN_INDEX * PITCH + TILE_W * 0.5)
	if _reel_tween != null and _reel_tween.is_valid():
		_reel_tween.kill()
	_reel_tween = create_tween()
	_reel_tween.tween_property(_strip, "position:x", target, 1.8) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await _reel_tween.finished
	_strip.position.x = target


func _build_strip(winner: SpeciesDef) -> void:
	for child in _strip.get_children():
		child.free()
	_tile_species.clear()
	for i in TILE_COUNT:
		var sp: SpeciesDef = winner if (i == WIN_INDEX and winner != null) else _pool[RunState.rng.randi_range(0, _pool.size() - 1)]
		_strip.add_child(_make_tile(sp))
		_tile_species.append(sp)


func _make_tile(sp: SpeciesDef) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(TILE_W, TILE_H)

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.08, 0.11)
	sb.border_color = _rarity_color(sp.base_price)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", sb)

	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(col)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(56, 56)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.texture = sp.sprite if sp.sprite != null else _filler
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	col.add_child(icon)

	return panel


func _rarity_color(price: int) -> Color:
	if price >= 40:
		return Color(1.0, 0.78, 0.2)
	if price >= 28:
		return Color(0.72, 0.45, 1.0)
	if price >= 20:
		return Color(0.4, 0.65, 1.0)
	if price >= 15:
		return Color(0.4, 0.9, 0.5)
	return Color(0.6, 0.6, 0.65)


func _process(delta: float) -> void:
	match _state:
		State.REEL:
			_reel_t += delta * 3.1
			var p := 0.5 + 0.5 * sin(_reel_t)
			_bar_marker.position.x = BAR_X + p * (BAR_W - MARKER_W)
		State.REVEAL:
			_update_reel_name()


## Name of whichever tile currently sits under the centre marker.
func _update_reel_name() -> void:
	if _tile_species.is_empty():
		return
	var idx := int(floor((VIEW_W * 0.5 - _strip.position.x) / PITCH))
	idx = clampi(idx, 0, _tile_species.size() - 1)
	var sp := _tile_species[idx]
	_result.text = sp.display_name
	_result.add_theme_color_override("font_color", _rarity_color(sp.base_price))


func _settle_catch() -> void:
	var fish := FishInstance.new(_pending_species, _pending_size, _pending_mod)
	RunState.add_to_stock(fish)
	_casts_left -= 1
	_state = State.IDLE
	_cast_btn.disabled = _casts_left <= 0
	_next_btn.disabled = _casts_left > 0
	_fisher.play("fishing idle")

	_result.text = _pending_species.display_name
	_result.add_theme_color_override("font_color", _rarity_color(_pending_species.base_price))
	_rare.text = ("RARE: %s" % _pending_mod.display_name) if _pending_mod != null else ""
	_caught.text = "Caught %s — %d slices, $%d per plate" % [
		_pending_species.display_name, _pending_size, fish.value()
	]
	_update_counts()


func _update_counts() -> void:
	_stock.text = "Casts left: %d   ·   stock: %d fish   ·   freezer: %d/%d" % [
		_casts_left, RunState.stock.size(), RunState.freezer.size(), RunState.freezer_capacity
	]
	_status.text = "Casts left: %d" % _casts_left
