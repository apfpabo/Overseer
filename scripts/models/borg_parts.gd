class_name BorgParts
extends RefCounted
## Box builders for every cyborg part listed in BorgModule (chassis, heads,
## tools, backpacks, toppers, chest emblems). All face +Z. Parts that animate
## register themselves on the BorgModel being built.
## Frame: chassis up to y 0.3, chest y 0.5-0.75, hands at y 0.47 z 0.18,
## head node at y 0.8.

const HAND_Y := 0.47
const HAND_Z := 0.18
const ARM_X := 0.33


# --- Chassis ---------------------------------------------------------------

static func chassis(model: BorgModel, m: BorgModule) -> void:
	match m.chassis:
		BorgModule.Chassis.TREADS:
			for side: float in [-1.0, 1.0]:
				BoxBuilder.box(model, Vector3(0.16, 0.2, 0.66), Vector3(side * 0.25, 0.1, 0.0), Palette.BORG_TRACKS)
				for z: float in [-0.2, 0.2]:
					BoxBuilder.box(model, Vector3(0.04, 0.12, 0.12), Vector3(side * 0.34, 0.1, z), Palette.BORG_DARK)
				BoxBuilder.glow_box(model, Vector3(0.03, 0.04, 0.5), Vector3(side * 0.345, 0.2, 0.0), m.color, 0.9)
			BoxBuilder.box(model, Vector3(0.42, 0.1, 0.52), Vector3(0.0, 0.24, 0.0), Palette.BORG_DARK)
		BorgModule.Chassis.HOVER:
			BoxBuilder.box(model, Vector3(0.42, 0.1, 0.46), Vector3(0.0, 0.26, 0.0), m.body_color)
			BoxBuilder.box(model, Vector3(0.52, 0.06, 0.56), Vector3(0.0, 0.19, 0.0), m.plate_color)
			BoxBuilder.glow_box(model, Vector3(0.42, 0.02, 0.46), Vector3(0.0, 0.15, 0.0), m.color, 1.5)
			var glow := OmniLight3D.new()
			glow.position = Vector3(0.0, 0.1, 0.0)
			glow.light_color = m.color
			glow.light_energy = 1.2
			glow.omni_range = 1.0
			model.add_child(glow)
			model.hovers = true
		BorgModule.Chassis.LEGS:
			# Reverse-knee ("digitigrade") legs: thigh forward, shin back, claws.
			BoxBuilder.box(model, Vector3(0.3, 0.1, 0.24), Vector3(0.0, 0.34, 0.0), Palette.BORG_DARK)
			for side: float in [-1.0, 1.0]:
				var leg := Node3D.new()
				leg.position = Vector3(side * 0.13, 0.34, 0.0)
				model.add_child(leg)
				var thigh := BoxBuilder.box(leg, Vector3(0.08, 0.2, 0.09), Vector3(0.0, -0.08, 0.06), m.plate_color)
				thigh.rotation.x = deg_to_rad(-35.0)
				var shin := BoxBuilder.box(leg, Vector3(0.07, 0.2, 0.07), Vector3(0.0, -0.24, 0.05), Palette.BORG_DARK)
				shin.rotation.x = deg_to_rad(30.0)
				BoxBuilder.box(leg, Vector3(0.1, 0.04, 0.16), Vector3(0.0, -0.32, 0.04), m.body_color)
				for toe: float in [-0.03, 0.03]:
					BoxBuilder.box(leg, Vector3(0.03, 0.03, 0.07), Vector3(toe, -0.325, 0.14), m.plate_color)
				model.legs.append(leg)
		BorgModule.Chassis.WHEELS:
			BoxBuilder.box(model, Vector3(0.42, 0.12, 0.5), Vector3(0.0, 0.24, 0.0), Palette.BORG_DARK)
			for side: float in [-1.0, 1.0]:
				for z: float in [-0.17, 0.17]:
					var wheel := Node3D.new()
					wheel.position = Vector3(side * 0.26, 0.11, z)
					model.add_child(wheel)
					# Two boxes turned 45 degrees make a chunky octagon.
					BoxBuilder.box(wheel, Vector3(0.09, 0.2, 0.2), Vector3.ZERO, Palette.BORG_TRACKS)
					var turned := BoxBuilder.box(wheel, Vector3(0.09, 0.2, 0.2), Vector3.ZERO, Palette.BORG_TRACKS)
					turned.rotation.x = PI * 0.25
					BoxBuilder.box(wheel, Vector3(0.02, 0.08, 0.08), Vector3(side * 0.05, 0.0, 0.0), m.color)
					model.wheels.append(wheel)


# --- Heads (built on the head node) ----------------------------------------

static func head(model: BorgModel, m: BorgModule, h: Node3D) -> void:
	BoxBuilder.box(h, Vector3(0.12, 0.06, 0.12), Vector3(0.0, 0.03, 0.0), Palette.BORG_DARK)
	match m.head:
		BorgModule.Head.VISOR:
			BoxBuilder.box(h, Vector3(0.34, 0.2, 0.3), Vector3(0.0, 0.15, 0.0), m.plate_color)
			BoxBuilder.box(h, Vector3(0.36, 0.05, 0.32), Vector3(0.0, 0.25, -0.01), m.color)
			BoxBuilder.box(h, Vector3(0.3, 0.09, 0.03), Vector3(0.0, 0.14, 0.155), Palette.BORG_DARK)
			BoxBuilder.glow_box(h, Vector3(0.26, 0.04, 0.02), Vector3(0.0, 0.14, 0.17), m.eye_color, 1.2)
			model.scanner = BoxBuilder.glow_box(h, Vector3(0.06, 0.05, 0.02), Vector3(0.0, 0.14, 0.18), Palette.BORG_SCANNER, 2.0)
			for side: float in [-1.0, 1.0]:
				BoxBuilder.box(h, Vector3(0.05, 0.1, 0.14), Vector3(side * 0.195, 0.14, 0.0), Palette.BORG_DARK)
		BorgModule.Head.DOME:
			BoxBuilder.box(h, Vector3(0.32, 0.16, 0.3), Vector3(0.0, 0.13, 0.0), m.plate_color)
			BoxBuilder.box(h, Vector3(0.33, 0.03, 0.31), Vector3(0.0, 0.2, 0.0), m.color)
			BoxBuilder.box(h, Vector3(0.26, 0.08, 0.24), Vector3(0.0, 0.25, 0.0), m.plate_color)
			BoxBuilder.box(h, Vector3(0.16, 0.04, 0.14), Vector3(0.0, 0.31, 0.0), m.plate_color)
			BoxBuilder.box(h, Vector3(0.14, 0.12, 0.03), Vector3(0.0, 0.13, 0.155), Palette.BORG_DARK)
			model.pulse(BoxBuilder.glow_box(h, Vector3(0.09, 0.08, 0.02), Vector3(0.0, 0.13, 0.17), m.eye_color, 1.2))
		BorgModule.Head.SLIT:
			BoxBuilder.box(h, Vector3(0.4, 0.16, 0.32), Vector3(0.0, 0.12, 0.0), m.plate_color)
			BoxBuilder.box(h, Vector3(0.42, 0.05, 0.14), Vector3(0.0, 0.215, 0.11), m.body_color)
			BoxBuilder.box(h, Vector3(0.3, 0.05, 0.1), Vector3(0.0, 0.04, 0.12), Palette.BORG_DARK)
			BoxBuilder.box(h, Vector3(0.32, 0.06, 0.03), Vector3(0.0, 0.13, 0.165), Palette.BORG_DARK)
			BoxBuilder.glow_box(h, Vector3(0.28, 0.025, 0.02), Vector3(0.0, 0.13, 0.175), m.eye_color, 1.2)
			model.scanner = BoxBuilder.glow_box(h, Vector3(0.06, 0.035, 0.02), Vector3(0.0, 0.13, 0.185), m.eye_color.lightened(0.6), 2.5)
		BorgModule.Head.EYE:
			BoxBuilder.box(h, Vector3(0.24, 0.26, 0.26), Vector3(0.0, 0.16, 0.0), m.plate_color)
			BoxBuilder.box(h, Vector3(0.2, 0.14, 0.03), Vector3(0.0, 0.13, 0.14), Palette.BORG_DARK)
			for side: float in [-1.0, 1.0]:
				BoxBuilder.box(h, Vector3(0.03, 0.18, 0.2), Vector3(side * 0.135, 0.17, -0.02), Palette.BORG_DARK)
			model.pulse(BoxBuilder.glow_box(h, Vector3(0.06, 0.06, 0.02), Vector3(0.0, 0.17, 0.155), m.eye_color, 2.0))
		BorgModule.Head.TWIN_EYES:
			BoxBuilder.box(h, Vector3(0.34, 0.22, 0.3), Vector3(0.0, 0.15, 0.0), m.plate_color)
			BoxBuilder.box(h, Vector3(0.36, 0.04, 0.32), Vector3(0.0, 0.27, 0.0), m.color)
			BoxBuilder.box(h, Vector3(0.28, 0.14, 0.03), Vector3(0.0, 0.14, 0.155), Palette.BORG_DARK)
			var left_eye := BoxBuilder.glow_box(h, Vector3(0.06, 0.07, 0.02), Vector3(-0.07, 0.15, 0.17), m.eye_color, 1.4)
			var right_eye := BoxBuilder.glow_box(h, Vector3(0.06, 0.07, 0.02), Vector3(0.07, 0.15, 0.17), m.eye_color, 1.4)
			right_eye.material_override = left_eye.material_override
			# A friendly blink every few seconds.
			model.blink(left_eye, 3.2, 0.94, 0.0, 1.4, 0.0)
		BorgModule.Head.NVG:
			# Narrow helmet with a quad-tube night-vision mount: four green lenses.
			BoxBuilder.box(h, Vector3(0.24, 0.16, 0.26), Vector3(0.0, 0.13, 0.0), m.plate_color)
			BoxBuilder.box(h, Vector3(0.2, 0.05, 0.22), Vector3(0.0, 0.23, -0.01), m.body_color)
			BoxBuilder.box(h, Vector3(0.26, 0.12, 0.08), Vector3(0.0, 0.12, -0.13), Palette.BORG_DARK)
			BoxBuilder.box(h, Vector3(0.16, 0.06, 0.1), Vector3(0.0, 0.04, 0.09), Palette.BORG_DARK)
			BoxBuilder.box(h, Vector3(0.28, 0.06, 0.08), Vector3(0.0, 0.22, 0.14), Palette.BORG_DARK)
			var lens_material: StandardMaterial3D
			# Inner tubes look straight ahead; outer tubes splay outward.
			for tube_x: float in [-0.115, -0.04, 0.04, 0.115]:
				var tube := Node3D.new()
				tube.position = Vector3(tube_x, 0.18, 0.15)
				# Tilted up a little so the lenses face the camera above.
				tube.rotation.x = -0.2
				if absf(tube_x) > 0.05:
					tube.rotation.y = signf(tube_x) * 0.3
				h.add_child(tube)
				BoxBuilder.box(tube, Vector3(0.065, 0.065, 0.12), Vector3(0.0, 0.0, 0.06), Palette.BORG_DARK)
				var lens := BoxBuilder.glow_box(tube, Vector3(0.05, 0.05, 0.02), Vector3(0.0, 0.0, 0.125), m.eye_color, 2.4)
				if lens_material == null:
					lens_material = lens.material_override
					# A rare, quick flicker, like the tubes re-gaining.
					model.blink(lens, 4.1, 0.96, 0.0, 2.4, 0.7)
				else:
					lens.material_override = lens_material


# --- Toppers (on the head node) --------------------------------------------

static func topper(model: BorgModel, m: BorgModule, h: Node3D) -> void:
	var top: float = 0.34 if m.head == BorgModule.Head.DOME else 0.3
	match m.topper:
		BorgModule.Topper.ANTENNA:
			BoxBuilder.box(h, Vector3(0.03, 0.2, 0.03), Vector3(0.12, top + 0.05, -0.08), Palette.BORG_DARK)
			model.blink(BoxBuilder.glow_box(h, Vector3(0.05, 0.05, 0.05), Vector3(0.12, top + 0.16, -0.08), m.glow_color, 2.0), 1.2, 0.15, 0.0, 2.0, 0.2)
		BorgModule.Topper.SIREN:
			BoxBuilder.box(h, Vector3(0.26, 0.03, 0.12), Vector3(0.0, top - 0.06, 0.0), Palette.BORG_DARK)
			model.blink(BoxBuilder.glow_box(h, Vector3(0.1, 0.07, 0.1), Vector3(-0.07, top - 0.01, 0.0), m.color, 2.5), 0.5, 0.5, 0.0, 2.5, 0.15)
			model.blink(BoxBuilder.glow_box(h, Vector3(0.1, 0.07, 0.1), Vector3(0.07, top - 0.01, 0.0), m.glow_color, 2.5), 0.5, 0.5, 0.25, 2.5, 0.15)


# --- Chest emblems ---------------------------------------------------------

static func emblem(model: BorgModel, m: BorgModule) -> void:
	match m.emblem:
		BorgModule.Emblem.CORE:
			BoxBuilder.box(model, Vector3(0.3, 0.18, 0.03), Vector3(0.0, 0.63, 0.22), Palette.BORG_DARK)
			model.pulse(BoxBuilder.glow_box(model, Vector3(0.1, 0.1, 0.03), Vector3(0.0, 0.63, 0.235), Palette.BORG_CORE, 1.0))
			for side: float in [-1.0, 1.0]:
				BoxBuilder.box(model, Vector3(0.06, 0.04, 0.03), Vector3(side * 0.1, 0.67, 0.235), m.color)
		BorgModule.Emblem.CROSS:
			BoxBuilder.box(model, Vector3(0.24, 0.2, 0.03), Vector3(0.0, 0.63, 0.22), Palette.CABINET)
			BoxBuilder.box(model, Vector3(0.16, 0.05, 0.03), Vector3(0.0, 0.63, 0.235), Palette.MED_CROSS)
			BoxBuilder.box(model, Vector3(0.05, 0.16, 0.03), Vector3(0.0, 0.63, 0.235), Palette.MED_CROSS)
		BorgModule.Emblem.SEAMS:
			# Faint circuit seams: a thin V across the chest, kept dim for stealth.
			var front: float = 0.17 if m.frame == BorgModule.Frame.SLEEK else 0.215
			for side: float in [-1.0, 1.0]:
				var seam := BoxBuilder.glow_box(model, Vector3(0.025, 0.16, 0.01), Vector3(side * 0.07, 0.67, front), m.eye_color, 0.5)
				seam.rotation.z = deg_to_rad(side * 35.0)
		BorgModule.Emblem.STRIPES:
			BoxBuilder.box(model, Vector3(0.32, 0.16, 0.03), Vector3(0.0, 0.63, 0.22), Palette.SIGN_DARK)
			for i in 3:
				var bar := BoxBuilder.box(model, Vector3(0.05, 0.2, 0.03), Vector3(-0.09 + i * 0.09, 0.63, 0.23), Palette.HAZARD_STRIPE)
				bar.rotation.z = deg_to_rad(35.0)
				bar.scale = Vector3(1.0, 0.75, 1.0)


# --- Backpacks -------------------------------------------------------------

static func back(model: BorgModel, m: BorgModule) -> void:
	match m.back:
		BorgModule.Back.VENTS:
			BoxBuilder.box(model, Vector3(0.34, 0.3, 0.14), Vector3(0.0, 0.62, -0.27), m.body_color)
			for i in 3:
				BoxBuilder.glow_box(model, Vector3(0.24, 0.03, 0.02), Vector3(0.0, 0.54 + i * 0.07, -0.345), m.color, 0.8)
		BorgModule.Back.CANISTER:
			BoxBuilder.box(model, Vector3(0.2, 0.34, 0.14), Vector3(0.0, 0.64, -0.28), Palette.BORG_DARK)
			model.pulse(BoxBuilder.glow_box(model, Vector3(0.14, 0.26, 0.02), Vector3(0.0, 0.63, -0.355), m.glow_color, 1.0))
			BoxBuilder.box(model, Vector3(0.22, 0.04, 0.16), Vector3(0.0, 0.83, -0.28), m.plate_color)
		BorgModule.Back.BUCKET:
			BoxBuilder.box(model, Vector3(0.28, 0.2, 0.22), Vector3(0.0, 0.56, -0.32), m.plate_color.darkened(0.25))
			BoxBuilder.glow_box(model, Vector3(0.24, 0.02, 0.18), Vector3(0.0, 0.665, -0.32), m.glow_color, 0.8)
			BoxBuilder.box(model, Vector3(0.3, 0.03, 0.03), Vector3(0.0, 0.73, -0.32), Palette.BORG_DARK)
		BorgModule.Back.CLOAK:
			# Tattered stealth cloak: strips that hang from the shoulders and sway.
			var lengths: Array[float] = [0.66, 0.74, 0.7, 0.62]
			for i in lengths.size():
				var strip := Node3D.new()
				strip.position = Vector3(-0.135 + i * 0.09, 0.79, -0.19)
				model.add_child(strip)
				# Narrow strips with gaps and uneven lengths read as torn cloth.
				BoxBuilder.box(strip, Vector3(0.075, lengths[i], 0.025), Vector3(0.0, -lengths[i] * 0.5, 0.0), Palette.CLOAK)
				model.capes.append(strip)
			BoxBuilder.box(model, Vector3(0.38, 0.05, 0.1), Vector3(0.0, 0.8, -0.16), Palette.CLOAK)
			_shoulder_cannon(model, m)
		BorgModule.Back.SHOULDER_GUN:
			BoxBuilder.box(model, Vector3(0.26, 0.24, 0.1), Vector3(0.0, 0.62, -0.25), Palette.BORG_DARK)
			BoxBuilder.box(model, Vector3(0.1, 0.08, 0.1), Vector3(0.3, 0.84, -0.05), Palette.BORG_DARK)
			BoxBuilder.box(model, Vector3(0.08, 0.08, 0.34), Vector3(0.3, 0.9, 0.08), m.body_color)
			model.pulse(BoxBuilder.glow_box(model, Vector3(0.06, 0.06, 0.02), Vector3(0.3, 0.9, 0.26), m.eye_color, 1.5))


## Compact cannon tucked on the right shoulder; just a small green muzzle light.
static func _shoulder_cannon(model: BorgModel, m: BorgModule) -> void:
	BoxBuilder.box(model, Vector3(0.09, 0.07, 0.12), Vector3(0.22, 0.83, -0.06), Palette.BORG_DARK)
	BoxBuilder.box(model, Vector3(0.07, 0.07, 0.32), Vector3(0.22, 0.88, 0.05), m.body_color)
	model.pulse(BoxBuilder.glow_box(model, Vector3(0.045, 0.045, 0.02), Vector3(0.22, 0.88, 0.215), m.eye_color, 1.2))
