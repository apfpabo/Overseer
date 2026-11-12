class_name BorgTools
extends RefCounted
## Box builders for cyborg arm tools (BorgModule.Tool), facing +Z.
## `side` is -1 for the left arm, +1 for the right. Hands are at
## (side * ARM_X, HAND_Y, HAND_Z), see BorgParts.

const HAND_Y := BorgParts.HAND_Y
const ARM_X := BorgParts.ARM_X


# --- Tools (one per arm; `side` is -1 left, +1 right) ----------------------

static func build(model: BorgModel, m: BorgModule, kind: BorgModule.Tool, side: float) -> void:
	var x: float = side * ARM_X
	match kind:
		BorgModule.Tool.WELDER:
			BoxBuilder.box(model, Vector3(0.07, 0.07, 0.14), Vector3(x, HAND_Y, 0.24), m.plate_color)
			BoxBuilder.glow_box(model, Vector3(0.05, 0.05, 0.04), Vector3(x, HAND_Y, 0.33), m.color, 1.5)
		BorgModule.Tool.CLAW:
			for offset: float in [-0.035, 0.035]:
				BoxBuilder.box(model, Vector3(0.03, 0.08, 0.14), Vector3(x + offset, HAND_Y - 0.01, 0.24), Palette.BORG_DARK)
		BorgModule.Tool.SYRINGE:
			BoxBuilder.box(model, Vector3(0.07, 0.07, 0.16), Vector3(x, HAND_Y, 0.26), m.plate_color)
			BoxBuilder.glow_box(model, Vector3(0.075, 0.03, 0.1), Vector3(x, HAND_Y, 0.26), m.glow_color, 1.0)
			BoxBuilder.box(model, Vector3(0.025, 0.025, 0.09), Vector3(x, HAND_Y, 0.385), Palette.PIPE)
		BorgModule.Tool.SCANNER:
			BoxBuilder.box(model, Vector3(0.04, 0.04, 0.1), Vector3(x, HAND_Y, 0.23), Palette.BORG_DARK)
			BoxBuilder.box(model, Vector3(0.14, 0.1, 0.03), Vector3(x, HAND_Y + 0.02, 0.29), m.plate_color)
			model.pulse(BoxBuilder.glow_box(model, Vector3(0.11, 0.07, 0.01), Vector3(x, HAND_Y + 0.02, 0.306), m.eye_color, 1.0))
		BorgModule.Tool.SHIELD:
			var sx: float = side * 0.42
			BoxBuilder.box(model, Vector3(0.05, 0.44, 0.34), Vector3(sx, 0.5, 0.2), m.plate_color.darkened(0.2))
			BoxBuilder.box(model, Vector3(0.055, 0.06, 0.34), Vector3(sx, 0.6, 0.2), m.color)
			BoxBuilder.box(model, Vector3(0.056, 0.04, 0.2), Vector3(sx, 0.67, 0.2), Palette.VISOR)
		BorgModule.Tool.BATON:
			BoxBuilder.box(model, Vector3(0.05, 0.05, 0.1), Vector3(x, HAND_Y, 0.24), Palette.BORG_DARK)
			BoxBuilder.box(model, Vector3(0.04, 0.04, 0.22), Vector3(x, HAND_Y, 0.38), m.body_color)
			model.blink(BoxBuilder.glow_box(model, Vector3(0.06, 0.06, 0.06), Vector3(x, HAND_Y, 0.5), m.glow_color, 2.0), 0.35, 0.6, 0.0, 2.5, 0.8)
		BorgModule.Tool.BLADE:
			BoxBuilder.box(model, Vector3(0.07, 0.07, 0.08), Vector3(x, HAND_Y, 0.23), Palette.BORG_DARK)
			BoxBuilder.glow_box(model, Vector3(0.02, 0.08, 0.42), Vector3(x, HAND_Y, 0.48), m.eye_color, 1.8)
		BorgModule.Tool.MOP:
			# Pole from the hand down to the floor in front: tilted 50 degrees.
			var pole := BoxBuilder.box(model, Vector3(0.03, 0.03, 0.58), Vector3(x, 0.25, 0.365), Palette.CRATE)
			pole.rotation.x = deg_to_rad(50.0)
			BoxBuilder.box(model, Vector3(0.2, 0.05, 0.1), Vector3(x, 0.03, 0.56), Palette.CABINET.darkened(0.15))
		BorgModule.Tool.TRAY:
			BoxBuilder.box(model, Vector3(0.26, 0.025, 0.2), Vector3(x - side * 0.04, HAND_Y + 0.03, 0.3), m.plate_color)
			BoxBuilder.box(model, Vector3(0.06, 0.08, 0.06), Vector3(x - side * 0.08, HAND_Y + 0.08, 0.3), Palette.CABINET)
			BoxBuilder.glow_box(model, Vector3(0.05, 0.01, 0.05), Vector3(x - side * 0.08, HAND_Y + 0.12, 0.3), m.glow_color, 0.8)
		BorgModule.Tool.FORKS:
			# Forklift mast and tines in front of the body, carrying a crate.
			for post: float in [-0.16, 0.16]:
				BoxBuilder.box(model, Vector3(0.05, 0.5, 0.05), Vector3(post, 0.3, 0.3), Palette.BORG_DARK)
				BoxBuilder.box(model, Vector3(0.06, 0.03, 0.42), Vector3(post * 0.75, 0.05, 0.5), Palette.BORG_DARK)
			BoxBuilder.box(model, Vector3(0.37, 0.05, 0.05), Vector3(0.0, 0.53, 0.3), m.color)
			BoxBuilder.box(model, Vector3(0.34, 0.3, 0.3), Vector3(0.0, 0.215, 0.52), Palette.CRATE)
			BoxBuilder.box(model, Vector3(0.36, 0.05, 0.32), Vector3(0.0, 0.3, 0.52), Palette.CRATE_BAND)
