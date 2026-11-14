extends Control
## ============================================================================
## MORNING — the plan screen. Weather is announced here and must be read before
## casting: hot means the freezer will spoil tonight, rain means rain-only fish.
## ============================================================================

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(UI.backdrop(Color(0.06, 0.07, 0.09)))

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	box.position = Vector2(80, 90)
	box.custom_minimum_size = Vector2(1100, 0)
	add_child(box)

	box.add_child(UI.label("Day %d of 7" % RunState.day, 40))
	box.add_child(UI.label("Debt remaining: $%d" % RunState.debt, 24, Color(1, 0.75, 0.55)))
	box.add_child(UI.label("Tonight's minimum: $%d" % RunState.minimum_today(), 24, Color(1, 0.85, 0.5)))

	box.add_child(UI.label("", 12))

	var weather_line := UI.label("Weather: %s" % RunState.weather_name(RunState.weather), 30)
	box.add_child(weather_line)
	if RunState.weather == 0:
		box.add_child(UI.label("Clear water. The usual catch.", 18, Color(0.7, 0.75, 0.8)))
	elif RunState.weather == 1:
		box.add_child(UI.label("Heat warning: every fish in the freezer spoils tonight.", 18, Color(1, 0.55, 0.4)))
	else:
		box.add_child(UI.label("Rain. Deep-water fish are moving in.", 18, Color(0.55, 0.8, 1)))

	box.add_child(UI.label("Tomorrow: %s" % RunState.weather_name(RunState.weather_tomorrow), 18, Color(0.55, 0.6, 0.68)))

	box.add_child(UI.label("", 20))
	var go := UI.button("Take the boat", 300, 24)
	go.pressed.connect(func(): RunState.advance_phase())
	box.add_child(go)

	box.add_child(UI.label("WASD / arrows to move in the evening · E to interact", 16, Color(0.5, 0.55, 0.6)))
