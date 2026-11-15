class_name Block
extends StaticBody3D
## A solid object standing on the ground: walls, crates, barriers, cars, drums,
## trees, poles, sandbags... `kind` decides how it reacts to damage and how it
## is destroyed. `size` is width (X), height (Y) and depth (Z) in meters.

enum Kind {
	SOLID,      ## never breaks (map edge, rocks, rubble heaps)
	CRATE,      ## splinters
	CONCRETE,   ## crumbles into rubble you can drive over
	METAL,      ## crumples with sparks (car wrecks)
	EXPLOSIVE,  ## blows up and damages everything nearby (fuel drums)
	TOPPLE,     ## falls over (palms, poles)
	SANDBAG,    ## bursts in a spray of sand
}

var size: Vector3 = Vector3(1.0, 1.0, 1.0)
var color: Color = Color(0.4, 0.4, 0.42)
var kind: Kind = Kind.SOLID
var health: int = 3
## False for invisible collision (props that draw their own model as children).
var show_mesh: bool = true
## TOPPLE only: the model that tips over (its origin must be at the base).
var topple_node: Node3D = null
var _mat: StandardMaterial3D
var _destroyed: bool = false


## `at` is the center of the block's footprint on the ground.
static func make(at: Vector3, block_size: Vector3, block_color: Color, is_breakable: bool) -> Block:
	var block := Block.new()
	block.position = at
	block.size = block_size
	block.color = block_color
	block.kind = Kind.CRATE if is_breakable else Kind.SOLID
	return block


## An invisible solid box. Props build their model as children of it, so the
## model disappears when the block is destroyed.
static func collider(parent: Node3D, at: Vector3, block_size: Vector3, yaw: float = 0.0,
		block_kind: Kind = Kind.SOLID, hp: int = 3, debris_color: Color = Color(0.45, 0.43, 0.4)) -> Block:
	var block := Block.make(at, block_size, debris_color, false)
	block.show_mesh = false
	block.rotation.y = yaw
	block.kind = block_kind
	block.health = hp
	parent.add_child(block)
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
	if kind == Kind.CRATE:
		# Wooden crate: a frame and a cross of planks on the top face.
		var plank_mat := StandardMaterial3D.new()
		plank_mat.albedo_color = color.darkened(0.3)
		Shapes.add_grime(plank_mat, 2.0)
		var top: float = size.y + 0.015
		var edge: float = size.x * 0.5 - 0.05
		for s: float in [-1.0, 1.0]:
			_add_box(Vector3(size.x, 0.03, 0.1), Vector3(0.0, top, s * edge), plank_mat)
			_add_box(Vector3(0.1, 0.03, size.z), Vector3(s * edge, top, 0.0), plank_mat)
		var diag: float = size.x * 1.25
		var plank := _add_box(Vector3(diag, 0.03, 0.1), Vector3(0.0, top, 0.0), plank_mat)
		plank.rotation.y = PI * 0.25
		plank = _add_box(Vector3(diag, 0.03, 0.1), Vector3(0.0, top, 0.0), plank_mat)
		plank.rotation.y = -PI * 0.25


func is_destructible() -> bool:
	return kind != Kind.SOLID and not _destroyed


## `from` is where the hit came from (used to decide which way things fall).
func take_damage(amount: int, from: Vector3 = Vector3.INF) -> void:
	if not is_destructible():
		return
	health -= amount
	if _mat != null:
		_mat.albedo_color = color.darkened(clampf(0.12 * float(3 - health), 0.0, 0.5))
	if health > 0:
		return
	_destroyed = true
	_destroy(from)


## Instantly destroyed (e.g. a tank drove into it).
func crush(from: Vector3) -> void:
	if is_destructible():
		take_damage(999, from)


## The top-level 3D node (the game), which sits at the world origin. Effects
## and debris go there, using world positions.
func _world_root() -> Node3D:
	var node: Node = self
	while node.get_parent() is Node3D:
		node = node.get_parent()
	return node as Node3D


func _destroy(from: Vector3) -> void:
	var world: Node3D = _world_root()
	var center: Vector3 = global_position + Vector3.UP * size.y * 0.5
	collision_layer = 0
	NavGrid.refresh_area(global_position, maxf(size.x, size.z) * 0.6)
	match kind:
		Kind.CRATE:
			FX.debris(world, center, color.darkened(0.2), 16, 7.0, 0.18)
			FX.dust_cloud(world, center, Color(0.6, 0.52, 0.4), 10, 1.0)
			_scatter(world, Vector3(0.5, 0.04, 0.1), color.darkened(0.35), 5, 0.7)
		Kind.CONCRETE:
			FX.debris(world, center, color, 22, 8.0, 0.22)
			FX.dust_cloud(world, center, Color(0.66, 0.62, 0.56), 18, 1.6)
			FX.dust_cloud(world, global_position, FX.SAND, 10, 1.3)
			FollowCamera.shake(0.3)
			_leave_rubble(world)
		Kind.METAL:
			FX.impact(world, center, "metal")
			FX.smoke_puffs(world, center, 10, Color(0.15, 0.14, 0.13), 2.5, 1.6)
			# A flattened, blackened shell stays behind.
			var shell_mat := Shapes.mat(Color(0.12, 0.1, 0.09), 0.4, 0.9)
			Shapes.box(world, Vector3(size.x * 0.95, 0.25, size.z * 0.9), Vector3(global_position.x, 0.12, global_position.z),
				shell_mat, Vector3(0.0, rotation.y, randf_range(-0.1, 0.1)))
		Kind.EXPLOSIVE:
			FX.explosion(world, center, 0.9)
			Damage.splash(world, center, 2.6, 2, 3, self)
		Kind.SANDBAG:
			FX.debris(world, center, Color(0.55, 0.48, 0.34), 14, 6.0, 0.2)
			FX.dust_cloud(world, center, FX.SAND, 16, 1.4)
			_scatter(world, Vector3(0.45, 0.12, 0.3), Color(0.5, 0.44, 0.31), 7, maxf(size.x, size.z) * 0.5)
		Kind.TOPPLE:
			_topple(world, from)
			return
	queue_free()


## Palms and poles: tip the model over, away from the hit, and leave it lying.
func _topple(world: Node3D, from: Vector3) -> void:
	FX.dust_cloud(world, global_position, FX.SAND, 8, 1.0)
	if topple_node == null:
		queue_free()
		return
	var away: Vector3 = global_position - from if from != Vector3.INF else Vector3(randf_range(-1, 1), 0.0, randf_range(-1, 1))
	away.y = 0.0
	if away.length() < 0.01:
		away = Vector3.RIGHT
	away = away.normalized()
	var axis: Vector3 = Vector3.UP.cross(away).normalized()
	var start: Basis = topple_node.global_basis
	var end: Basis = Basis(axis, PI * 0.47) * start
	var keep: Transform3D = topple_node.global_transform
	remove_child(topple_node)
	world.add_child(topple_node)
	topple_node.global_transform = keep
	var tween := topple_node.create_tween()
	tween.tween_method(func(t: float) -> void:
		topple_node.global_basis = start.slerp(end, t), 0.0, 1.0, 0.9).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_callback(func() -> void:
		var hit_at: Vector3 = global_position + away * size.y * 1.6
		FX.dust_cloud(world, hit_at, FX.SAND, 14, 1.3)
		FollowCamera.shake(0.15))
	tween.tween_callback(queue_free)


## Loose pieces lying on the ground (no collision).
func _scatter(world: Node3D, piece: Vector3, piece_color: Color, count: int, spread: float) -> void:
	var m := Shapes.mat(piece_color, 0.0, 1.0)
	for i: int in count:
		var at := Vector3(global_position.x + randf_range(-spread, spread), piece.y * 0.5, global_position.z + randf_range(-spread, spread))
		Shapes.box(world, piece, at, m, Vector3(0.0, randf() * TAU, randf_range(-0.2, 0.2)))


## Broken concrete lying where a wall stood. Tanks can drive over it.
func _leave_rubble(world: Node3D) -> void:
	var m := Shapes.mat(color.darkened(0.15), 0.0, 1.0)
	var spread: float = maxf(size.x, size.z) * 0.6
	var count: int = clampi(int(size.x * size.z * 6.0) + 5, 5, 14)
	for i: int in count:
		var chunk := Vector3(randf_range(0.15, 0.45), randf_range(0.08, 0.22), randf_range(0.15, 0.45))
		var at := Vector3(global_position.x + randf_range(-spread, spread), chunk.y * 0.4,
			global_position.z + randf_range(-spread, spread))
		Shapes.box(world, chunk, at, m, Vector3(randf_range(-0.4, 0.4), randf() * TAU, randf_range(-0.4, 0.4)))
	Shapes.cylinder(world, spread * 0.8, spread, 0.06, Vector3(global_position.x, 0.03, global_position.z),
		Shapes.mat(Color(0.5, 0.47, 0.42), 0.0, 1.0), Vector3.ZERO, 8)


func _add_box(box_size: Vector3, at: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = box_size
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	inst.material_override = mat
	inst.position = at
	add_child(inst)
	return inst
