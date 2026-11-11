class_name TestCase
extends RefCounted
## Base class for tests. Extend it in tests/test_*.gd files and write funcs
## named test_something(). Use check()/check_eq() to record failures.


func check(condition: bool, message: String = "check failed") -> void:
	if not condition:
		_record(message)


func check_eq(actual: Variant, expected: Variant, message: String = "") -> void:
	if actual != expected:
		_record("%sexpected %s, got %s" % [message + ": " if message else "", expected, actual])


func _record(message: String) -> void:
	var errors: PackedStringArray = get_meta(&"errors", PackedStringArray())
	errors.append(message)
	set_meta(&"errors", errors)
