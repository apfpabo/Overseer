extends TestCase
## Smoke tests: prove the test runner works. Real law-system tests go in
## test_law_system.gd once milestone M1.6 starts.


func test_palette_colors_differ() -> void:
	check(Palette.DOOR_OPEN != Palette.DOOR_CLOSED, "door colors must be distinguishable")


func test_math_still_works() -> void:
	check_eq(2 + 2, 4)
