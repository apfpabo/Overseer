class_name Tank
extends CharacterBody3D
## Shared code for every tank: 3D model, movement, turret, shooting, health.
## Tanks drive on the flat ground (Y = 0). The hull faces -Z when rotation.y is 0.
## The 3D model is built from boxes and cylinders in code (see _build_model).

signal health_changed(current: int, maximum: int)
signal died(tank: Tank)

const MUZZLE_HEIGHT: float = 0.68
const MUZZLE_DISTANCE: float = 1.55
const TREAD_SPACING: float = 0.12
const TREADS_PER_TRACK: int = 10
const TREAD_RUN: float = TREAD_SPACING * TREADS_PER_TRACK
const BARREL_REST_Z: float = -0.42
const RECOIL_DISTANCE: float = 0.2
const SMOKE_INTERVAL: float = 0.18

@export var team: String = "player"
@export var max_health: int = 5
@export var move_speed: float = 5.3  # meters per second
@export var turn_speed: float = 2.6  # radians per second
@export var turret_turn_speed: float = 6.0  # radians per second
@export var fire_cooldown: float = 0.5
@export var shell_speed: float = 16.0
@export var shell_damage: int = 1
@export var hull_color: Color = Color(0.26, 0.42, 0.22)
@export var turret_color: Color = Color(0.3, 0.47, 0.26)

var health: int = 0
## Turret direction in the world (a yaw angle), independent of the hull.
var turret_yaw: float = 0.0
var _cooldown_left: float = 0.0
var _flash_left: float = 0.0
var _track_offset: float = 0.0

var _turret: Node3D
var _barrel: Node3D
var _recoil: float = 0.0
var _smoke_left: float = 0.0
var _hull_mat: StandardMaterial3D
var _turret_mat: StandardMaterial3D
var _treads: Array[MeshInstance3D] = []


## Converts a flat direction into a yaw angle (rotation.y).
static func yaw_of(dir: Vector3) -> float:
	return atan2(-dir.x, -dir.z)


## Converts a yaw angle into a flat direction.
static func dir_of(yaw: float) -> Vector3:
	return Vector3(-sin(yaw), 0.0, -cos(yaw))


func _ready() -> void:
	health = max_health
	turret_yaw = rotation.y
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.1, 1.0, 1.5)
	shape.shape = box
	shape.position.y = 0.5
	add_child(shape)
	_build_model()


func _physics_process(delta: float) -> void:
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)
	var flashing: bool = _flash_left > 0.0
	if flashing:
		_flash_left -= delta
	_hull_mat.albedo_color = Color.WHITE if flashing else hull_color
	_turret_mat.albedo_color = Color.WHITE if flashing else turret_color
	_turret.rotation.y = turret_yaw - rotation.y
	_update_treads()
	# Badly damaged tanks trail smoke.
	if health * 3 <= max_health:
		_smoke_left -= delta
		if _smoke_left <= 0.0:
			_smoke_left = SMOKE_INTERVAL
			Smoke.spawn(get_parent(), global_position + global_basis * Vector3(randf_range(-0.2, 0.2), 0.7, randf_range(0.3, 0.6)))


## Drives the hull. `drive` is -1..1 (back/forward). `turn` is -1..1,
## positive turns left (counter-clockwise seen from above).
func drive_tank(drive: float, turn: float, delta: float) -> void:
	rotation.y += turn * turn_speed * delta
	var speed: float = move_speed if drive >= 0.0 else move_speed * 0.6
	velocity = dir_of(rotation.y) * drive * speed
	move_and_slide()
	position.y = 0.0
	_track_offset = fposmod(_track_offset + drive * speed * delta, TREAD_SPACING)
	# Turning in place also moves the treads a little.
	_track_offset = fposmod(_track_offset + absf(turn) * 0.3 * delta, TREAD_SPACING)


## Turns the turret toward a world yaw angle, limited by turret_turn_speed.
func aim_turret_toward(target_yaw: float, delta: float) -> void:
	var diff: float = wrapf(target_yaw - turret_yaw, -PI, PI)
	var step: float = turret_turn_speed * delta
	turret_yaw += clampf(diff, -step, step)


func can_fire() -> bool:
	return _cooldown_left <= 0.0


func fire() -> void:
	if not can_fire():
		return
	_cooldown_left = fire_cooldown
	_recoil = RECOIL_DISTANCE
	var dir: Vector3 = dir_of(turret_yaw)
	var shell := Shell.new()
	shell.team = team
	shell.damage = shell_damage
	shell.velocity = dir * shell_speed
	shell.position = global_position + dir * MUZZLE_DISTANCE + Vector3.UP * MUZZLE_HEIGHT
	get_parent().add_child(shell)
	Explosion.spawn(get_parent(), shell.position, 0.25, Color(1.0, 0.85, 0.4))


func take_damage(amount: int) -> void:
	if health <= 0:
		return
	health -= amount
	_flash_left = 0.12
	health_changed.emit(health, max_health)
	if health <= 0:
		Explosion.spawn(get_parent(), global_position + Vector3.UP * 0.6, 1.5, Color(1.0, 0.55, 0.15))
		Smoke.scorch(get_parent(), global_position)
		died.emit(self)
		queue_free()


# --- Model ---------------------------------------------------------------
# Built from boxes and cylinders. Sizes are in meters; the hull is about
# 1.6 m long and 1.1 m wide, and its front points toward -Z.

func _build_model() -> void:
	_hull_mat = _material(hull_color)
	_turret_mat = _material(turret_color)
	var trim := _material(hull_color.darkened(0.3))
	var rubber := _material(Color(0.1, 0.1, 0.1))
	var steel := _material(Color(0.32, 0.32, 0.33), 0.55)
	var link_mat := _material(Color(0.24, 0.23, 0.22), 0.4)
	var black := _material(Color(0.04, 0.04, 0.05))
	var glass := _material(Color(0.95, 0.9, 0.6))
	glass.emission_enabled = true
	glass.emission = Color(1.0, 0.9, 0.55)
	glass.emission_energy_multiplier = 0.6
	var canvas := _material(Color(0.42, 0.4, 0.28))
	var drum := _material(Color(0.24, 0.27, 0.2))

	_build_tracks(rubber, steel, link_mat)
	_build_hull(trim, steel, black, glass, canvas, drum, link_mat)
	_build_turret(trim, steel, black, glass, canvas)


func _build_tracks(rubber: Material, steel: Material, link_mat: Material) -> void:
	for side: float in [-1.0, 1.0]:
		var x: float = side * 0.42
		var wheel_turn := Vector3(0.0, 0.0, PI * 0.5)  # wheel axle along X
		# Track run, plus the drive sprocket (front) and idler (rear) as round ends.
		_box(self, Vector3(0.26, 0.38, 1.2), Vector3(x, 0.21, 0.0), rubber)
		_cylinder(self, 0.19, 0.19, 0.26, Vector3(x, 0.21, -0.6), rubber, wheel_turn)
		_cylinder(self, 0.19, 0.19, 0.26, Vector3(x, 0.21, 0.6), rubber, wheel_turn)
		_cylinder(self, 0.09, 0.09, 0.28, Vector3(x, 0.21, -0.6), steel, wheel_turn)
		_cylinder(self, 0.08, 0.08, 0.28, Vector3(x, 0.21, 0.6), steel, wheel_turn)
		# Road wheels peeking out of the outer side.
		for i: int in 5:
			var z: float = -0.44 + 0.22 * float(i)
			_cylinder(self, 0.12, 0.12, 0.05, Vector3(x + side * 0.14, 0.15, z), steel, wheel_turn)
			_cylinder(self, 0.05, 0.05, 0.06, Vector3(x + side * 0.15, 0.15, z), rubber, wheel_turn)
		# Tread links on top, which slide as the tank drives.
		for i: int in TREADS_PER_TRACK:
			_treads.append(_box(self, Vector3(0.27, 0.035, 0.06), Vector3(x, 0.41, 0.0), link_mat))


func _build_hull(trim: Material, steel: Material, black: Material, glass: Material,
		canvas: Material, drum: Material, link_mat: Material) -> void:
	# Lower and upper hull. The deck sits between the tracks so they stay visible.
	_box(self, Vector3(0.58, 0.32, 1.46), Vector3(0.0, 0.3, 0.0), _hull_mat)
	_box(self, Vector3(0.62, 0.1, 1.1), Vector3(0.0, 0.5, 0.06), _hull_mat)
	# Sloped front armor (glacis) and rear plate.
	_box(self, Vector3(0.62, 0.06, 0.4), Vector3(0.0, 0.43, -0.64), _hull_mat, Vector3(-0.45, 0.0, 0.0))
	_box(self, Vector3(0.62, 0.22, 0.05), Vector3(0.0, 0.42, 0.66), trim)
	# Fenders over the front and rear of the tracks.
	for side: float in [-1.0, 1.0]:
		var x: float = side * 0.42
		_box(self, Vector3(0.3, 0.025, 0.2), Vector3(x, 0.45, -0.72), trim)
		_box(self, Vector3(0.3, 0.025, 0.14), Vector3(x, 0.45, 0.74), trim)
		# Headlight with a guard.
		_cylinder(self, 0.04, 0.045, 0.06, Vector3(side * 0.28, 0.5, -0.8), glass, Vector3(PI * 0.5, 0.0, 0.0))
		_box(self, Vector3(0.1, 0.02, 0.03), Vector3(side * 0.28, 0.55, -0.82), steel)
		# Tow hooks and exhaust pipes.
		_box(self, Vector3(0.05, 0.05, 0.08), Vector3(side * 0.18, 0.3, -0.78), steel)
		_cylinder(self, 0.035, 0.035, 0.12, Vector3(side * 0.18, 0.45, 0.72), black, Vector3(PI * 0.5, 0.0, 0.0))
	# Spare track links bolted to the glacis.
	for i: int in 3:
		_box(self, Vector3(0.14, 0.03, 0.07), Vector3(-0.16 + 0.16 * float(i), 0.47, -0.62), link_mat, Vector3(-0.45, 0.0, 0.0))
	# Driver's hatch and periscope.
	_cylinder(self, 0.07, 0.07, 0.03, Vector3(-0.14, 0.56, -0.42), trim)
	_box(self, Vector3(0.08, 0.03, 0.03), Vector3(-0.14, 0.57, -0.5), black)
	# Engine deck: two grilles with slats.
	for side: float in [-1.0, 1.0]:
		_box(self, Vector3(0.24, 0.02, 0.24), Vector3(side * 0.15, 0.56, 0.48), black)
		for i: int in 4:
			_box(self, Vector3(0.22, 0.025, 0.02), Vector3(side * 0.15, 0.57, 0.39 + 0.06 * float(i)), steel)
	# Fuel drums strapped across the back.
	for side: float in [-1.0, 1.0]:
		_cylinder(self, 0.08, 0.08, 0.28, Vector3(side * 0.16, 0.6, 0.72), drum, Vector3(0.0, 0.0, PI * 0.5))
	# Toolbox and a shovel on the left, stowage on the right.
	_box(self, Vector3(0.1, 0.07, 0.3), Vector3(-0.26, 0.58, -0.18), trim)
	_box(self, Vector3(0.03, 0.02, 0.32), Vector3(0.27, 0.57, -0.2), steel)
	_box(self, Vector3(0.07, 0.02, 0.09), Vector3(0.27, 0.57, -0.4), steel)
	_box(self, Vector3(0.1, 0.08, 0.24), Vector3(0.26, 0.59, 0.18), canvas)


func _build_turret(trim: Material, steel: Material, black: Material, glass: Material, canvas: Material) -> void:
	_turret = Node3D.new()
	_turret.position = Vector3(0.0, 0.56, 0.06)
	add_child(_turret)
	# Turret ring and main body, with angled cheek armor at the front.
	_cylinder(_turret, 0.36, 0.38, 0.05, Vector3(0.0, 0.0, 0.0), trim)
	_box(_turret, Vector3(0.62, 0.22, 0.56), Vector3(0.0, 0.12, 0.02), _turret_mat)
	for side: float in [-1.0, 1.0]:
		_box(_turret, Vector3(0.24, 0.2, 0.3), Vector3(side * 0.2, 0.11, -0.28), _turret_mat, Vector3(0.0, side * 0.45, 0.0))
	_box(_turret, Vector3(0.56, 0.03, 0.5), Vector3(0.0, 0.245, 0.02), _turret_mat)
	# Rear bustle with a stowage basket full of gear.
	_box(_turret, Vector3(0.5, 0.17, 0.2), Vector3(0.0, 0.12, 0.38), _turret_mat)
	_box(_turret, Vector3(0.58, 0.02, 0.18), Vector3(0.0, 0.2, 0.56), steel)
	for side: float in [-1.0, 1.0]:
		_box(_turret, Vector3(0.02, 0.1, 0.2), Vector3(side * 0.29, 0.25, 0.56), steel)
	_box(_turret, Vector3(0.56, 0.02, 0.02), Vector3(0.0, 0.3, 0.65), steel)
	_box(_turret, Vector3(0.22, 0.08, 0.14), Vector3(-0.14, 0.25, 0.55), canvas)
	_box(_turret, Vector3(0.18, 0.1, 0.13), Vector3(0.12, 0.26, 0.56), canvas)
	# Commander's cupola with vision blocks and a hatch.
	var cupola := Vector3(0.15, 0.29, 0.12)
	_cylinder(_turret, 0.11, 0.12, 0.09, cupola, _turret_mat)
	for i: int in 6:
		var a: float = TAU * float(i) / 6.0
		_box(_turret, Vector3(0.04, 0.03, 0.03), cupola + Vector3(sin(a) * 0.11, 0.02, cos(a) * 0.11), black, Vector3(0.0, a, 0.0))
	_cylinder(_turret, 0.09, 0.09, 0.025, cupola + Vector3(0.0, 0.055, 0.0), trim)
	# Loader's hatch with a roof machine gun.
	_box(_turret, Vector3(0.16, 0.025, 0.16), Vector3(-0.15, 0.27, 0.1), trim)
	_box(_turret, Vector3(0.05, 0.08, 0.05), Vector3(-0.15, 0.31, -0.04), steel)
	_cylinder(_turret, 0.015, 0.015, 0.34, Vector3(-0.15, 0.35, -0.16), black, Vector3(PI * 0.5, 0.0, 0.0))
	_box(_turret, Vector3(0.05, 0.05, 0.12), Vector3(-0.15, 0.35, -0.02), black)
	# Gunner's sight.
	_box(_turret, Vector3(0.1, 0.07, 0.1), Vector3(0.18, 0.28, -0.14), _turret_mat)
	_box(_turret, Vector3(0.08, 0.04, 0.01), Vector3(0.18, 0.29, -0.195), glass)
	# Smoke grenade launchers on both cheeks.
	for side: float in [-1.0, 1.0]:
		for i: int in 3:
			var at := Vector3(side * (0.27 + 0.04 * float(i)), 0.2, -0.12 - 0.05 * float(i))
			_cylinder(_turret, 0.025, 0.025, 0.1, at, black, Vector3(PI * 0.4, 0.0, -side * 0.6))
	# Two whip antennas at the back.
	for side: float in [-1.0, 1.0]:
		_cylinder(_turret, 0.025, 0.03, 0.04, Vector3(side * 0.22, 0.26, 0.4), steel)
		_cylinder(_turret, 0.006, 0.01, 0.6, Vector3(side * 0.22, 0.57, 0.4), black)
	# Gun mantlet, then the barrel (its own node so it can recoil).
	_box(_turret, Vector3(0.26, 0.17, 0.12), Vector3(0.0, 0.12, -0.38), _turret_mat)
	_barrel = Node3D.new()
	_barrel.position = Vector3(0.0, 0.12, BARREL_REST_Z)
	_turret.add_child(_barrel)
	var along := Vector3(PI * 0.5, 0.0, 0.0)  # cylinder laid along Z
	_cylinder(_barrel, 0.045, 0.055, 1.02, Vector3(0.0, 0.0, -0.51), _turret_mat, along)
	_cylinder(_barrel, 0.075, 0.075, 0.2, Vector3(0.0, 0.0, -0.5), _turret_mat, along)
	_cylinder(_barrel, 0.06, 0.06, 0.03, Vector3(0.0, 0.0, -0.2), trim, along)
	_box(_barrel, Vector3(0.15, 0.1, 0.15), Vector3(0.0, 0.0, -1.06), trim)
	for side: float in [-1.0, 1.0]:
		_box(_barrel, Vector3(0.01, 0.06, 0.04), Vector3(side * 0.076, 0.0, -1.06), black)


func _update_treads() -> void:
	var count: int = TREADS_PER_TRACK
	for i: int in _treads.size():
		var slot: int = i % count
		var z: float = -TREAD_RUN * 0.5 + TREAD_SPACING * float(slot) + _track_offset
		# Moving forward means the top of the track slides backward (+Z).
		_treads[i].position.z = -z
	_recoil = move_toward(_recoil, 0.0, get_physics_process_delta_time() * 0.9)
	_barrel.position.z = BARREL_REST_Z + _recoil


static func _material(color: Color, metal: float = 0.15) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = metal
	mat.roughness = 0.75
	return mat


static func _box(parent: Node3D, size: Vector3, at: Vector3, mat: Material, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	inst.material_override = mat
	inst.position = at
	inst.rotation = rot
	parent.add_child(inst)
	return inst


static func _cylinder(parent: Node3D, top: float, bottom: float, height: float, at: Vector3,
		mat: Material, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = height
	mesh.radial_segments = 14
	mesh.rings = 1
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	inst.material_override = mat
	inst.position = at
	inst.rotation = rot
	parent.add_child(inst)
	return inst
