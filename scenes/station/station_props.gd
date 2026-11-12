class_name StationProps
extends RefCounted
## Furniture and clutter for the M1 test rooms, built from boxes. Each builder
## returns the floor footprints (x, z) that crew and borgs must walk around.
## Moves to room data files in M4.


## Engineering (x 0..5, z 0..5): console, pipes, crates, floor vent, sign.
static func build_engineering(parent: Node3D) -> Array[Rect2]:
	# Console with a glowing, tilted screen against the back wall.
	BoxBuilder.box(parent, Vector3(1.2, 0.8, 0.5), Vector3(2.5, 0.4, 0.4), Palette.CONSOLE)
	var screen := BoxBuilder.glow_box(parent, Vector3(1.0, 0.45, 0.05), Vector3(2.5, 1.05, 0.3), Palette.SCREEN_GLOW, 0.8)
	screen.rotation.x = deg_to_rad(-15.0)

	# Two pipes along the left wall, dropping into the floor at the far end.
	BoxBuilder.box(parent, Vector3(0.14, 0.14, 4.3), Vector3(0.2, 1.15, 2.6), Palette.PIPE)
	BoxBuilder.box(parent, Vector3(0.1, 0.1, 4.3), Vector3(0.2, 0.85, 2.6), Palette.PIPE.darkened(0.25))
	BoxBuilder.box(parent, Vector3(0.14, 1.15, 0.14), Vector3(0.2, 0.575, 4.68), Palette.PIPE)
	BoxBuilder.box(parent, Vector3(0.2, 0.2, 0.12), Vector3(0.2, 1.15, 1.6), Palette.PIPE_VALVE)

	# A stack of crates in the back-right corner.
	_crate(parent, Vector3(4.3, 0.0, 0.55), 0.62, 0.0)
	_crate(parent, Vector3(4.3, 0.62, 0.55), 0.46, 0.35)
	_crate(parent, Vector3(3.55, 0.0, 0.45), 0.42, -0.2)

	# Floor vent with dark slats.
	BoxBuilder.box(parent, Vector3(0.9, 0.02, 0.6), Vector3(1.3, 0.01, 3.9), Palette.VENT)
	for i in 4:
		BoxBuilder.box(parent, Vector3(0.8, 0.03, 0.06), Vector3(1.3, 0.015, 3.68 + i * 0.15), Palette.SIGN_DARK)

	# Hazard sign on the back wall.
	_hazard_sign(parent, Vector3(0.95, 1.2, 0.12))

	_door_stripes(parent, 4.55)
	return [
		Rect2(1.9, 0.15, 1.2, 0.5),   # console
		Rect2(3.3, 0.2, 1.4, 0.7),    # crates
	]


## Medbay (x 5..10, z 0..5): bed, medicine cabinet, IV stand, cross sign.
static func build_medbay(parent: Node3D) -> Array[Rect2]:
	# Bed with a blue sheet and a pillow.
	BoxBuilder.box(parent, Vector3(0.9, 0.45, 1.9), Vector3(8.6, 0.225, 1.25), Palette.BED)
	BoxBuilder.box(parent, Vector3(0.92, 0.06, 1.2), Vector3(8.6, 0.48, 1.55), Palette.BED_SHEET)
	BoxBuilder.box(parent, Vector3(0.6, 0.12, 0.35), Vector3(8.6, 0.51, 0.5), Palette.BED)

	# IV stand by the bed: base, pole, glowing drip bag.
	BoxBuilder.box(parent, Vector3(0.3, 0.05, 0.3), Vector3(7.85, 0.025, 0.7), Palette.PIPE)
	BoxBuilder.box(parent, Vector3(0.05, 1.3, 0.05), Vector3(7.85, 0.65, 0.7), Palette.PIPE)
	BoxBuilder.glow_box(parent, Vector3(0.16, 0.22, 0.08), Vector3(7.85, 1.2, 0.76), Palette.IV_BAG, 0.6)

	# Medicine cabinet with a red cross, against the back wall.
	BoxBuilder.box(parent, Vector3(0.8, 1.1, 0.4), Vector3(6.4, 0.55, 0.3), Palette.CABINET)
	BoxBuilder.box(parent, Vector3(0.02, 1.0, 0.02), Vector3(6.4, 0.55, 0.51), Palette.CABINET.darkened(0.3))
	_cross(parent, Vector3(6.4, 0.85, 0.51), 0.3)

	# Medbay sign: white plate with a red cross.
	BoxBuilder.box(parent, Vector3(0.5, 0.5, 0.04), Vector3(9.45, 1.15, 0.12), Palette.CABINET)
	_cross(parent, Vector3(9.45, 1.15, 0.15), 0.34)

	_door_stripes(parent, 5.45)
	return [
		Rect2(8.15, 0.3, 0.9, 1.9),   # bed
		Rect2(7.7, 0.55, 0.3, 0.3),   # IV stand
		Rect2(6.0, 0.1, 0.8, 0.4),    # cabinet
	]


## A wooden crate of `edge` meters, sitting on `base`, turned by `yaw` radians.
static func _crate(parent: Node3D, base: Vector3, edge: float, yaw: float) -> void:
	var crate := Node3D.new()
	crate.position = base
	crate.rotation.y = yaw
	parent.add_child(crate)
	BoxBuilder.box(crate, Vector3(edge, edge, edge), Vector3(0.0, edge * 0.5, 0.0), Palette.CRATE)
	BoxBuilder.box(crate, Vector3(edge + 0.02, 0.06, edge + 0.02), Vector3(0.0, edge * 0.8, 0.0), Palette.CRATE_BAND)
	BoxBuilder.box(crate, Vector3(edge + 0.02, 0.06, edge + 0.02), Vector3(0.0, edge * 0.2, 0.0), Palette.CRATE_BAND)


## Yellow plate with two dark bars, on a wall facing +Z.
static func _hazard_sign(parent: Node3D, center: Vector3) -> void:
	BoxBuilder.box(parent, Vector3(0.6, 0.32, 0.04), center, Palette.HAZARD_STRIPE)
	for offset: float in [-0.15, 0.05]:
		var bar := BoxBuilder.box(parent, Vector3(0.08, 0.4, 0.05), center + Vector3(offset + 0.05, 0.0, 0.01), Palette.SIGN_DARK)
		bar.rotation.z = deg_to_rad(35.0)
		bar.scale = Vector3(1.0, 0.75, 1.0)


## A red cross facing +Z, `size` meters across.
static func _cross(parent: Node3D, center: Vector3, size: float) -> void:
	BoxBuilder.box(parent, Vector3(size, size * 0.32, 0.03), center, Palette.MED_CROSS)
	BoxBuilder.box(parent, Vector3(size * 0.32, size, 0.03), center, Palette.MED_CROSS)


## Yellow/black floor stripes in front of the door (z 2..3), on one side.
static func _door_stripes(parent: Node3D, x: float) -> void:
	for i in 5:
		var color: Color = Palette.HAZARD_STRIPE if i % 2 == 0 else Palette.SIGN_DARK
		BoxBuilder.box(parent, Vector3(0.3, 0.012, 0.2), Vector3(x, 0.006, 2.1 + i * 0.2), color)
