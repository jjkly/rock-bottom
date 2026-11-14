extends Control
## ============================================================================
## RESULTS — the week's number.
## ============================================================================

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(UI.backdrop(Color(0.04, 0.04, 0.06)))

	var repaid_ratio := float(RunState.paid_total) / float(maxi(RunState.debt_start, 1))
	var pct := int(round(repaid_ratio * 100.0))

	var box := VBoxContainer.new()
	box.position = Vector2(120, 180)
	box.add_theme_constant_override("separation", 16)
	add_child(box)

	box.add_child(UI.label("Dawn, day eight.", 40))
	box.add_child(UI.label("The debt is settled with whatever you had left.", 20, Color(0.7, 0.7, 0.7)))

	var big := UI.label("%d%% repaid" % pct, 64, Color(1.0, 0.78, 0.35))
	box.add_child(big)

	box.add_child(UI.label("Paid $%d of $%d" % [RunState.paid_total, RunState.debt_start], 24))
	box.add_child(UI.label("Still owed: $%d" % RunState.debt, 22, Color(1.0, 0.55, 0.45)))

	if RunState.run_over and not RunState.minimum_paid_today:
		box.add_child(UI.label("You missed a minimum. The week ended early.", 18, Color(0.9, 0.5, 0.5)))

	box.add_child(UI.label("", 10))
	var again := UI.button("New week", 240, 22)
	again.pressed.connect(func(): RunState.start_run())
	box.add_child(again)
