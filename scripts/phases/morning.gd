extends Control
## ============================================================================
## MORNING — the plan screen. Nodes live in scenes/morning.tscn.
## Weather must be read before casting: hot spoils the freezer tonight, rain
## opens the rain-only species.
## ============================================================================

@onready var _title: Label = $Title
@onready var _debt: Label = $DebtLabel
@onready var _minimum: Label = $MinLabel
@onready var _weather: Label = $WeatherLabel
@onready var _hint: Label = $WeatherHint
@onready var _tomorrow: Label = $TomorrowLabel
@onready var _boat: Button = $BoatButton


func _ready() -> void:
	UI.style_button(_boat)
	_boat.pressed.connect(func(): RunState.advance_phase())

	_title.text = "Day %d of 7" % RunState.day
	_debt.text = "Debt remaining: $%d" % RunState.debt
	_minimum.text = "Tonight's installment: $%d  (%d/7)" % [RunState.installment_today(), RunState.installment_number()]
	_weather.text = "Weather: %s" % RunState.weather_name(RunState.weather)
	_tomorrow.text = "Tomorrow: %s" % RunState.weather_name(RunState.weather_tomorrow)

	match RunState.weather:
		0:
			_hint.text = "Clear water. The usual catch."
			_hint.add_theme_color_override("font_color", Color(0.7, 0.75, 0.8))
		1:
			_hint.text = "Heat warning: every fish in the freezer spoils tonight."
			_hint.add_theme_color_override("font_color", Color(1, 0.55, 0.4))
		_:
			_hint.text = "Rain. Deep-water fish are moving in."
			_hint.add_theme_color_override("font_color", Color(0.55, 0.8, 1))
