class_name Shell
extends Area3D
## A tank shell. Flies straight, damages the first tank or crate it hits,
## and disappears on walls.

const LIFETIME: float = 2.5

var team: String = "player"
var damage: int = 1
var velocity: Vector3 = Vector3.ZERO
var _age: float = 0.0
var _done: bool = false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 | 2 | 4  # walls/crates, player, enemies
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.13
	shape.shape = sphere
	add_child(shape)
	body_entered.connect(_on_body_entered)

	var color: Color = Color(1.0, 0.95, 0.6) if team == "player" else Color(1.0, 0.5, 0.4)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var mesh := SphereMesh.new()
	mesh.radius = 0.13
	mesh.height = 0.26
	var ball := MeshInstance3D.new()
	ball.mesh = mesh
	ball.material_override = mat
	add_child(ball)
	# A short glowing trail behind the shell.
	var trail_mat := StandardMaterial3D.new()
	trail_mat.albedo_color = Color(color, 0.4)
	trail_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	trail_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var trail_mesh := BoxMesh.new()
	trail_mesh.size = Vector3(0.1, 0.1, 0.5)
	var trail := MeshInstance3D.new()
	trail.mesh = trail_mesh
	trail.material_override = trail_mat
	trail.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	trail.position.z = 0.3
	add_child(trail)
	rotation.y = Tank.yaw_of(velocity)


func _physics_process(delta: float) -> void:
	position += velocity * delta
	_age += delta
	if _age > LIFETIME:
		queue_free()


func _on_body_entered(body: Node3D) -> void:
	if _done:
		return
	if body is Tank:
		var tank: Tank = body
		if tank.team == team:
			return  # no friendly fire
		tank.take_damage(damage)
	elif body is Block:
		var block: Block = body
		block.take_damage(damage)
	_done = true
	Explosion.spawn(get_parent(), global_position, 0.4, Color(1.0, 0.75, 0.3))
	queue_free()
