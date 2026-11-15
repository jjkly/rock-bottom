class_name UI
extends RefCounted
## Small helpers so every phase builds its UI the same way.
## No theme resource yet: sizes and colours are set inline, one place to change.

static func label(text: String, size := 20, color := Color(0.95, 0.95, 0.92)) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


static func button(text: String, width := 220.0, size := 20) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(width, 44)
	b.add_theme_font_size_override("font_size", size)
	# Keyboard focus would make Space press the last button instead of the reel.
	b.focus_mode = Control.FOCUS_NONE
	style_button(b)
	return b


## Apply the house button look to a Button that lives in a scene file.
static func style_button(b: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.14, 0.15, 0.19)
	normal.border_color = Color(0.32, 0.35, 0.42)
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(4)
	b.add_theme_stylebox_override("normal", normal)

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.20, 0.22, 0.28)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)


static func panel(bg := Color(0.07, 0.07, 0.10, 0.92)) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.corner_radius_top_left = 6
	sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_left = 6
	sb.corner_radius_bottom_right = 6
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	p.add_theme_stylebox_override("panel", sb)
	return p


## Colour per table preference/tag. One place so tables and inventory agree.
static func tag_color(tag: String) -> Color:
	match tag:
		"lean": return Color(0.45, 0.7, 1.0)
		"fatty": return Color(0.78, 0.55, 1.0)
		"cheap": return Color(0.5, 0.9, 0.6)
		"expensive": return Color(1.0, 0.82, 0.35)
	return Color(0.85, 0.85, 0.85)


## Full-screen flat background for Control roots.
static func backdrop(color := Color(0.05, 0.06, 0.08)) -> ColorRect:
	var c := ColorRect.new()
	c.color = color
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return c
