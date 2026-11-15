class_name Block
extends StaticBody3D
## A solid block standing on the ground: an unbreakable wall, or a breakable crate.
## `size` is width (X), height (Y) and depth (Z) in meters.

var size: Vector3 = Vector3(1.0, 1.0, 1.0)
var color: Color = Color(0.4, 0.4, 0.42)
var breakable: bool = false
var health: int = 3
## False for invisible collision (e.g. the map edge, or props that draw their own model).
var show_mesh: bool = true
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
	if not show_mesh:
		return

	_mat = StandardMaterial3D.new()
	_mat.albedo_color = color
	_mat.roughness = 0.95
	Shapes.add_grime(_mat)
	_add_box(size, Vector3(0.0, size.y * 0.5, 0.0), _mat)
	if breakable:
		# Wooden crate: a frame and a cross of planks on the top face.
		_plank_mat = StandardMaterial3D.new()
		_plank_mat.albedo_color = color.darkened(0.3)
		Shapes.add_grime(_plank_mat, 2.0)
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


## An invisible solid box. Used under props that build their own model.
static func collider(parent: Node3D, at: Vector3, block_size: Vector3, yaw: float = 0.0) -> Block:
	var block := Block.make(at, block_size, Color.WHITE, false)
	block.show_mesh = false
	block.rotation.y = yaw
	parent.add_child(block)
	return block


func take_damage(amount: int) -> void:
	if not breakable:
		return
	health -= amount
	_mat.albedo_color = color.darkened(0.12 * float(3 - health))
	if health <= 0:
		collision_layer = 0
		NavGrid.refresh_area(global_position, 0.8)
		Explosion.spawn(get_parent(), global_position + Vector3.UP * 0.5, 0.9, Color(0.85, 0.6, 0.3))
		Smoke.spawn(get_parent(), global_position + Vector3.UP * 0.4, Color(0.6, 0.52, 0.4), 1.6)
		# Leave a few splintered planks behind.
		var wood := Shapes.mat(color.darkened(0.35))
		for i: int in 4:
			var at := Vector3(global_position.x + randf_range(-0.6, 0.6), 0.03, global_position.z + randf_range(-0.6, 0.6))
			Shapes.box(get_parent(), Vector3(0.5, 0.04, 0.1), at, wood, Vector3(0.0, randf() * TAU, 0.0))
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
