class_name PixelSnap
extends RefCounted
## Math for keeping a moving orthographic camera locked to whole screen pixels,
## so borg feeds don't shimmer (see docs/ARCHITECTURE.md -> Rendering).


## Returns `world_pos` moved so that, seen through a camera with `cam_basis`,
## it sits exactly on the grid of screen pixels (`pixel_size` meters wide).
static func snap(world_pos: Vector3, cam_basis: Basis, pixel_size: float) -> Vector3:
	if pixel_size <= 0.0:
		return world_pos
	var local: Vector3 = cam_basis.transposed() * world_pos
	local.x = snappedf(local.x, pixel_size)
	local.y = snappedf(local.y, pixel_size)
	return cam_basis * local


## Size of one screen pixel in meters for an orthographic camera.
## `view_height` is Camera3D.size, `pixel_rows` the viewport height (360).
static func pixel_size_for(view_height: float, pixel_rows: int) -> float:
	return view_height / float(pixel_rows)
