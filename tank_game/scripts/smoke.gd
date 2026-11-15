class_name Smoke
extends MeshInstance3D
## A puff of dark smoke that rises, grows and fades. Also makes scorch marks.

const DURATION: float = 1.2

var _age: float = 0.0
var _mat: StandardMaterial3D
var _drift: Vector3 = Vector3.ZERO


static func spawn(parent: Node, at: Vector3) -> void:
	if parent == null:
		return
	var puff := Smoke.new()
	puff.position = at
	parent.add_child(puff)


## A dark burnt patch on the ground where a tank was destroyed. It stays.
static func scorch(parent: Node, at: Vector3) -> void:
	if parent == null:
		return
	var mesh := CylinderMesh.new()
	mesh.top_radius = 1.0
	mesh.bottom_radius = 1.0
	mesh.height = 0.01
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.05, 0.05, 0.04, 0.75)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var mark := MeshInstance3D.new()
	mark.mesh = mesh
	mark.material_override = mat
	mark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mark.position = Vector3(at.x, 0.01, at.z)
	mark.scale = Vector3(randf_range(0.9, 1.2), 1.0, randf_range(0.9, 1.2))
	mark.rotation.y = randf() * TAU
	parent.add_child(mark)


func _ready() -> void:
	var sphere := SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	sphere.radial_segments = 10
	sphere.rings = 5
	mesh = sphere
	_mat = StandardMaterial3D.new()
	var grey: float = randf_range(0.12, 0.25)
	_mat.albedo_color = Color(grey, grey, grey, 0.6)
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material_override = _mat
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_drift = Vector3(randf_range(-0.3, 0.3), 1.2, randf_range(0.2, 0.6))
	scale = Vector3.ONE * 0.3


func _process(delta: float) -> void:
	_age += delta
	if _age >= DURATION:
		queue_free()
		return
	var t: float = _age / DURATION
	position += _drift * delta
	scale = Vector3.ONE * (0.3 + 0.7 * t)
	_mat.albedo_color.a = 0.6 * (1.0 - t)
