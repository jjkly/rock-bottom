extends Control
## ============================================================================
## RESULTS — the week's number. Nodes live in scenes/results.tscn.
## ============================================================================

@onready var _big: Label = $Big
@onready var _paid: Label = $PaidLabel
@onready var _owed: Label = $OwedLabel
@onready var _missed: Label = $MissedLabel
@onready var _again: Button = $AgainButton


func _ready() -> void:
	UI.style_button(_again)
	_again.pressed.connect(func(): RunState.start_run())

	var repaid_ratio := float(RunState.paid_total) / float(maxi(RunState.debt_start, 1))
	_big.text = "%d%% repaid" % int(round(repaid_ratio * 100.0))
	_paid.text = "Paid $%d of $%d" % [RunState.paid_total, RunState.debt_start]
	_owed.text = "Still owed: $%d" % RunState.debt
	_missed.visible = RunState.run_over and not RunState.minimum_paid_today
