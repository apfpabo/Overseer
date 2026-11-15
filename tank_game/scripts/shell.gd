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
	collision_mask = 1 | 2 | 4 | 8  # walls/crates, player, enemies, wrecks
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.13
	shape.shape = sphere
	add_child(shape)
	body_entered.connect(_on_body_entered)

	# Tracer: a hot bright core with a glowing streak behind it.
	var color: Color = Color(1.0, 0.85, 0.5) if team == "player" else Color(1.0, 0.5, 0.25)
	var core_mat := StandardMaterial3D.new()
	core_mat.albedo_color = Color(1.0, 1.0, 0.9)
	core_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var core := MeshInstance3D.new()
	var core_mesh := BoxMesh.new()
	core_mesh.size = Vector3(0.09, 0.09, 0.3)
	core.mesh = core_mesh
	core.material_override = core_mat
	core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(core)
	for i: int in 3:
		var glow_mat := StandardMaterial3D.new()
		glow_mat.albedo_color = Color(color, 0.55 - 0.15 * float(i))
		glow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		glow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		glow_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		var glow_mesh := BoxMesh.new()
		var w: float = 0.16 - 0.04 * float(i)
		glow_mesh.size = Vector3(w, w, 0.5)
		var glow := MeshInstance3D.new()
		glow.mesh = glow_mesh
		glow.material_override = glow_mat
		glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		glow.position.z = 0.3 + 0.45 * float(i)
		add_child(glow)
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = 1.2
	light.omni_range = 2.2
	add_child(light)
	# Faint smoke trail left hanging in the air.
	FX.emitter(self, Vector3(0.0, 0.0, 0.2), {"burst": false, "amount": 24, "life": 0.7, "spread": 10.0,
		"vmin": 0.0, "vmax": 0.3, "gravity": FX.WIND * 0.5, "smin": 0.2, "smax": 0.35, "size": 1.0,
		"grow": FX._curve(0.6, 0.0, 2.0),
		"colors": [Color(0.8, 0.75, 0.68, 0.35), Color(0.7, 0.68, 0.64, 0.0)] as Array[Color]})
	rotation.y = Tank.yaw_of(velocity)


func _physics_process(delta: float) -> void:
	position += velocity * delta
	_age += delta
	if _age > LIFETIME:
		queue_free()


func _on_body_entered(body: Node3D) -> void:
	if _done:
		return
	var kind: String = "sand"
	if body is Tank:
		var tank: Tank = body
		if tank.team == team:
			return  # no friendly fire
		kind = "metal" if tank.is_wreck else "armor"
		tank.take_damage(damage)
	elif body is Block:
		var block: Block = body
		match block.kind:
			Block.Kind.CRATE:
				kind = "wood"
			Block.Kind.METAL, Block.Kind.EXPLOSIVE:
				kind = "metal"
			Block.Kind.SANDBAG, Block.Kind.TOPPLE:
				kind = "sand"
			_:
				kind = "concrete"
		block.take_damage(damage, global_position - velocity.normalized())
	_done = true
	var world: Node3D = get_parent() as Node3D
	FX.impact(world, global_position, kind)
	# The blast also chips nearby structures (sandbags, walls next to the hit).
	Damage.splash(world, global_position, 1.1, 0, 1, body)
	queue_free()
