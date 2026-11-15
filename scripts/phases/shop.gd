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

var _gear: Array[GearDef] = []
var _rows: Array[Dictionary] = []
var _offers: Array[Dictionary] = []


func _ready() -> void:
	UI.style_button(_pay_btn)
	UI.style_button(_sleep_btn)
	_pay_btn.pressed.connect(_pay_extra)
	_sleep_btn.pressed.connect(_sleep)

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
		row.add_child(b)
		_gear_box.add_child(row)
		_rows.append({"gear": g, "label": l, "button": b})


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
	stats.shuffle()  # unique offers: the heading promises "one offer each"
	for i in 3:
		var stat: String = stats[i]
		var cost := 60 + 25 * int(RunState.stats.get(stat, 0))
		var discount: bool = int(RunState.stats.get("luck", 0)) > 0 and RunState.rng.randf() < 0.25
		if discount:
			cost = int(round(cost * 0.75))
		var offer := {"stat": stat, "cost": cost, "bought": false, "discount": discount}
		var b := UI.button("", 320, 17)
		b.pressed.connect(func(): _buy_training(offer, b))
		_train_box.add_child(b)
		offer["button"] = b
		_offers.append(offer)
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
	# The installment is charged inside end_day(); if it cannot be paid the
	# run ends and the router swaps to results.
	RunState.end_day()
