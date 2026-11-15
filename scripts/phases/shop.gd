extends Control
## ============================================================================
## NIGHT — pay the minimum, then spend what is left.
##
## Static nodes live in scenes/shop.tscn. Gear rows and the 3 training offers
## are built from data/gear/*.tres and the run's stats, because they are
## content, not layout.
## ============================================================================

@onready var _cash_label: Label = $CashLabel
@onready var _due_label: Label = $DueLabel
@onready var _msg: Label = $Message
@onready var _pay_btn: Button = $PayButton
@onready var _sleep_btn: Button = $SleepButton
@onready var _gear_box: VBoxContainer = $GearBox
@onready var _train_box: VBoxContainer = $TrainBox
@onready var _stats: Label = $StatsLabel

var _gear: Array[GearDef] = []
var _rows: Array[Dictionary] = []
var _offers: Array[Dictionary] = []
var _confirm: ConfirmationDialog
var _pending := Callable()


func _ready() -> void:
	UI.style_button(_pay_btn)
	UI.style_button(_sleep_btn)
	_pay_btn.pressed.connect(_pay_extra)
	_sleep_btn.pressed.connect(_sleep)

	_confirm = ConfirmationDialog.new()
	_confirm.title = "Are you sure?"
	_confirm.ok_button_text = "Yes"
	add_child(_confirm)
	_confirm.confirmed.connect(_run_pending)

	_load_gear()
	_build_gear_rows()
	_roll_offers()
	_refresh()


func _load_gear() -> void:
	for f in DirAccess.get_files_at("res://data/gear"):
		if f.ends_with(".tres"):
			var g := load("res://data/gear/" + f) as GearDef
			if g != null:
				_gear.append(g)
	_gear.sort_custom(func(a, b): return a.id < b.id)


func _build_gear_rows() -> void:
	for g in _gear:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var l := UI.label("", 18)
		l.custom_minimum_size = Vector2(240, 0)
		row.add_child(l)
		var b := UI.button("", 160, 16)
		b.pressed.connect(func(): _buy_gear(g))
		b.tooltip_text = g.description
		row.add_child(b)
		_gear_box.add_child(row)
		_rows.append({"gear": g, "label": l, "button": b})


func _buy_gear(g: GearDef) -> void:
	var tier: int = RunState.gear.get(g.slot, 0)
	var cost := g.next_cost(tier)
	if cost < 0:
		_msg.text = "Already maxed."
		return
	if RunState.cash < cost:
		_msg.text = "Not enough cash."
		return
	if RunState.cash - cost < RunState.installment_today():
		_ask("Buying %s leaves you $%d. Tonight's installment is $%d.\nBuy anyway?" % [
			g.display_name, RunState.cash - cost, RunState.installment_today()
		], "Buy", func(): _do_gear(g))
		return
	_do_gear(g)


func _do_gear(g: GearDef) -> void:
	var tier: int = RunState.gear.get(g.slot, 0)
	var cost := g.next_cost(tier)
	if cost < 0 or not RunState.upgrade_gear(g.slot, cost):
		_msg.text = "Not enough cash."
		return
	_msg.text = "Bought %s tier %d." % [g.display_name, RunState.gear[g.slot]]
	_refresh.call_deferred()


func _roll_offers() -> void:
	var stats := ["luck", "fishing", "speed"]
	stats.shuffle()  # unique offers: the heading promises "one offer each"
	for i in 3:
		var stat: String = stats[i]
		var level := int(RunState.stats.get(stat, 0))
		# Costs compound: fishing scales harder than the other two.
		var growth := 1.8 if stat == "fishing" else 1.5
		var cost := int(ceil(60.0 * pow(growth, level) / 5.0)) * 5
		var discount: bool = int(RunState.stats.get("luck", 0)) > 0 and RunState.rng.randf() < 0.25
		if discount:
			cost = int(round(cost * 0.75))
		var offer := {"stat": stat, "cost": cost, "bought": false, "discount": discount}
		var b := UI.button("", 320, 17)
		b.tooltip_text = _stat_help(offer["stat"])
		b.pressed.connect(func(): _buy_training(offer, b))
		_train_box.add_child(b)
		offer["button"] = b
		_offers.append(offer)
	_refresh_offers()


func _buy_training(offer: Dictionary, button: Button) -> void:
	if offer["bought"]:
		return
	if RunState.cash < int(offer["cost"]):
		_msg.text = "Not enough cash."
		return
	if RunState.cash - int(offer["cost"]) < RunState.installment_today():
		_ask("Training leaves you $%d. Tonight's installment is $%d.\nBuy anyway?" % [
			RunState.cash - int(offer["cost"]), RunState.installment_today()
		], "Buy", func(): _do_training(offer, button))
		return
	_do_training(offer, button)


func _do_training(offer: Dictionary, button: Button) -> void:
	if offer["bought"] or not RunState.spend(offer["cost"]):
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


func _stat_help(stat: String) -> String:
	match stat:
		"luck": return "Luck: +2% rare fish odds and better shop deals."
		"fishing": return "Fishing: +1 cast every 2 points (cap 10)."
		"speed": return "Speed: +10 movement speed per point."
	return ""


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
	if _stats != null:
		_stats.text = "Luck %d  ·  Fishing %d  ·  Speed %d" % [
			RunState.stats.get("luck", 0), RunState.stats.get("fishing", 0), RunState.stats.get("speed", 0)
		]
		_stats.tooltip_text = "Luck: +2% rare odds and shop deals\nFishing: +1 cast every 2 points\nSpeed: +10 move speed per point"
	_due_label.text = "Installment %d/7 tonight: $%d (charged when you sleep)" % [
		RunState.installment_number(), RunState.installment_today()
	]
	_pay_btn.disabled = RunState.cash < 100 or RunState.debt <= 0

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


func _pay_extra() -> void:
	if RunState.pay_extra(100):
		_msg.text = "Paid $100 extra. Debt now $%d." % RunState.debt
	else:
		_msg.text = "Need $100 spare cash."
	_refresh()


func _sleep() -> void:
	if RunState.cash < RunState.installment_today():
		_ask("You are $%d short of tonight's $%d installment.\nSleep anyway?" % [
			RunState.installment_today() - RunState.cash, RunState.installment_today()
		], "Sleep", _do_sleep)
		return
	_do_sleep()


func _do_sleep() -> void:
	# The installment is charged inside end_day(); if it cannot be paid the
	# run ends and the router swaps to results.
	RunState.end_day()


func _ask(text: String, ok_text: String, action: Callable) -> void:
	_pending = action
	_confirm.dialog_text = text
	_confirm.ok_button_text = ok_text
	_confirm.popup_centered(Vector2i(460, 170))


func _run_pending() -> void:
	if _pending.is_valid():
		_pending.call()
	_pending = Callable()
