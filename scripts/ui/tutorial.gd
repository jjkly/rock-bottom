extends CanvasLayer
## ============================================================================
## Tutorial modal — one popup per phase on day 1, re-openable from the HUD.
## Pauses the tree while open; "More" expands extra detail.
## ============================================================================

signal closed

const CONTENT := {
	0: {
		"title": "Morning",
		"body": "You have one week to pay a $2,000 debt. Read today's weather, then click Go to dock.\n\nHot days spoil the fish tank. Rain brings different fish.",
		"more": "The debt is seven installments, charged when you sleep: 100, 150, 200, 250, 300, 300, then a $700 balloon on day 7. Fall short and the week ends.\n\nOverpaying is optional and only improves your final score.",
	},
	1: {
		"title": "Fishing",
		"body": "SPACE casts. SPACE again stops the marker. E skips the crate animation.\n\nThe closer the marker stops to the centre, the bigger the fish and the better the loot.",
		"more": "Four bar zones: centre = 8 slices and the best species odds, then 6, 4, and 3 on the outer edge.\n\nThe crate is a scrolling reel. Tile colour is rarity by price: grey, green, blue, purple, gold. The name under the marker updates as it scrolls.",
	},
	2: {
		"title": "Evening",
		"body": "WASD moves. E takes a plate at the cutting board, and E serves it at a table.\n\nEach table wants a preference: lean, fatty, cheap or rare. Match it for +20%.",
		"more": "Walk to the fish tank on the right to see stored fish; click one to move it back to stock. Fish keep for one day in the tank, then spoil.\n\nStock rows show the preference tag and its colour. Tables shuffle position and preference every service.",
	},
	3: {
		"title": "Night",
		"body": "Sleep charges tonight's installment automatically. If you are short, the week ends.\n\nBuy gear or training with what is left, or Pay extra to reduce the debt.",
		"more": "A purchase that would leave you below tonight's installment asks for confirmation first, and sleep warns you if you are short.\n\nGear is permanent for the run. Training is a one-time pick from three offers.",
	},
}

@onready var _root: Control = $Root
@onready var _title: Label = $Root/Box/Title
@onready var _body: Label = $Root/Box/Body
@onready var _more_text: Label = $Root/Box/MoreText
@onready var _more_btn: Button = $Root/Box/MoreButton
@onready var _got_it: Button = $Root/Box/GotIt


func _ready() -> void:
	_root.visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	UI.style_button(_more_btn)
	UI.style_button(_got_it)
	_more_btn.pressed.connect(_toggle_more)
	_got_it.pressed.connect(_close)


func open(phase: int) -> void:
	var data: Dictionary = CONTENT.get(phase, CONTENT[0])
	_title.text = data["title"]
	_body.text = data["body"]
	_more_text.text = data["more"]
	_more_text.visible = false
	_more_btn.text = "More"
	_root.visible = true
	get_tree().paused = true


func _toggle_more() -> void:
	_more_text.visible = not _more_text.visible
	_more_btn.text = "Less" if _more_text.visible else "More"


func _close() -> void:
	_root.visible = false
	get_tree().paused = false
	closed.emit()
