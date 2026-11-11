extends TestCase
## Tests for the borg-feed pixel snapping math.

const PIXEL := 7.0 / 360.0


func _iso_basis() -> Basis:
	return Basis.from_euler(Vector3(deg_to_rad(-30.0), deg_to_rad(45.0), 0.0))


func test_snapped_point_lands_on_pixel_grid() -> void:
	var b := _iso_basis()
	var snapped_pos := PixelSnap.snap(Vector3(3.217, 0.5, 1.093), b, PIXEL)
	var local: Vector3 = b.transposed() * snapped_pos
	check(is_zero_approx(fmod(absf(local.x) + PIXEL * 0.5, PIXEL) - PIXEL * 0.5), "x not on pixel grid")
	check(is_zero_approx(fmod(absf(local.y) + PIXEL * 0.5, PIXEL) - PIXEL * 0.5), "y not on pixel grid")


func test_snap_moves_less_than_one_pixel() -> void:
	var original := Vector3(-2.5, 0.0, 4.41)
	var snapped_pos := PixelSnap.snap(original, _iso_basis(), PIXEL)
	check(snapped_pos.distance_to(original) <= PIXEL, "snap moved the point too far")


func test_snapping_twice_changes_nothing() -> void:
	var b := _iso_basis()
	var once := PixelSnap.snap(Vector3(1.111, 0.2, 2.222), b, PIXEL)
	check(once.is_equal_approx(PixelSnap.snap(once, b, PIXEL)), "snap is not stable")
