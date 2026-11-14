extends Control
## ============================================================================
## FISHING — the reel bar, then the crate. Nodes live in scenes/fishing.tscn.
##
## Space / E to cast, Space / E again to stop the marker. The stop position
## decides the fish size (3/4/6/8 slices), the crate decides the species and
## rolls the ~8% rare slot. Odds stay hidden; the bestiary is the reveal.
## ============================================================================

enum State { IDLE, REEL, REVEAL }

const BAR_X := 330.0
const BAR_Y := 430.0
const BAR_W := 620.0
const MARKER_W := 8.0
const ZONE_W := 150.0

@onready var _title: Label = $Title
@onready var _caught: Label = $CaughtLabel
@onready var _stock: Label = $StockLabel
@onready var _slot_a: Label = $SlotA
@onready var _slot_b: Label = $SlotB
@onready var _slot_c: Label = $SlotC
@onready var _rare: Label = $RareLabel
@onready var _marker: ColorRect = $Marker
@onready var _status: Label = $StatusLabel
@onready var _cast_btn: Button = $CastButton
@onready var _next_btn: Button = $NextButton

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


func _ready() -> void:
	_load_content()
	_casts_left = clampi(3 + RunState.day, 5, 8)

	_title.text = "Fishing — %s" % RunState.weather_name(RunState.weather)
	_marker.position.x = BAR_X + (BAR_W - MARKER_W) * 0.5

	UI.style_button(_cast_btn)
	UI.style_button(_next_btn)
	_cast_btn.pressed.connect(_on_cast)
	_next_btn.pressed.connect(func(): RunState.advance_phase())
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
	_update_counts()


func _update_counts() -> void:
	_stock.text = "Casts left: %d   ·   stock: %d fish   ·   freezer: %d/%d" % [
		_casts_left, RunState.stock.size(), RunState.freezer.size(), RunState.freezer_capacity
	]
	_status.text = "Casts left: %d" % _casts_left
