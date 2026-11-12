class_name BorgModel
extends Node3D
## A cyborg made of boxes, facing +Z, ~1.2 m tall: treads with light strips,
## layered armor, a glowing power core, shoulder plates and back vents in the
## module color, a tool arm and a claw arm, and a head with a glowing visor,
## a sweeping scanner dot and a blinking antenna. Idles with small animations.

const SCANNER_SWEEP := 0.1
const HEAD_SWAY_RADIANS := 0.25

var _head: Node3D
var _scanner: MeshInstance3D
var _beacon: StandardMaterial3D
var _core: StandardMaterial3D
var _time: float = 0.0


## Builds the model. Call once, right after creating it.
func build(module_color: Color) -> void:
	_build_treads(module_color)
	_build_body(module_color)
	_build_arms(module_color)
	_build_head(module_color)


func _process(delta: float) -> void:
	_time += delta
	# The head slowly looks around; the scanner dot sweeps across the visor.
	_head.rotation.y = sin(_time * 0.6) * HEAD_SWAY_RADIANS
	_scanner.position.x = sin(_time * 3.0) * SCANNER_SWEEP
	# Antenna beacon blinks; power core breathes.
	_beacon.emission_energy_multiplier = 2.0 if fmod(_time, 1.2) < 0.15 else 0.2
	_core.emission_energy_multiplier = 1.0 + 0.5 * sin(_time * 2.5)


func _build_treads(module_color: Color) -> void:
	for side: float in [-1.0, 1.0]:
		BoxBuilder.box(self, Vector3(0.16, 0.2, 0.66), Vector3(side * 0.25, 0.1, 0.0), Palette.BORG_TRACKS)
		# Wheel hubs on the outside of each tread.
		for z: float in [-0.2, 0.2]:
			BoxBuilder.box(self, Vector3(0.04, 0.12, 0.12), Vector3(side * 0.34, 0.1, z), Palette.BORG_DARK)
		BoxBuilder.glow_box(self, Vector3(0.03, 0.04, 0.5), Vector3(side * 0.345, 0.2, 0.0), module_color, 0.9)
	BoxBuilder.box(self, Vector3(0.42, 0.1, 0.52), Vector3(0.0, 0.24, 0.0), Palette.BORG_DARK)


func _build_body(module_color: Color) -> void:
	# Narrow waist, wide armored chest: reads as a strong silhouette.
	BoxBuilder.box(self, Vector3(0.36, 0.2, 0.36), Vector3(0.0, 0.39, 0.0), Palette.BORG_BODY)
	BoxBuilder.box(self, Vector3(0.52, 0.26, 0.42), Vector3(0.0, 0.62, 0.0), Palette.BORG_PLATE)
	BoxBuilder.box(self, Vector3(0.54, 0.05, 0.44), Vector3(0.0, 0.5, 0.0), Palette.BORG_DARK)
	# Chest panel with a glowing power core.
	BoxBuilder.box(self, Vector3(0.3, 0.18, 0.03), Vector3(0.0, 0.63, 0.22), Palette.BORG_DARK)
	var core := BoxBuilder.glow_box(self, Vector3(0.1, 0.1, 0.03), Vector3(0.0, 0.63, 0.235), Palette.BORG_CORE, 1.0)
	_core = core.material_override
	for side: float in [-1.0, 1.0]:
		BoxBuilder.box(self, Vector3(0.06, 0.04, 0.03), Vector3(side * 0.1, 0.67, 0.235), module_color)
	# Backpack with glowing vents.
	BoxBuilder.box(self, Vector3(0.34, 0.3, 0.14), Vector3(0.0, 0.62, -0.27), Palette.BORG_BODY)
	for i in 3:
		BoxBuilder.glow_box(self, Vector3(0.24, 0.03, 0.02), Vector3(0.0, 0.54 + i * 0.07, -0.345), module_color, 0.8)
	# Shoulder plates in the module color.
	for side: float in [-1.0, 1.0]:
		BoxBuilder.box(self, Vector3(0.16, 0.1, 0.3), Vector3(side * 0.32, 0.76, 0.0), module_color)


func _build_arms(module_color: Color) -> void:
	for side: float in [-1.0, 1.0]:
		BoxBuilder.box(self, Vector3(0.1, 0.22, 0.12), Vector3(side * 0.33, 0.6, 0.02), Palette.BORG_DARK)
		BoxBuilder.box(self, Vector3(0.12, 0.08, 0.2), Vector3(side * 0.33, 0.47, 0.08), Palette.BORG_BODY)
	# Right arm: a tool with a glowing tip.
	BoxBuilder.box(self, Vector3(0.07, 0.07, 0.14), Vector3(0.33, 0.47, 0.24), Palette.BORG_PLATE)
	BoxBuilder.glow_box(self, Vector3(0.05, 0.05, 0.04), Vector3(0.33, 0.47, 0.33), module_color, 1.5)
	# Left arm: a two-pronged claw.
	for offset: float in [-0.035, 0.035]:
		BoxBuilder.box(self, Vector3(0.03, 0.08, 0.14), Vector3(-0.33 + offset, 0.46, 0.24), Palette.BORG_DARK)


func _build_head(module_color: Color) -> void:
	_head = Node3D.new()
	_head.position = Vector3(0.0, 0.8, 0.0)
	add_child(_head)
	BoxBuilder.box(_head, Vector3(0.12, 0.06, 0.12), Vector3(0.0, 0.03, 0.0), Palette.BORG_DARK)
	BoxBuilder.box(_head, Vector3(0.34, 0.2, 0.3), Vector3(0.0, 0.15, 0.0), Palette.BORG_PLATE)
	BoxBuilder.box(_head, Vector3(0.36, 0.05, 0.32), Vector3(0.0, 0.25, -0.01), module_color)
	# Visor: dark housing, glowing band, and a bright scanner dot that sweeps.
	BoxBuilder.box(_head, Vector3(0.3, 0.09, 0.03), Vector3(0.0, 0.14, 0.155), Palette.BORG_DARK)
	BoxBuilder.glow_box(_head, Vector3(0.26, 0.04, 0.02), Vector3(0.0, 0.14, 0.17), module_color, 1.2)
	_scanner = BoxBuilder.glow_box(_head, Vector3(0.06, 0.05, 0.02), Vector3(0.0, 0.14, 0.18), Palette.BORG_SCANNER, 2.0)
	# Side sensors and an antenna with a blinking beacon.
	for side: float in [-1.0, 1.0]:
		BoxBuilder.box(_head, Vector3(0.05, 0.1, 0.14), Vector3(side * 0.195, 0.14, 0.0), Palette.BORG_DARK)
	BoxBuilder.box(_head, Vector3(0.03, 0.2, 0.03), Vector3(0.12, 0.35, -0.08), Palette.BORG_DARK)
	var beacon := BoxBuilder.glow_box(_head, Vector3(0.05, 0.05, 0.05), Vector3(0.12, 0.46, -0.08), Palette.BORG_BEACON, 2.0)
	_beacon = beacon.material_override
