extends SceneTree
## Minimal test runner. Run with:
##   godot --headless -s res://tests/run_tests.gd
## Loads every tests/test_*.gd, calls each func named test_*, prints results,
## and exits with code 1 if anything failed.
##
## In a test, call `fail("message")` (or use the `check` helper) to report a failure.

const TEST_DIR := "res://tests/"

var _failures: int = 0
var _passes: int = 0


func _initialize() -> void:
	for file_name in DirAccess.get_files_at(TEST_DIR):
		if file_name.begins_with("test_") and file_name.ends_with(".gd"):
			_run_file(TEST_DIR + file_name)
	print("\n%d passed, %d failed" % [_passes, _failures])
	quit(1 if _failures > 0 else 0)


func _run_file(path: String) -> void:
	var script: GDScript = load(path)
	for method in script.get_script_method_list():
		var method_name: String = method["name"]
		if not method_name.begins_with("test_"):
			continue
		var suite: Object = script.new()
		suite.set_meta(&"errors", PackedStringArray())
		suite.call(method_name)
		var errors: PackedStringArray = suite.get_meta(&"errors")
		if errors.is_empty():
			_passes += 1
			print("PASS  %s :: %s" % [path.get_file(), method_name])
		else:
			_failures += 1
			print("FAIL  %s :: %s\n      %s" % [path.get_file(), method_name, "\n      ".join(errors)])
		if suite is RefCounted:
			suite = null
		elif is_instance_valid(suite):
			suite.free()
