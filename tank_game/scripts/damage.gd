class_name Damage
extends RefCounted
## Area damage from explosions (shell blasts, exploding drums).

## Damages everything within `radius` of `at`: tanks take `tank_damage`,
## structures take `structure_damage`. Runs on the next frame, because physics
## can't be queried in the middle of a collision callback.
static func splash(world: Node3D, at: Vector3, radius: float, tank_damage: int, structure_damage: int,
		skip: Node = null) -> void:
	_apply.call_deferred(world, at, radius, tank_damage, structure_damage, skip)


static func _apply(world: Node3D, at: Vector3, radius: float, tank_damage: int, structure_damage: int,
		skip: Node) -> void:
	if world == null or not is_instance_valid(world):
		return
	var sphere := SphereShape3D.new()
	sphere.radius = radius
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = sphere
	query.transform = Transform3D(Basis.IDENTITY, at)
	query.collision_mask = 1 | 2 | 4
	var hits: Array[Dictionary] = world.get_world_3d().direct_space_state.intersect_shape(query, 32)
	for hit: Dictionary in hits:
		var body: Object = hit.get("collider")
		if body == null or body == skip or not is_instance_valid(body):
			continue
		if body is Tank and tank_damage > 0:
			(body as Tank).take_damage(tank_damage)
		elif body is Block and structure_damage > 0:
			(body as Block).take_damage(structure_damage, at)
