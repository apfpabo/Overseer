class_name Explosion
extends Node3D
## A short expanding fireball with a flash of light, used for shots, hits
## and destroyed tanks.

const DURATION: float = 0.35

var radius: float = 0.5
var color: Color = Color.ORANGE
var _age: float = 0.0
var _outer: MeshInstance3D
var _inner: MeshInstance3D
var _outer_mat: StandardMaterial3D
var _inner_mat: StandardMaterial3D
var _light: OmniLight3D


static func spawn(parent: Node, at: Vector3, size: float, tint: Color) -> void:
	if parent == null:
		return
	var boom := Explosion.new()
	boom.position = at
	boom.radius = size
	boom.color = tint
	parent.add_child(boom)


func _ready() -> void:
	_outer_mat = _fade_material(color)
	_inner_mat = _fade_material(Color(1.0, 1.0, 0.85))
	_outer = _sphere(_outer_mat)
	_inner = _sphere(_inner_mat)
	if radius >= 0.8:
		_light = OmniLight3D.new()
		_light.light_color = color
		_light.omni_range = radius * 4.0
		_light.light_energy = 3.0
		add_child(_light)
	_update_look()


func _process(delta: float) -> void:
	_age += delta
	if _age >= DURATION:
		queue_free()
		return
	_update_look()


func _update_look() -> void:
	var t: float = _age / DURATION
	var r: float = radius * (0.4 + 0.6 * t)
	_outer.scale = Vector3.ONE * r
	_inner.scale = Vector3.ONE * r * 0.5
	_outer_mat.albedo_color.a = 1.0 - t
	_inner_mat.albedo_color.a = 1.0 - t
	if _light != null:
		_light.light_energy = 3.0 * (1.0 - t)


func _sphere(mat: Material) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	mesh.radial_segments = 16
	mesh.rings = 8
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	inst.material_override = mat
	inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(inst)
	return inst


static func _fade_material(tint: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return mat
