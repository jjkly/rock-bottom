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
	_test_minimum(t)
	_test_value(t)
	_test_aging(t)
	_test_hot_weather(t)
	_test_serving_money(t)
	_test_carry_plates(t)


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


static func _test_minimum(t) -> void:
	var rs = _new_run()
	rs.advance_phase()
	rs.advance_phase()
	rs.advance_phase()
	t.eq(rs.phase, 3, "three advances reach NIGHT")
	t.eq(rs.pay_minimum(), false, "cannot pay with $0")
	rs.earn(100)
	t.eq(rs.pay_minimum(), true, "can pay the $60 minimum")
	t.eq(rs.cash, 40, "cash after paying minimum")
	t.eq(rs.debt, 1940, "debt after paying minimum")
	t.eq(rs.paid_total, 60, "paid total tracks the minimum")
	t.eq(rs.minimum_paid_today, true, "marked paid")
	t.eq(rs.end_day(), true, "day ends when minimum is paid")
	t.eq(rs.day, 2, "advanced to day 2")
	t.eq(rs.phase, 0, "next day starts in MORNING")
	rs.free()


static func _test_value(t) -> void:
	var f = _fish(28, 8)
	t.eq(f.value(), 42, "8-slice fish: 28 x 1.5")
	f.age_days = 2
	t.eq(f.value(), 59, "two days aged: 42 x 1.4")
	var g = ModifierDefScript.new()
	g.sale_mult = 1.75
	var golden = _fish(28, 8, g)
	t.eq(golden.value(), 74, "golden 8-slice: 28 x 1.5 x 1.75")


static func _test_aging(t) -> void:
	var f = _fish(28, 8)
	t.eq(f.aging_multiplier(), 1.0, "fresh fish has no aging bonus")
	f.age_days = 2
	t.eq(f.aging_multiplier(), 1.4, "peaks at two days")
	f.age_days = 5
	t.eq(f.aging_multiplier(), 0.5, "rots after four days")

	var m = ModifierDefScript.new()
	m.never_spoils = true
	var ice = _fish(28, 8, m)
	ice.age_days = 5
	t.eq(ice.aging_multiplier(), 1.0, "ice cold never ages")


static func _test_serving_money(t) -> void:
	var rs = _new_run()
	var f = _fish(50, 4)  # lean, 4 slices -> x1.0
	rs.add_to_stock(f)
	t.eq(rs.serve_plate(f, "lean"), 60, "matching preference pays +20%")
	t.eq(rs.cash, 60, "cash rose by the served value")
	t.eq(f.plates_left, 0, "serving consumed the only plate")
	t.eq(rs.stock.size(), 0, "empty fish leaves the stock")
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


static func _test_hot_weather(t) -> void:
	var rs = _new_run()
	rs.advance_phase()
	rs.advance_phase()
	rs.advance_phase()
	rs.earn(100)
	rs.pay_minimum()

	var m = ModifierDefScript.new()
	m.never_spoils = true
	var normal = _fish(28, 8)
	var ice = _fish(28, 8, m)
	rs.freeze(normal)
	rs.freeze(ice)

	rs.weather = 1  # HOT
	rs.end_day()
	t.eq(normal.spoiled, true, "hot day spoils freezer fish")
	t.eq(normal.value(), 0, "spoiled fish is worthless")
	t.eq(ice.spoiled, false, "ice cold survives a hot day")
	t.eq(ice.value(), 42, "ice cold keeps its value")
	rs.free()
