class_name TrackMarks
extends MultiMeshInstance3D
## Tread marks pressed into the sand. Uses one MultiMesh (one draw call) with a
## fixed number of marks; when it is full, the oldest marks are reused.

const MAX_MARKS: int = 3000

static var _current: TrackMarks = null

var _next: int = 0


## Adds a mark at a ground position, rotated to the tank's heading.
static func add(at: Vector3, yaw: float) -> void:
	if _current == null or not is_instance_valid(_current):
		return
	_current._add(at, yaw)


func _ready() -> void:
	_current = self
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var quad := BoxMesh.new()
	quad.size = Vector3(0.26, 0.004, 0.1)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.42, 0.34, 0.24, 0.55)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 1.0
	quad.material = mat
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = quad
	multimesh.instance_count = MAX_MARKS
	multimesh.visible_instance_count = 0


func _exit_tree() -> void:
	if _current == self:
		_current = null


func _add(at: Vector3, yaw: float) -> void:
	var xform := Transform3D(Basis(Vector3.UP, yaw), Vector3(at.x, 0.012, at.z))
	multimesh.set_instance_transform(_next, xform)
	_next = (_next + 1) % MAX_MARKS
	multimesh.visible_instance_count = maxi(multimesh.visible_instance_count, _next if _next > 0 else MAX_MARKS)
