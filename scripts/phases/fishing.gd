extends Control
## ============================================================================
## FISHING — the reel bar, then the crate.
##
## Space / E to cast, Space / E again to stop the marker. The stop position
## decides the fish size (3/4/6/8 slices), the crate decides the species and
## rolls the ~8% rare slot. Odds are not shown: the bestiary is the reveal.
##
## Casts per day: 3 + day, capped at 8. When they run out, go to evening.
## ============================================================================

enum State { IDLE, REEL, REVEAL }

const BAR_X := 330.0
const BAR_Y := 430.0
const BAR_W := 620.0
const BAR_H := 34.0
const MARKER_W := 8.0
const ZONE_W := 150.0

var _state: State = State.IDLE
var _casts_left := 0
var _reel_t := 0.0
var _reveal_t := 0.0
var _reveal_tick := 0.0
var _pending_size := 3
var _pending_species: SpeciesDef = null
var _pending_mod: ModifierDef = null

var _pool: Array[SpeciesDef] = []
var _mods: Array[ModifierDef] = []

var _marker: ColorRect
var _status: Label
var _caught: Label
var _stock: Label
var _cast_btn: Button
var _next_btn: Button
var _slot_a: Label
var _slot_b: Label
var _slot_c: Label
var _rare: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(UI.backdrop(Color(0.03, 0.08, 0.12)))

	_load_content()
	_casts_left = clampi(3 + RunState.day, 5, 8)

	var title := UI.label("Fishing — %s" % RunState.weather_name(RunState.weather), 32)
	title.position = Vector2(80, 70)
	add_child(title)

	_caught = UI.label("Press SPACE to cast.", 22, Color(0.8, 0.85, 0.9))
	_caught.position = Vector2(80, 120)
	add_child(_caught)

	_stock = UI.label("", 18, Color(0.7, 0.75, 0.8))
	_stock.position = Vector2(80, 155)
	add_child(_stock)

	# Reel bar.
	var bar_bg := ColorRect.new()
	bar_bg.color = Color(0.12, 0.15, 0.2)
	bar_bg.position = Vector2(BAR_X, BAR_Y)
	bar_bg.size = Vector2(BAR_W, BAR_H)
	add_child(bar_bg)

	var zone := ColorRect.new()
	zone.color = Color(0.2, 0.55, 0.3, 0.65)
	zone.position = Vector2(BAR_X + BAR_W * 0.5 - ZONE_W * 0.5, BAR_Y)
	zone.size = Vector2(ZONE_W, BAR_H)
	add_child(zone)

	_marker = ColorRect.new()
	_marker.color = Color(1.0, 0.9, 0.4)
	_marker.size = Vector2(MARKER_W, BAR_H)
	# Idle marker sits at the centre of the zone, not at the bar's left edge.
	_marker.position = Vector2(BAR_X + (BAR_W - MARKER_W) * 0.5, BAR_Y)
	add_child(_marker)

	_status = UI.label("", 18, Color(0.75, 0.8, 0.85))
	_status.position = Vector2(BAR_X, BAR_Y + 50)
	add_child(_status)

	# Crate slots.
	var crate := UI.panel()
	crate.position = Vector2(330, 200)
	add_child(crate)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 26)
	crate.add_child(row)
	_slot_a = UI.label("???", 26, Color(0.85, 0.85, 0.9))
	_slot_b = UI.label("???", 26, Color(0.85, 0.85, 0.9))
	_slot_c = UI.label("???", 26, Color(0.85, 0.85, 0.9))
	row.add_child(_slot_a)
	row.add_child(_slot_b)
	row.add_child(_slot_c)

	_rare = UI.label("", 22, Color(1.0, 0.8, 0.3))
	_rare.position = Vector2(330, 265)
	add_child(_rare)

	_cast_btn = UI.button("Cast (SPACE)", 220, 22)
	_cast_btn.position = Vector2(80, 620)
	_cast_btn.pressed.connect(_on_cast)
	add_child(_cast_btn)

	_next_btn = UI.button("Go to evening", 240, 22)
	_next_btn.position = Vector2(960, 620)
	_next_btn.disabled = true
	_next_btn.pressed.connect(func(): RunState.advance_phase())
	add_child(_next_btn)

	_update_counts()


func _load_content() -> void:
	# Rain-only species join the pool only on a rain day (2 = RAIN).
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
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		_on_cast()
		get_viewport().set_input_as_handled()


func _on_cast() -> void:
	if _state == State.REEL:
		_stop_reel()
	elif _state == State.IDLE and _casts_left > 0:
		_state = State.REEL
		_reel_t = 0.0
		_cast_btn.disabled = true
		_caught.text = "Stop the marker in the green zone."
		_rare.text = ""


func _stop_reel() -> void:
	# Marker x in 0..1 across the bar; 0.5 is the centre of the green zone.
	var p := 0.5 + 0.5 * sin(_reel_t)
	var dist := absf(p - 0.5)
	if dist <= (ZONE_W / BAR_W) * 0.5:
		if dist < 0.03:
			_pending_size = 8
		elif dist < 0.07:
			_pending_size = 6
		else:
			_pending_size = 4
	else:
		_pending_size = 3  # still a fish, just a small one

	_pending_species = _pool[RunState.rng.randi_range(0, _pool.size() - 1)]
	_pending_mod = null
	if RunState.rng.randf() < 0.08 and not _mods.is_empty():
		_pending_mod = _mods[RunState.rng.randi_range(0, _mods.size() - 1)]

	_state = State.REVEAL
	_reveal_t = 0.0
	_reveal_tick = 0.0
	_caught.text = "Crate opening..."
	_status.text = ""


func _process(delta: float) -> void:
	match _state:
		State.REEL:
			_reel_t += delta * 3.1
			var p := 0.5 + 0.5 * sin(_reel_t)
			_marker.position.x = BAR_X + p * (BAR_W - MARKER_W)
		State.REVEAL:
			_reveal_t += delta
			_reveal_tick += delta
			if _reveal_tick >= 0.06:
				_reveal_tick = 0.0
				_slot_a.text = _rand_name()
				_slot_b.text = _rand_name()
				_slot_c.text = _rand_name()
			if _reveal_t >= 1.0:
				_settle_catch()


func _rand_name() -> String:
	return _pool[RunState.rng.randi_range(0, _pool.size() - 1)].display_name


func _settle_catch() -> void:
	var fish := FishInstance.new(_pending_species, _pending_size, _pending_mod)
	RunState.add_to_stock(fish)
	_casts_left -= 1
	_state = State.IDLE
	_cast_btn.disabled = _casts_left <= 0
	_next_btn.disabled = _casts_left > 0

	_slot_a.text = _pending_species.display_name
	_slot_b.text = "%d slices" % _pending_size
	_slot_c.text = "+1 plate" if _pending_mod != null and _pending_mod.extra_plates > 0 else "—"
	_rare.text = ("RARE: %s" % _pending_mod.display_name) if _pending_mod != null else ""
	_caught.text = "Caught %s — worth $%d per plate" % [fish.display_name(), fish.value()]
	_status.text = "Casts left: %d" % _casts_left
	_update_counts()


func _update_counts() -> void:
	_stock.text = "Casts left: %d   ·   stock: %d fish   ·   freezer: %d/%d" % [
		_casts_left, RunState.stock.size(), RunState.freezer.size(), RunState.freezer_capacity
	]
	if _status.text == "":
		_status.text = "Casts left: %d" % _casts_left
