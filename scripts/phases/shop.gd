extends Control
## ============================================================================
## NIGHT — pay the minimum, then spend what is left.
##
## Two tabs on one screen: durable gear (data/gear/*.tres) and a 3-of-N
## training offer (Luck / Fishing / Speed). Luck can discount an offer — that
## is the only thing luck does here; odds stay out of the shop.
##
## Sleep calls end_day(). If the minimum is unpaid, RunState ends the run and
## the router swaps to the results screen.
## ============================================================================

var _gear: Array[GearDef] = []
var _rows: Array[Dictionary] = []
var _offers: Array[Dictionary] = []
var _cash_label: Label
var _due_label: Label
var _msg: Label
var _pay_btn: Button
var _sleep_btn: Button
var _train_box: VBoxContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(UI.backdrop(Color(0.05, 0.05, 0.07)))
	_load_gear()

	var title := UI.label("Night — the ledger", 34)
	title.position = Vector2(80, 70)
	add_child(title)

	_cash_label = UI.label("", 24, Color(0.9, 0.9, 0.85))
	_cash_label.position = Vector2(80, 125)
	add_child(_cash_label)

	_due_label = UI.label("", 22, Color(1.0, 0.8, 0.5))
	_due_label.position = Vector2(80, 165)
	add_child(_due_label)

	# Gear column.
	var gear_box := VBoxContainer.new()
	gear_box.position = Vector2(80, 230)
	gear_box.add_theme_constant_override("separation", 6)
	add_child(gear_box)
	gear_box.add_child(UI.label("EQUIPMENT", 18, Color(0.65, 0.8, 0.95)))
	for g in _gear:
		gear_box.add_child(_make_gear_row(g))

	# Training column.
	_train_box = VBoxContainer.new()
	_train_box.position = Vector2(770, 230)
	_train_box.add_theme_constant_override("separation", 8)
	add_child(_train_box)
	_train_box.add_child(UI.label("TRAINING — one offer each", 18, Color(0.95, 0.8, 0.55)))
	_roll_offers()

	_pay_btn = UI.button("Pay minimum", 220, 20)
	_pay_btn.position = Vector2(80, 620)
	_pay_btn.pressed.connect(_pay)
	add_child(_pay_btn)

	_sleep_btn = UI.button("Sleep", 220, 20)
	_sleep_btn.position = Vector2(960, 620)
	_sleep_btn.pressed.connect(_sleep)
	add_child(_sleep_btn)

	_msg = UI.label("", 17, Color(0.8, 0.8, 0.8))
	_msg.position = Vector2(80, 585)
	add_child(_msg)

	_refresh()


func _load_gear() -> void:
	for f in DirAccess.get_files_at("res://data/gear"):
		if f.ends_with(".tres"):
			var g := load("res://data/gear/" + f) as GearDef
			if g != null:
				_gear.append(g)
	_gear.sort_custom(func(a, b): return a.id < b.id)


func _make_gear_row(g: GearDef) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var l := UI.label("", 18)
	l.custom_minimum_size = Vector2(240, 0)
	row.add_child(l)
	var b := UI.button("", 160, 16)
	b.pressed.connect(func(): _buy_gear(g))
	row.add_child(b)
	_rows.append({"gear": g, "label": l, "button": b})
	return row


func _buy_gear(g: GearDef) -> void:
	var tier: int = RunState.gear.get(g.slot, 0)
	var cost := g.next_cost(tier)
	if cost < 0:
		_msg.text = "Already maxed."
		return
	if not RunState.upgrade_gear(g.slot, cost):
		_msg.text = "Not enough cash."
		return
	_msg.text = "Bought %s tier %d." % [g.display_name, RunState.gear[g.slot]]
	_refresh.call_deferred()


func _roll_offers() -> void:
	var stats := ["luck", "fishing", "speed"]
	stats.shuffle()  # unique offers: heading promises "one offer each"
	for i in 3:
		var stat: String = stats[i]
		var cost := 60 + 25 * int(RunState.stats.get(stat, 0))
		var discount: bool = int(RunState.stats.get("luck", 0)) > 0 and RunState.rng.randf() < 0.25
		if discount:
			cost = int(round(cost * 0.75))
		_offers.append({"stat": stat, "cost": cost, "bought": false, "discount": discount})
	for offer in _offers:
		var b := UI.button("", 320, 17)
		b.pressed.connect(func(): _buy_training(offer, b))
		_train_box.add_child(b)
		offer["button"] = b
	_refresh_offers()


func _buy_training(offer: Dictionary, button: Button) -> void:
	if offer["bought"]:
		return
	if not RunState.spend(offer["cost"]):
		_msg.text = "Not enough cash."
		return
	RunState.add_stat(offer["stat"])
	offer["bought"] = true
	button.disabled = true
	button.text = "%s +1  (bought)" % _stat_name(offer["stat"])
	_msg.text = "Training: %s +1." % _stat_name(offer["stat"])
	_refresh()


func _refresh_offers() -> void:
	for offer in _offers:
		var b: Button = offer["button"]
		if offer["bought"]:
			continue
		b.text = "%s +1   $%d%s" % [
			_stat_name(offer["stat"]), offer["cost"], "  (luck deal)" if offer["discount"] else ""
		]
		b.disabled = RunState.cash < int(offer["cost"])


func _stat_name(stat: String) -> String:
	match stat:
		"luck": return "Luck"
		"fishing": return "Fishing"
		"speed": return "Speed"
	return stat


func _refresh() -> void:
	if _cash_label == null:
		return
	_cash_label.text = "Cash $%d   ·   debt $%d" % [RunState.cash, RunState.debt]
	_due_label.text = "Minimum tonight: $%d %s" % [
		RunState.minimum_today(), "(paid)" if RunState.minimum_paid_today else ""
	]
	_pay_btn.disabled = RunState.minimum_paid_today or RunState.cash < RunState.minimum_today()

	for row in _rows:
		var g: GearDef = row["gear"]
		var tier: int = RunState.gear.get(g.slot, 0)
		var cost := g.next_cost(tier)
		var label: Label = row["label"]
		var button: Button = row["button"]
		# Keep the row narrow: full description lives in the tooltip, or it
		# pushes the upgrade button into the training column.
		label.text = "%s  T%d" % [g.display_name, tier]
		label.tooltip_text = g.description
		if cost < 0:
			button.text = "MAX"
			button.disabled = true
		else:
			button.text = "Upgrade $%d" % cost
			button.disabled = RunState.cash < cost
	_refresh_offers()


func _pay() -> void:
	if RunState.pay_minimum():
		_msg.text = "Paid $%d. Debt now $%d." % [RunState.minimum_today(), RunState.debt]
	else:
		_msg.text = "Cannot pay that."
	_refresh()


func _sleep() -> void:
	if not RunState.minimum_paid_today:
		_msg.text = "Pay the minimum before sleeping."
		return
	if not RunState.end_day():
		return  # run ended; the router shows results
