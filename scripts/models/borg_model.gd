class_name BorgModel
extends Node3D
## A cyborg made of boxes, facing +Z: tracks, boxy body, head with a glowing
## eye. The module color marks its job (security, medical, engineering).


## Builds the model. Call once, right after creating it.
func build(module_color: Color) -> void:
	for side: float in [-1.0, 1.0]:
		BoxBuilder.box(self, Vector3(0.14, 0.18, 0.62), Vector3(side * 0.24, 0.09, 0.0), Palette.BORG_TRACKS)
	BoxBuilder.box(self, Vector3(0.44, 0.46, 0.48), Vector3(0.0, 0.42, 0.0), Palette.BORG_BODY)
	BoxBuilder.box(self, Vector3(0.46, 0.10, 0.50), Vector3(0.0, 0.52, 0.0), module_color)
	BoxBuilder.box(self, Vector3(0.10, 0.30, 0.12), Vector3(-0.28, 0.45, 0.04), Palette.BORG_BODY)
	BoxBuilder.box(self, Vector3(0.10, 0.30, 0.12), Vector3(0.28, 0.45, 0.04), Palette.BORG_BODY)
	BoxBuilder.box(self, Vector3(0.30, 0.24, 0.28), Vector3(0.0, 0.79, 0.0), Palette.BORG_BODY)
	BoxBuilder.glow_box(self, Vector3(0.20, 0.06, 0.04), Vector3(0.0, 0.81, 0.15), module_color, 1.2)
