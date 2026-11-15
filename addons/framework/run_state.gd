extends Node
## ============================================================================
## RunState — the single source of truth for one week (7 days) of the game.
##
## WHY THIS EXISTS
##   Every phase (fishing, evening, shop) needs the same numbers: cash, debt,
##   day, stock, tank, gear. If each scene keeps its own copy they drift,
##   and "why did the shop show $80 when the HUD showed $120" eats a day.
##   So: one autoload, one authority, everything else listens to signals.
##
## WHO EDITS THIS
##   Framework owner. Gameplay scenes should ONLY call the public functions
##   below and connect to the signals — never write these vars directly.
##   If you need a new field, add it here and tell the others; do not stash
##   state on a scene.
##
## WHAT TO CHANGE FIRST (design knobs, all near the top)
##   START_DEBT / INSTALLMENTS  -> the difficulty curve of the week
##   START_TANK_SLOTS        -> tank pressure
##   WEATHER_WEIGHTS            -> how often hot/rain happen
##
## TESTED BY res://tests/test_economy.gd (run: see docs/contract.md).
## ============================================================================

# --- The four phase types of a single day, in order. ------------------------
# MORNING: news, shipments.  FISHING: the reel minigame + crate.
# EVENING: Overcooked-style service.  NIGHT: pay minimum, shop, sleep.
enum Phase { MORNING, FISHING, EVENING, NIGHT }

# --- Weather is one enum, three states, no forecasts. -----------------------
# CLEAR: baseline.  HOT: every tank fish spoils at end of day.
# RAIN: the catch table swaps in rain-only species.
enum Weather { CLEAR, HOT, RAIN }

# --- The week's economy. ---------------------------------------------------
# The $2,000 debt is split into seven installments that are charged
# automatically when you sleep. Days 1-6 are survival; day 7 is a $700 balloon
# that forces you to save instead of spending everything on gear.
# Sum = 2000. Anything you pay above an installment is score.
const DAYS_PER_RUN := 7
const START_DEBT := 2000
const INSTALLMENTS: Array[int] = [100, 150, 200, 250, 300, 300, 700]

const START_TANK_SLOTS := 21

# Weights are relative, not percentages: 50/25/25 = 50% clear, 25% hot, 25% rain.
const WEATHER_WEIGHTS := {
	Weather.CLEAR: 50,
	Weather.HOT: 25,
	Weather.RAIN: 25,
}

# --- Signals: the only way scenes learn that something changed. -------------
# Connect in _ready():  RunState.cash_changed.connect(_on_cash_changed)
signal phase_changed(from_phase: int, to_phase: int)
signal day_started(day: int)
signal cash_changed(cash: int)
signal debt_changed(remaining_debt: int)
signal stock_changed
signal tank_changed
signal gear_changed(slot: String, tier: int)
signal quota_paid(day: int, amount: int)
signal quota_missed(day: int)
signal weather_changed(weather: int)
signal run_ended(repaid_ratio: float, remaining_debt: int)

# --- State. Read it, don't write it. ----------------------------------------
var day := 1
var phase: Phase = Phase.MORNING
var cash := 0
var debt := 0              # remaining debt (start - everything paid so far)
var debt_start := 0
var paid_total := 0        # what the score is computed from
var installment_paid_today := false
var missed_installment := false
var run_over := false

var weather: Weather = Weather.CLEAR
var weather_tomorrow: Weather = Weather.CLEAR

# Fish caught but not yet served. Cleared/moved at end of day.
var stock: Array[FishInstance] = []
# Fish held across days. Aging raises value up to a peak, then it rots.
var tank: Array[FishInstance] = []
var tank_capacity := START_TANK_SLOTS

# Gear tiers, 0 = stock starter item. Keys are fixed; the shop reads them.
var gear := {"rod": 0, "knife": 0, "tank": 0}
# Per-run training stats (bought in the nightly 3-of-N draft).
var stats := {"luck": 0, "fishing": 0, "speed": 0}

# Seeded so a run can be reproduced from a debug log.
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	# Nothing runs until the game calls start_run() — the dev harness in
	# scripts/game.gd does it. Keeps tests in control of their own state.
	pass


# ============================================================================
# PUBLIC API — scenes call these, nothing else.
# ============================================================================

## Wipe state and begin a new week. Call once when the run starts.
func start_run(seed_value: int = 0) -> void:
	day = 1
	phase = Phase.MORNING
	cash = 0
	debt_start = START_DEBT
	debt = START_DEBT
	paid_total = 0
	installment_paid_today = false
	missed_installment = false
	run_over = false

	stock.clear()
	tank.clear()
	gear = {"rod": 0, "knife": 0, "tank": 0}
	stats = {"luck": 0, "fishing": 0, "speed": 0}
	tank_capacity = START_TANK_SLOTS

	# Day 1 is always clear: the player should learn the loop before weather.
	weather = Weather.CLEAR
	if seed_value == 0:
		rng.randomize()
	else:
		rng.seed = seed_value
	weather_tomorrow = _roll_weather()

	day_started.emit(day)
	cash_changed.emit(cash)
	debt_changed.emit(debt)
	weather_changed.emit(weather)
	stock_changed.emit()
	tank_changed.emit()


## MORNING -> FISHING -> EVENING -> NIGHT. Night ends via end_day().
func advance_phase() -> void:
	if run_over:
		return
	match phase:
		Phase.MORNING: _set_phase(Phase.FISHING)
		Phase.FISHING: _set_phase(Phase.EVENING)
		Phase.EVENING: _set_phase(Phase.NIGHT)
		Phase.NIGHT:
			# The night is closed out by end_day(), which also checks payment.
			push_warning("advance_phase() at NIGHT — call end_day() instead.")


## Close the night: charge tonight's installment, spoil/age the tank,
## move leftovers, roll weather, start the next day (or end the run).
## Returns false if the installment could not be paid (run over).
func end_day() -> bool:
	if run_over:
		return false
	if phase != Phase.NIGHT:
		push_warning("end_day() called outside NIGHT — ignored.")
		return false

	var due := installment_today()
	if cash < due:
		missed_installment = true
		run_over = true
		quota_missed.emit(day)
		_settle_and_end()
		return false

	cash -= due
	debt -= due
	paid_total += due
	installment_paid_today = true
	cash_changed.emit(cash)
	debt_changed.emit(debt)
	quota_paid.emit(day, due)

	# Order matters: existing tank contents feel tonight's heat and age
	# one day; fish caught today are stored afterwards, so they start at 0.
	_apply_end_of_day_weather()
	_age_tank()
	_store_leftover_stock()

	if day >= DAYS_PER_RUN:
		_settle_and_end()
		return true

	day += 1
	phase = Phase.MORNING
	installment_paid_today = false
	missed_installment = false
	weather = weather_tomorrow
	weather_tomorrow = _roll_weather()

	day_started.emit(day)
	weather_changed.emit(weather)
	phase_changed.emit(Phase.NIGHT, Phase.MORNING)
	stock_changed.emit()
	tank_changed.emit()
	return true


## Tonight's installment. Charged automatically by end_day().
func installment_today() -> int:
	return INSTALLMENTS[clampi(day - 1, 0, INSTALLMENTS.size() - 1)]


## 1-based "3/7" for the UI.
func installment_number() -> int:
	return clampi(day, 1, DAYS_PER_RUN)


## Voluntary overpayment: pays down the debt and raises the final score.
## Capped at the remaining debt.
func pay_extra(amount: int) -> bool:
	if amount <= 0 or cash < amount or debt <= 0:
		return false
	var applied := mini(amount, debt)
	cash -= applied
	debt -= applied
	paid_total += applied
	cash_changed.emit(cash)
	debt_changed.emit(debt)
	return true


func spend(amount: int) -> bool:
	if amount <= 0 or cash < amount:
		return false
	cash -= amount
	cash_changed.emit(cash)
	return true


func earn(amount: int) -> void:
	if amount <= 0:
		return
	cash += amount
	cash_changed.emit(cash)


## Add a freshly caught fish to today's stock.
func add_to_stock(fish: FishInstance) -> void:
	stock.append(fish)
	stock_changed.emit()


## Serve one plate from a stock fish. Returns the cash earned (0 if invalid).
## Kept for one-shot callers/tests; carrying uses take_plate + pay_plate.
func serve_plate(fish: FishInstance, table_preference: String) -> int:
	if not stock.has(fish) or fish.plates_left <= 0:
		return 0
	var value := pay_plate(fish, table_preference)
	take_plate(fish)
	return value


## Remove one plate from a stock fish (for carrying). False if unavailable.
func take_plate(fish: FishInstance) -> bool:
	if not stock.has(fish) or fish.plates_left <= 0:
		return false
	fish.plates_left -= 1
	if fish.plates_left <= 0:
		stock.erase(fish)
	stock_changed.emit()
	return true


## Pay for a plate that was already taken. Preference match gives +20%.
func pay_plate(fish: FishInstance, table_preference: String) -> int:
	var value := fish.value()
	if fish.matches(table_preference):
		value = int(round(value * 1.2))
	# Knife tiers are finer cuts: +5% plate value each.
	value = int(round(value * (1.0 + 0.05 * int(gear.get("knife", 0)))))
	cash += value
	cash_changed.emit(cash)
	return value


## Move a portion out of the tank and back into today's stock.
func take_from_tank(fish: FishInstance) -> bool:
	if not tank.has(fish):
		return false
	tank.erase(fish)
	stock.append(fish)
	tank_changed.emit()
	stock_changed.emit()
	return true


## Put a fish in the tank. False if full.
func freeze(fish: FishInstance) -> bool:
	if tank.size() >= tank_capacity:
		return false
	if stock.has(fish):
		stock.erase(fish)
	tank.append(fish)
	stock_changed.emit()
	tank_changed.emit()
	return true


## Sell a raw fish instead of serving it. Raw always pays less than a plate
## (that gap is what makes cooking and serving the real business).
func sell(fish: FishInstance, from_tank: bool = false) -> int:
	var pool := tank if from_tank else stock
	if not pool.has(fish):
		return 0
	var value := int(round(fish.value() * 0.6))
	pool.erase(fish)
	cash += value
	cash_changed.emit(cash)
	stock_changed.emit()
	tank_changed.emit()
	return value


## Buy one tier of a gear slot. The shop UI is responsible for offering only
## legal purchases; this enforces cost and tier bounds.
func upgrade_gear(slot: String, cost: int) -> bool:
	if not gear.has(slot):
		return false
	if not spend(cost):
		return false
	gear[slot] += 1
	if slot == "tank":
		tank_capacity = START_TANK_SLOTS + 7 * int(gear["tank"])
	gear_changed.emit(slot, gear[slot])
	return true


func add_stat(stat_name: String, amount: int = 1) -> void:
	if stats.has(stat_name):
		stats[stat_name] += amount


# ============================================================================
# INTERNALS — safe to read, don't call from scenes.
# ============================================================================

func _set_phase(next_phase: Phase) -> void:
	var old := phase
	phase = next_phase
	phase_changed.emit(old, next_phase)


func _roll_weather() -> Weather:
	var roll := rng.randi_range(1, 100)
	var acc := 0
	for w in WEATHER_WEIGHTS:
		acc += int(WEATHER_WEIGHTS[w])
		if roll <= acc:
			return w
	return Weather.CLEAR


## HOT spoils existing tank fish. Ice cold ignores it (that's its job).
func _apply_end_of_day_weather() -> void:
	if weather != Weather.HOT:
		return
	for fish in tank:
		if fish.modifier != null and fish.modifier.never_spoils:
			continue
		fish.spoiled = true


func _age_tank() -> void:
	for fish in tank:
		if fish.modifier != null and fish.modifier.never_spoils:
			continue
		fish.age_days += 1
		# One day of storage is safe; the second night spoils it.
		if fish.age_days > FishInstance.SAFE_DAYS:
			fish.spoiled = true


## Unserved stock goes in the tank if there's room, otherwise it is lost.
## Tune later: this is a design decision, not an implementation detail.
func _store_leftover_stock() -> void:
	for fish in stock:
		if tank.size() < tank_capacity:
			tank.append(fish)
	stock.clear()


## Add leftover cash to the debt, compute the score, fire run_ended once.
func _settle_and_end() -> void:
	run_over = true
	if cash > 0:
		paid_total += cash
		debt = maxi(0, debt - cash)
		cash = 0
	var ratio := float(paid_total) / float(maxi(debt_start, 1))
	cash_changed.emit(cash)
	debt_changed.emit(debt)
	run_ended.emit(ratio, debt)


# ============================================================================
# DEBUG — required by the framework checklist: every system prints its state.
# ============================================================================

func debug_state() -> String:
	return "day=%d/%d phase=%s cash=%d debt=%d paid=%d stock=%d tank=%d/%d gear=%s stats=%s weather=%s" % [
		day, DAYS_PER_RUN, phase_name(phase), cash, debt, paid_total,
		stock.size(), tank.size(), tank_capacity, str(gear), str(stats),
		weather_name(weather),
	]


func phase_name(p: int) -> String:
	return ["MORNING", "FISHING", "EVENING", "NIGHT"][p]


func weather_name(w: int) -> String:
	return ["CLEAR", "HOT", "RAIN"][w]
