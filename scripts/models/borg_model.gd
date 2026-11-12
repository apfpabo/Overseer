class_name BorgModel
extends Node3D
## A cyborg assembled from the parts its BorgModule lists (see
## scripts/models/borg_parts.gd), facing +Z, ~1.2 m tall before the module's
## size. Shared frame: waist, armored chest, shoulder plates in the module
## color, two arms; the module picks chassis, head, tools, backpack, topper
## and chest emblem. Handles the idle animations parts ask for.

const SCANNER_SWEEP := 0.1
const HEAD_SWAY_RADIANS := 0.25
const LEG_SWING_DEGREES := 30.0

## Filled in by BorgParts while building.
var scanner: MeshInstance3D
var legs: Array[Node3D] = []
var wheels: Array[Node3D] = []
## Cloak strips that sway (and flutter back while moving).
var capes: Array[Node3D] = []
var hovers: bool = false

var _head: Node3D
## Each: { "material", "period", "on_fraction", "phase", "on", "off" }.
var _blinkers: Array[Dictionary] = []
var _pulses: Array[StandardMaterial3D] = []
var _time: float = 0.0
var _motion: float = 0.0
var _stride: float = 0.0


## Builds the model for `module`. Call once, right after creating it.
func build(module: BorgModule) -> void:
	scale = module.size
	BorgParts.chassis(self, module)
	# Shared frame: narrow waist, wide armored chest, shoulder plates, arms.
	BoxBuilder.box(self, Vector3(0.36, 0.2, 0.36), Vector3(0.0, 0.39, 0.0), module.body_color)
	BoxBuilder.box(self, Vector3(0.52, 0.26, 0.42), Vector3(0.0, 0.62, 0.0), module.plate_color)
	BoxBuilder.box(self, Vector3(0.54, 0.05, 0.44), Vector3(0.0, 0.5, 0.0), Palette.BORG_DARK)
	for side: float in [-1.0, 1.0]:
		var shoulder: Color = module.color if module.shoulder_color.a == 0.0 else module.shoulder_color
		BoxBuilder.box(self, Vector3(0.16, 0.1, 0.3), Vector3(side * 0.32, 0.76, 0.0), shoulder)
		BoxBuilder.box(self, Vector3(0.1, 0.22, 0.12), Vector3(side * 0.33, 0.6, 0.02), Palette.BORG_DARK)
		BoxBuilder.box(self, Vector3(0.12, 0.08, 0.2), Vector3(side * 0.33, 0.47, 0.08), module.body_color)
	BorgParts.emblem(self, module)
	BorgParts.back(self, module)
	BorgTools.build(self, module, module.right_tool, 1.0)
	BorgTools.build(self, module, module.left_tool, -1.0)
	_head = Node3D.new()
	_head.position = Vector3(0.0, 0.8, 0.0)
	add_child(_head)
	BorgParts.head(self, module, _head)
	BorgParts.topper(self, module, _head)


## 0 = standing still, 1 = driving at full speed (legs walk, wheels spin).
func set_motion(amount: float) -> void:
	_motion = amount


## Makes a glowing part blink: on for `on_fraction` of every `period` seconds.
func blink(part: MeshInstance3D, period: float, on_fraction: float, phase: float, on_energy: float, off_energy: float) -> void:
	_blinkers.append({
		"material": part.material_override, "period": period, "on_fraction": on_fraction,
		"phase": phase, "on": on_energy, "off": off_energy,
	})


## Makes a glowing part slowly breathe brighter and dimmer.
func pulse(part: MeshInstance3D) -> void:
	_pulses.append(part.material_override)


func _process(delta: float) -> void:
	_time += delta
	_head.rotation.y = sin(_time * 0.6) * HEAD_SWAY_RADIANS * (1.0 - _motion)
	if scanner != null:
		scanner.position.x = sin(_time * 3.0) * SCANNER_SWEEP
	for b: Dictionary in _blinkers:
		var t: float = fmod(_time + b["phase"], b["period"]) / b["period"]
		(b["material"] as StandardMaterial3D).emission_energy_multiplier = b["on"] if t < b["on_fraction"] else b["off"]
	for mat: StandardMaterial3D in _pulses:
		mat.emission_energy_multiplier = 1.0 + 0.5 * sin(_time * 2.5)
	_stride += delta * 8.0 * _motion
	for i in legs.size():
		legs[i].rotation.x = deg_to_rad(LEG_SWING_DEGREES) * sin(_stride + PI * i) * _motion
	for wheel: Node3D in wheels:
		wheel.rotation.x += delta * 9.0 * _motion
	for i in capes.size():
		var sway: float = sin(_time * 2.2 + i * 1.3) * (0.06 + 0.12 * _motion)
		capes[i].rotation.x = 0.08 + 0.45 * _motion + sway
	if hovers:
		position.y = 0.04 + sin(_time * 2.0) * 0.025
