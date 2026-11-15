class_name HealthBar
extends Node3D
## A small flat health bar that floats above a tank and does not rotate with it.

const WIDTH: float = 1.2

var tank: Tank = null
var _fill: MeshInstance3D


func _ready() -> void:
	top_level = true
	_make_bar(Vector3(WIDTH + 0.08, 0.02, 0.2), Color(0.0, 0.0, 0.0), 0.0)
	_fill = _make_bar(Vector3(WIDTH, 0.02, 0.13), Color(0.9, 0.25, 0.2), 0.03)


func _process(_delta: float) -> void:
	if tank == null or not is_instance_valid(tank):
		return
	# "Above" on screen is -Z, since the camera looks straight down.
	global_position = tank.global_position + Vector3(0.0, 1.6, -1.1)
	global_rotation = Vector3.ZERO
	var ratio: float = clampf(float(tank.health) / float(maxi(tank.max_health, 1)), 0.0, 1.0)
	_fill.scale.x = maxf(ratio, 0.001)
	_fill.position.x = -WIDTH * 0.5 * (1.0 - ratio)


func _make_bar(size: Vector3, color: Color, height: float) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	inst.material_override = mat
	inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	inst.position.y = height
	add_child(inst)
	return inst
