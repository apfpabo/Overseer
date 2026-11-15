class_name Smoke
extends MeshInstance3D
## A puff of smoke or dust that rises, grows and fades. Also makes scorch marks.

const DURATION: float = 1.4

var color: Color = Color(0.15, 0.15, 0.15)
var size: float = 1.0
var _age: float = 0.0
var _mat: StandardMaterial3D
var _drift: Vector3 = Vector3.ZERO


## `size` scales the puff (1 = about a meter across when fully grown).
static func spawn(parent: Node, at: Vector3, tint: Color, puff_size: float) -> void:
	if parent == null:
		return
	var puff := Smoke.new()
	puff.position = at
	puff.color = tint
	puff.size = puff_size
	parent.add_child(puff)


## A dark burnt patch on the ground where a tank was destroyed. It stays.
static func scorch(parent: Node, at: Vector3, size: float = 1.0) -> void:
	if parent == null:
		return
	var mesh := CylinderMesh.new()
	mesh.top_radius = 1.0
	mesh.bottom_radius = 1.0
	mesh.height = 0.01
	mesh.radial_segments = 12
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.05, 0.04, 0.03, 0.6)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var mark := MeshInstance3D.new()
	mark.mesh = mesh
	mark.material_override = mat
	mark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mark.position = Vector3(at.x, 0.02, at.z)
	mark.scale = Vector3(randf_range(1.1, 1.5) * size, 1.0, randf_range(1.1, 1.5) * size)
	mark.rotation.y = randf() * TAU
	parent.add_child(mark)


func _ready() -> void:
	var sphere := SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	sphere.radial_segments = 8
	sphere.rings = 4
	mesh = sphere
	_mat = StandardMaterial3D.new()
	var shade: float = randf_range(0.85, 1.15)
	_mat.albedo_color = Color(color.r * shade, color.g * shade, color.b * shade, 0.55)
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material_override = _mat
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Rise and drift with the wind (which blows toward +X).
	_drift = Vector3(randf_range(0.3, 0.9), randf_range(0.8, 1.4), randf_range(-0.3, 0.3))
	rotation = Vector3(randf() * TAU, randf() * TAU, 0.0)
	scale = Vector3.ONE * 0.3 * size


func _process(delta: float) -> void:
	_age += delta
	if _age >= DURATION:
		queue_free()
		return
	var t: float = _age / DURATION
	position += _drift * delta
	scale = Vector3(1.0, 0.8, 1.0) * (0.3 + 0.9 * t) * size
	_mat.albedo_color.a = 0.55 * (1.0 - t) * (1.0 - t)
