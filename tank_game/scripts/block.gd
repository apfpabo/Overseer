class_name Block
extends StaticBody3D
## A solid block standing on the ground: an unbreakable wall, or a breakable crate.
## `size` is width (X), height (Y) and depth (Z) in meters.

var size: Vector3 = Vector3(1.0, 1.0, 1.0)
var color: Color = Color(0.4, 0.4, 0.42)
var breakable: bool = false
var health: int = 3
var _mat: StandardMaterial3D
var _plank_mat: StandardMaterial3D


## `at` is the center of the block's footprint on the ground.
static func make(at: Vector3, block_size: Vector3, block_color: Color, is_breakable: bool) -> Block:
	var block := Block.new()
	block.position = at
	block.size = block_size
	block.color = block_color
	block.breakable = is_breakable
	return block


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position.y = size.y * 0.5
	add_child(shape)

	_mat = StandardMaterial3D.new()
	_mat.albedo_color = color
	_mat.roughness = 0.9
	_add_box(size, Vector3(0.0, size.y * 0.5, 0.0), _mat)
	if breakable:
		# Wooden crate: a frame and a cross of planks on the top face.
		_plank_mat = StandardMaterial3D.new()
		_plank_mat.albedo_color = color.darkened(0.3)
		var top: float = size.y + 0.015
		var edge: float = size.x * 0.5 - 0.05
		for s: float in [-1.0, 1.0]:
			_add_box(Vector3(size.x, 0.03, 0.1), Vector3(0.0, top, s * edge), _plank_mat)
			_add_box(Vector3(0.1, 0.03, size.z), Vector3(s * edge, top, 0.0), _plank_mat)
		var diag: float = size.x * 1.25
		var plank := _add_box(Vector3(diag, 0.03, 0.1), Vector3(0.0, top, 0.0), _plank_mat)
		plank.rotation.y = PI * 0.25
		plank = _add_box(Vector3(diag, 0.03, 0.1), Vector3(0.0, top, 0.0), _plank_mat)
		plank.rotation.y = -PI * 0.25


func take_damage(amount: int) -> void:
	if not breakable:
		return
	health -= amount
	_mat.albedo_color = color.darkened(0.12 * float(3 - health))
	if health <= 0:
		Explosion.spawn(get_parent(), global_position + Vector3.UP * 0.5, 0.9, Color(0.85, 0.6, 0.3))
		queue_free()


func _add_box(box_size: Vector3, at: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = box_size
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	inst.material_override = mat
	inst.position = at
	add_child(inst)
	return inst
