extends SceneTree
## ============================================================================
## run_tests.gd — headless test runner. Run this before every push:
##
##   godot --headless --path . -s res://tests/run_tests.gd
##
## Exit code 0 = all good, 1 = failures. CI can run exactly this line.
## Add a test by creating tests/test_<name>.gd with `static func run(t)` and
## calling it from _initialize() below. Keep tests free of scenes: preload the
## script, instantiate, assert.
##
## RULE (from the systems checklist): a test that always passes is worse than
## no test. Break the rule on purpose once and confirm the test fails.
## ============================================================================

const TestEconomy := preload("res://tests/test_economy.gd")
const TestService := preload("res://tests/test_service.gd")

var checks := 0
var failures := 0


func _initialize() -> void:
	print("== sashimi-debt tests ==")
	# project.godot is hand-edited; prove the input map actually parsed.
	for action in ["move_left", "move_right", "move_up", "move_down", "interact"]:
		check(InputMap.has_action(action), "input action exists: " + action)
	TestEconomy.run(self)
	TestService.run(self)
	print("== %d checks, %d failures ==" % [checks, failures])
	quit(0 if failures == 0 else 1)


func check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("  ok   ", message)
	else:
		failures += 1
		printerr("  FAIL ", message)


func eq(actual, expected, message: String) -> void:
	check(actual == expected, "%s — got %s, expected %s" % [message, actual, expected])
