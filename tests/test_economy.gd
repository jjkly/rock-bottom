extends RefCounted
## ============================================================================
## Economy tests — the week's money rules. No scenes, no physics, no tree.
## If one of these fails, the design changed or a rule broke. Both need a look.
## ============================================================================

const RunStateScript := preload("res://addons/framework/run_state.gd")
const SpeciesDefScript := preload("res://scripts/data/species_def.gd")
const ModifierDefScript := preload("res://scripts/data/modifier_def.gd")
const FishInstanceScript := preload("res://scripts/data/fish_instance.gd")


static func run(t) -> void:
	_test_start(t)
	_test_installment(t)
	_test_value(t)
	_test_aging(t)
	_test_hot_weather(t)
	_test_serving_money(t)
	_test_carry_plates(t)
	_test_extra_payment(t)
	_test_tank_move(t)
	_test_difficulty(t)
	_test_replays(t)


static func _new_run(seed_value: int = 7):
	var rs = RunStateScript.new()
	rs.start_run(seed_value)
	return rs


static func _species(base: int, preference: String = "lean"):
	var s = SpeciesDefScript.new()
	s.id = "test"
	s.display_name = "Test Fish"
	s.base_price = base
	s.preference = preference
	return s


static func _fish(base: int, slices: int = 8, mod: Resource = null):
	return FishInstanceScript.new(_species(base), slices, mod)


static func _test_start(t) -> void:
	var rs = _new_run()
	t.eq(rs.day, 1, "run starts on day 1")
	t.eq(rs.debt, 2000, "run starts with $2000 debt")
	t.eq(rs.cash, 0, "run starts with no cash")
	t.eq(rs.phase, 0, "run starts in MORNING")
	t.eq(rs.weather, 0, "day 1 is always CLEAR")
	t.eq(rs.stock.size(), 0, "stock starts empty")
	rs.free()


static func _test_installment(t) -> void:
	# Empty wallet: the auto-charge fails and the run ends.
	var broke = _new_run()
	broke.set_difficulty(2)  # hard: no replay
	broke.start_run()
	broke.advance_phase()
	broke.advance_phase()
	broke.advance_phase()
	t.eq(broke.phase, 3, "three advances reach NIGHT")
	t.eq(broke.installment_today(), 120, "hard day 1 installment is $120")
	t.eq(broke.end_day(), false, "cannot pay with $0")
	t.eq(broke.missed_installment, true, "missed installment is recorded")
	t.eq(broke.run_over, true, "missing an installment ends the run")
	broke.free()

	# Funded: sleeping charges the installment and advances the day.
	var rs = _new_run()
	rs.advance_phase()
	rs.advance_phase()
	rs.advance_phase()
	rs.earn(250)
	t.eq(rs.end_day(), true, "installment charged on sleep")
	t.eq(rs.cash, 150, "cash after the $100 installment")
	t.eq(rs.debt, 1900, "debt after the installment")
	t.eq(rs.paid_total, 100, "paid total tracks the installment")
	t.eq(rs.day, 2, "advanced to day 2")
	t.eq(rs.phase, 0, "next day starts in MORNING")
	t.eq(rs.installment_today(), 150, "day 2 installment is $150")
	rs.free()

	# The last day is the balloon.
	var last = _new_run()
	last.day = 7
	t.eq(last.installment_today(), 700, "day 7 balloon is $700")
	last.free()


static func _test_value(t) -> void:
	var f = _fish(28, 8)
	t.eq(f.value(), 42, "8-slice fish: 28 x 1.5")
	f.age_days = 1
	t.eq(f.value(), 42, "one day in the tank keeps full value")
	f.age_days = 2
	t.eq(f.value(), 0, "two days in the tank spoils it")
	var g = ModifierDefScript.new()
	g.sale_mult = 1.75
	var golden = _fish(28, 8, g)
	t.eq(golden.value(), 74, "golden 8-slice: 28 x 1.5 x 1.75")


static func _test_aging(t) -> void:
	var f = _fish(28, 8)
	t.eq(f.aging_multiplier(), 1.0, "fresh fish is worth full value")
	f.age_days = 1
	t.eq(f.aging_multiplier(), 1.0, "one day in the tank is safe")
	f.age_days = 2
	t.eq(f.aging_multiplier(), 0.0, "the second day spoils it")
	f.spoiled = true
	t.eq(f.aging_multiplier(), 0.0, "spoiled fish stays worthless")

	var m = ModifierDefScript.new()
	m.never_spoils = true
	var ice = _fish(28, 8, m)
	ice.age_days = 5
	t.eq(ice.aging_multiplier(), 1.0, "ice cold never spoils")


static func _test_serving_money(t) -> void:
	var rs = _new_run()
	var f = _fish(50, 4)  # lean, 4 slices -> x1.0
	rs.add_to_stock(f)
	t.eq(rs.serve_plate(f, "lean"), 60, "matching preference pays +20%")
	t.eq(rs.cash, 60, "cash rose by the served value")
	t.eq(f.plates_left, 0, "serving consumed the only plate")
	t.eq(rs.stock.size(), 0, "empty fish leaves the stock")
	rs.free()


static func _test_extra_payment(t) -> void:
	var rs = _new_run()
	rs.earn(500)
	t.eq(rs.pay_extra(300), true, "extra payment accepted")
	t.eq(rs.cash, 200, "cash reduced by the extra payment")
	t.eq(rs.debt, 1700, "debt reduced by the extra payment")
	t.eq(rs.paid_total, 300, "extra payment counts toward the score")
	rs.free()


static func _test_carry_plates(t) -> void:
	var rs = _new_run()
	var f = _fish(50, 4)
	rs.add_to_stock(f)
	t.eq(rs.take_plate(f), true, "take_plate removes a plate from stock")
	t.eq(f.plates_left, 0, "plate consumed")
	t.eq(rs.take_plate(f), false, "cannot take from an emptied fish")
	t.eq(rs.pay_plate(f, "lean"), 60, "pay_plate pays the +20% match")
	t.eq(rs.cash, 60, "cash rose for the carried plate")
	rs.free()


static func _test_tank_move(t) -> void:
	var rs = _new_run()
	var f = _fish(28, 8)
	rs.add_to_stock(f)
	t.eq(rs.freeze(f), true, "fish stored in the tank")
	t.eq(rs.tank.size(), 1, "tank holds the fish")
	t.eq(rs.stock.size(), 0, "stored fish leaves stock")
	t.eq(rs.take_from_tank(f), true, "fish taken out of the tank")
	t.eq(rs.stock.size(), 1, "taken fish returns to stock")
	t.eq(rs.tank.size(), 0, "tank is empty again")
	rs.free()


static func _test_difficulty(t) -> void:
	var easy = _new_run()
	easy.set_difficulty(0)
	easy.start_run()
	t.eq(easy.debt, 1600, "easy debt is $1600")
	t.eq(easy.installment_today(), 80, "easy day 1 installment is $80")
	t.eq(easy.rare_multiplier(), 1.2, "easy rare odds +20%")
	easy.free()

	var hard = _new_run()
	hard.set_difficulty(2)
	hard.start_run()
	t.eq(hard.debt, 2400, "hard debt is $2400")
	t.eq(hard.installment_today(), 120, "hard day 1 installment is $120")
	t.eq(hard.rare_multiplier(), 0.8, "hard rare odds -20%")
	hard.free()


static func _test_replays(t) -> void:
	var rs = _new_run()
	rs.set_difficulty(1)  # medium: one replay
	rs.start_run()
	rs.advance_phase(); rs.advance_phase(); rs.advance_phase()
	t.eq(rs.replays_left, 1, "medium starts with one replay")
	# Empty wallet at night: rewind to the morning of the same day.
	t.eq(rs.end_day(), false, "missing the installment stops the night")
	t.eq(rs.replays_left, 0, "replay consumed")
	t.eq(rs.day, 1, "day rewound")
	t.eq(rs.phase, 0, "back to morning")
	t.eq(rs.run_over, false, "run continues after a replay")
	rs.free()

	var hard = _new_run()
	hard.set_difficulty(2)
	hard.start_run()
	hard.advance_phase(); hard.advance_phase(); hard.advance_phase()
	t.eq(hard.end_day(), false, "hard cannot pay")
	t.eq(hard.run_over, true, "hard run ends")
	hard.free()


static func _test_hot_weather(t) -> void:
	var rs = _new_run()
	rs.advance_phase()
	rs.advance_phase()
	rs.advance_phase()
	rs.earn(100)   # end_day() charges the $100 installment

	var m = ModifierDefScript.new()
	m.never_spoils = true
	var normal = _fish(28, 8)
	var ice = _fish(28, 8, m)
	rs.freeze(normal)
	rs.freeze(ice)

	rs.weather = 1  # HOT
	rs.end_day()
	t.eq(normal.spoiled, true, "hot day spoils tank fish")
	t.eq(normal.value(), 0, "spoiled fish is worthless")
	t.eq(ice.spoiled, false, "ice cold survives a hot day")
	t.eq(ice.value(), 42, "ice cold keeps its value")
	rs.free()
