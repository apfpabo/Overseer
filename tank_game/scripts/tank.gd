class_name Tank
extends CharacterBody3D
## Shared code for every tank: 3D model, movement, turret, shooting, health.
## Tanks drive on the flat ground (Y = 0). The hull faces -Z when rotation.y is 0.
## The 3D model is built from boxes and cylinders in code (see _build_model).
## A destroyed tank stays on the map as a burnt-out wreck that blocks movement and shots.

signal health_changed(current: int, maximum: int)
signal died(tank: Tank)

const MUZZLE_HEIGHT: float = 0.68
const MUZZLE_DISTANCE: float = 1.55
const TREAD_SPACING: float = 0.12
const TREADS_PER_TRACK: int = 10
const TREAD_RUN: float = TREAD_SPACING * TREADS_PER_TRACK
const BARREL_REST_Z: float = -0.42
const RECOIL_DISTANCE: float = 0.2
const DUST_INTERVAL: float = 0.09
const TRACK_MARK_STEP: float = 0.32
const WRECK_BURN_TIME: float = 14.0
const WRECK_LAYER: int = 8  # blocks shells and sight, but not tanks
const SAND_DUST: Color = Color(0.72, 0.62, 0.46)

@export var team: String = "player"
@export var max_health: int = 5
@export var move_speed: float = 5.3  # meters per second
@export var turn_speed: float = 2.6  # radians per second
@export var turret_turn_speed: float = 6.0  # radians per second
@export var fire_cooldown: float = 0.5
@export var shell_speed: float = 16.0
@export var shell_damage: int = 1
@export var hull_color: Color = Color(0.27, 0.34, 0.16)
@export var turret_color: Color = Color(0.31, 0.38, 0.18)

var health: int = 0
## Turret direction in the world (a yaw angle), independent of the hull.
var turret_yaw: float = 0.0
## True once the tank is destroyed: it no longer moves, shoots or takes damage.
var is_wreck: bool = false
var _cooldown_left: float = 0.0
var _flash_left: float = 0.0
var _track_offset: float = 0.0
var _dust_left: float = 0.0
var _mark_distance: float = 0.0
var _burn_left: float = 0.0
var _fire_light: MeshInstance3D = null  # firelight glow on the ground
var _fire: Node3D = null
var _damage_smoke: CPUParticles3D = null

var _turret: Node3D
var _barrel: Node3D
var _recoil: float = 0.0
var _hull_mat: StandardMaterial3D
var _turret_mat: StandardMaterial3D
var _trim_mat: StandardMaterial3D
var _treads: Array[MeshInstance3D] = []


## Converts a flat direction into a yaw angle (rotation.y).
static func yaw_of(dir: Vector3) -> float:
	return atan2(-dir.x, -dir.z)


## Converts a yaw angle into a flat direction.
static func dir_of(yaw: float) -> Vector3:
	return Vector3(-sin(yaw), 0.0, -cos(yaw))


## Places a burnt-out tank hulk as map scenery (cover).
static func make_hulk(parent: Node3D, at: Vector3, yaw: float, turret_offset: float) -> Tank:
	var hulk := Tank.new()
	hulk.position = at
	hulk.rotation.y = yaw
	parent.add_child(hulk)
	hulk.turret_yaw = yaw + turret_offset
	hulk.become_wreck(false)
	return hulk


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
	_turret.rotation.y = turret_yaw - rotation.y
	if is_wreck:
		_update_wreck(delta)
		return
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)
	var flashing: bool = _flash_left > 0.0
	if flashing:
		_flash_left -= delta
	_hull_mat.albedo_color = Color.WHITE if flashing else hull_color
	_turret_mat.albedo_color = Color.WHITE if flashing else turret_color
	_update_treads()
	# Badly damaged tanks trail smoke from the engine deck.
	if health * 3 <= max_health and _damage_smoke == null:
		_damage_smoke = FX.damage_smoke(self, Vector3(0.0, 0.7, 0.5))


## Drives the hull. `drive` is -1..1 (back/forward). `turn` is -1..1,
## positive turns left (counter-clockwise seen from above).
func drive_tank(drive: float, turn: float, delta: float) -> void:
	if is_wreck:
		return
	rotation.y += turn * turn_speed * delta
	var speed: float = move_speed if drive >= 0.0 else move_speed * 0.6
	velocity = dir_of(rotation.y) * drive * speed
	var before: Vector3 = global_position
	move_and_slide()
	position.y = 0.0
	_crush_obstacles()
	_track_offset = fposmod(_track_offset + drive * speed * delta, TREAD_SPACING)
	# Turning in place also moves the treads a little.
	_track_offset = fposmod(_track_offset + absf(turn) * 0.3 * delta, TREAD_SPACING)
	_leave_traces(global_position.distance_to(before), absf(turn), delta)


## Driving into crates, sandbags, palms, poles or drums flattens them.
func _crush_obstacles() -> void:
	for i: int in get_slide_collision_count():
		var other: Object = get_slide_collision(i).get_collider()
		if other is Block:
			var block: Block = other
			if block.kind in [Block.Kind.CRATE, Block.Kind.TOPPLE, Block.Kind.SANDBAG, Block.Kind.EXPLOSIVE]:
				block.crush(global_position)


## Dust kicked up behind the tracks, and track marks pressed into the sand.
func _leave_traces(moved: float, turning: float, delta: float) -> void:
	if moved < 0.001 and turning < 0.01:
		return
	_mark_distance += moved + turning * 0.15 * delta
	if _mark_distance >= TRACK_MARK_STEP:
		_mark_distance = 0.0
		for side: float in [-1.0, 1.0]:
			TrackMarks.add(global_position + global_basis * Vector3(side * 0.42, 0.0, 0.0), rotation.y)
	if moved / maxf(delta, 0.0001) > 1.5:
		_dust_left -= delta
		if _dust_left <= 0.0:
			_dust_left = DUST_INTERVAL
			var side: float = -1.0 if randf() < 0.5 else 1.0
			var at: Vector3 = global_position + global_basis * Vector3(side * 0.42, 0.25, 0.85)
			Smoke.spawn(get_parent(), at, SAND_DUST, 0.8)


## Turns the turret toward a world yaw angle, limited by turret_turn_speed.
func aim_turret_toward(target_yaw: float, delta: float) -> void:
	var diff: float = wrapf(target_yaw - turret_yaw, -PI, PI)
	var step: float = turret_turn_speed * delta
	turret_yaw += clampf(diff, -step, step)


func can_fire() -> bool:
	return _cooldown_left <= 0.0 and not is_wreck


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
	FX.muzzle_blast(get_parent(), shell.position - dir * 0.15, dir)


func take_damage(amount: int) -> void:
	if health <= 0 or is_wreck:
		return
	health -= amount
	_flash_left = 0.12
	health_changed.emit(health, max_health)
	if health <= 0:
		FX.explosion(get_parent(), global_position + Vector3.UP * 0.4, 1.0)
		died.emit(self)
		become_wreck(true)


## Turns this tank into a blackened wreck. If `burning`, it smokes and
## flickers with fire for a while.
func become_wreck(burning: bool) -> void:
	is_wreck = true
	team = "wreck"
	health = 0
	velocity = Vector3.ZERO
	collision_layer = 1  # now counts as scenery: blocks tanks and shells
	collision_mask = 0
	NavGrid.refresh_area(global_position, 1.0)
	if not NavGrid.all_connected():
		# This wreck would wall off part of the map: let tanks squeeze past it
		# (it still stops shells and blocks line of sight).
		collision_layer = WRECK_LAYER
		NavGrid.refresh_area(global_position, 1.0)
	_hull_mat.albedo_color = Color(0.09, 0.08, 0.07)
	_turret_mat.albedo_color = Color(0.11, 0.1, 0.09)
	_trim_mat.albedo_color = Color(0.06, 0.05, 0.05)
	_turret.position.y += 0.02
	_turret.rotation.z = randf_range(-0.12, 0.12)  # knocked off its ring
	_barrel.rotation.x = randf_range(-0.25, -0.05)  # barrel drooping
	for child: Node in get_children():
		if child is HealthBar:
			child.queue_free()
	if _damage_smoke != null:
		_damage_smoke.queue_free()  # the wreck fire's smoke takes over
		_damage_smoke = null
	if burning:
		_burn_left = WRECK_BURN_TIME
		_fire = FX.fire(self, Vector3(0.0, 0.6, 0.35), 1.0)
		_fire_light = FX.glow(self, Vector3(0.0, 0.06, 0.2), Color(1.0, 0.5, 0.2), 2.2, 0.5)


func _update_wreck(delta: float) -> void:
	if _burn_left <= 0.0:
		return
	_burn_left -= delta
	var strength: float = clampf(_burn_left / WRECK_BURN_TIME, 0.0, 1.0)
	if _fire_light != null:
		# Flickering firelight.
		var flicker: float = (0.15 + strength * 0.4) * randf_range(0.7, 1.3)
		(_fire_light.material_override as StandardMaterial3D).albedo_color.a = flicker
	# Ammunition cooking off now and then while it burns.
	if randf() < delta * 0.6 * strength:
		FX.impact(get_parent(), global_position + Vector3(randf_range(-0.4, 0.4), 0.8, randf_range(-0.4, 0.4)), "metal")
	if _burn_left <= 0.0:
		FX.stop_fire(_fire)
		_fire = null
		if _fire_light != null:
			_fire_light.queue_free()
			_fire_light = null


# --- Model ---------------------------------------------------------------
# Built from boxes and cylinders. Sizes are in meters; the hull is about
# 1.6 m long and 1.1 m wide, and its front points toward -Z.

func _build_model() -> void:
	_hull_mat = Shapes.mat(hull_color, 0.2, 0.9, true)
	_turret_mat = Shapes.mat(turret_color, 0.2, 0.9, true)
	_trim_mat = Shapes.mat(hull_color.darkened(0.3), 0.2, 0.9, true)
	var trim: StandardMaterial3D = _trim_mat
	var rubber := Shapes.mat(Color(0.1, 0.1, 0.1))
	var steel := Shapes.mat(Color(0.32, 0.32, 0.33), 0.55)
	var link_mat := Shapes.mat(Color(0.24, 0.23, 0.22), 0.4)
	var black := Shapes.mat(Color(0.04, 0.04, 0.05))
	var glass := Shapes.mat(Color(0.95, 0.9, 0.6))
	glass.emission_enabled = true
	glass.emission = Color(1.0, 0.9, 0.55)
	glass.emission_energy_multiplier = 0.6
	var canvas := Shapes.mat(Color(0.4, 0.36, 0.26))
	var drum := Shapes.mat(Color(0.24, 0.27, 0.2))

	_build_tracks(rubber, steel, link_mat)
	_build_hull(trim, steel, black, glass, canvas, drum, link_mat)
	_build_turret(trim, steel, black, glass, canvas)


func _build_tracks(rubber: Material, steel: Material, link_mat: Material) -> void:
	for side: float in [-1.0, 1.0]:
		var x: float = side * 0.42
		var wheel_turn := Vector3(0.0, 0.0, PI * 0.5)  # wheel axle along X
		# Track run, plus the drive sprocket (front) and idler (rear) as round ends.
		Shapes.box(self, Vector3(0.26, 0.38, 1.2), Vector3(x, 0.21, 0.0), rubber)
		Shapes.cylinder(self, 0.19, 0.19, 0.26, Vector3(x, 0.21, -0.6), rubber, wheel_turn)
		Shapes.cylinder(self, 0.19, 0.19, 0.26, Vector3(x, 0.21, 0.6), rubber, wheel_turn)
		Shapes.cylinder(self, 0.09, 0.09, 0.28, Vector3(x, 0.21, -0.6), steel, wheel_turn)
		Shapes.cylinder(self, 0.08, 0.08, 0.28, Vector3(x, 0.21, 0.6), steel, wheel_turn)
		# Road wheels peeking out of the outer side.
		for i: int in 5:
			var z: float = -0.44 + 0.22 * float(i)
			Shapes.cylinder(self, 0.12, 0.12, 0.05, Vector3(x + side * 0.14, 0.15, z), steel, wheel_turn)
			Shapes.cylinder(self, 0.05, 0.05, 0.06, Vector3(x + side * 0.15, 0.15, z), rubber, wheel_turn)
		# Tread links on top, which slide as the tank drives.
		for i: int in TREADS_PER_TRACK:
			_treads.append(Shapes.box(self, Vector3(0.27, 0.035, 0.06), Vector3(x, 0.41, 0.0), link_mat))


func _build_hull(trim: Material, steel: Material, black: Material, glass: Material,
		canvas: Material, drum: Material, link_mat: Material) -> void:
	# Lower and upper hull. The deck sits between the tracks so they stay visible.
	Shapes.box(self, Vector3(0.58, 0.32, 1.46), Vector3(0.0, 0.3, 0.0), _hull_mat)
	Shapes.box(self, Vector3(0.62, 0.1, 1.1), Vector3(0.0, 0.5, 0.06), _hull_mat)
	# Sloped front armor (glacis) and rear plate.
	Shapes.box(self, Vector3(0.62, 0.06, 0.4), Vector3(0.0, 0.43, -0.64), _hull_mat, Vector3(-0.45, 0.0, 0.0))
	Shapes.box(self, Vector3(0.62, 0.22, 0.05), Vector3(0.0, 0.42, 0.66), trim)
	# Fenders over the front and rear of the tracks.
	for side: float in [-1.0, 1.0]:
		var x: float = side * 0.42
		Shapes.box(self, Vector3(0.3, 0.025, 0.2), Vector3(x, 0.45, -0.72), trim)
		Shapes.box(self, Vector3(0.3, 0.025, 0.14), Vector3(x, 0.45, 0.74), trim)
		# Headlight with a guard.
		Shapes.cylinder(self, 0.04, 0.045, 0.06, Vector3(side * 0.28, 0.5, -0.8), glass, Vector3(PI * 0.5, 0.0, 0.0))
		Shapes.box(self, Vector3(0.1, 0.02, 0.03), Vector3(side * 0.28, 0.55, -0.82), steel)
		# Tow hooks and exhaust pipes.
		Shapes.box(self, Vector3(0.05, 0.05, 0.08), Vector3(side * 0.18, 0.3, -0.78), steel)
		Shapes.cylinder(self, 0.035, 0.035, 0.12, Vector3(side * 0.18, 0.45, 0.72), black, Vector3(PI * 0.5, 0.0, 0.0))
	# Spare track links bolted to the glacis.
	for i: int in 3:
		Shapes.box(self, Vector3(0.14, 0.03, 0.07), Vector3(-0.16 + 0.16 * float(i), 0.47, -0.62), link_mat, Vector3(-0.45, 0.0, 0.0))
	# Driver's hatch and periscope.
	Shapes.cylinder(self, 0.07, 0.07, 0.03, Vector3(-0.14, 0.56, -0.42), trim)
	Shapes.box(self, Vector3(0.08, 0.03, 0.03), Vector3(-0.14, 0.57, -0.5), black)
	# Engine deck: two grilles with slats.
	for side: float in [-1.0, 1.0]:
		Shapes.box(self, Vector3(0.24, 0.02, 0.24), Vector3(side * 0.15, 0.56, 0.48), black)
		for i: int in 4:
			Shapes.box(self, Vector3(0.22, 0.025, 0.02), Vector3(side * 0.15, 0.57, 0.39 + 0.06 * float(i)), steel)
	# Fuel drums strapped across the back.
	for side: float in [-1.0, 1.0]:
		Shapes.cylinder(self, 0.08, 0.08, 0.28, Vector3(side * 0.16, 0.6, 0.72), drum, Vector3(0.0, 0.0, PI * 0.5))
	# Toolbox and a shovel on the left, stowage on the right.
	Shapes.box(self, Vector3(0.1, 0.07, 0.3), Vector3(-0.26, 0.58, -0.18), trim)
	Shapes.box(self, Vector3(0.03, 0.02, 0.32), Vector3(0.27, 0.57, -0.2), steel)
	Shapes.box(self, Vector3(0.07, 0.02, 0.09), Vector3(0.27, 0.57, -0.4), steel)
	Shapes.box(self, Vector3(0.1, 0.08, 0.24), Vector3(0.26, 0.59, 0.18), canvas)


func _build_turret(trim: Material, steel: Material, black: Material, glass: Material, canvas: Material) -> void:
	_turret = Node3D.new()
	_turret.position = Vector3(0.0, 0.56, 0.06)
	add_child(_turret)
	# Turret ring and main body, with angled cheek armor at the front.
	Shapes.cylinder(_turret, 0.36, 0.38, 0.05, Vector3(0.0, 0.0, 0.0), trim)
	Shapes.box(_turret, Vector3(0.62, 0.22, 0.56), Vector3(0.0, 0.12, 0.02), _turret_mat)
	for side: float in [-1.0, 1.0]:
		Shapes.box(_turret, Vector3(0.24, 0.2, 0.3), Vector3(side * 0.2, 0.11, -0.28), _turret_mat, Vector3(0.0, side * 0.45, 0.0))
	Shapes.box(_turret, Vector3(0.56, 0.03, 0.5), Vector3(0.0, 0.245, 0.02), _turret_mat)
	# Rear bustle with a stowage basket full of gear.
	Shapes.box(_turret, Vector3(0.5, 0.17, 0.2), Vector3(0.0, 0.12, 0.38), _turret_mat)
	Shapes.box(_turret, Vector3(0.58, 0.02, 0.18), Vector3(0.0, 0.2, 0.56), steel)
	for side: float in [-1.0, 1.0]:
		Shapes.box(_turret, Vector3(0.02, 0.1, 0.2), Vector3(side * 0.29, 0.25, 0.56), steel)
	Shapes.box(_turret, Vector3(0.56, 0.02, 0.02), Vector3(0.0, 0.3, 0.65), steel)
	Shapes.box(_turret, Vector3(0.22, 0.08, 0.14), Vector3(-0.14, 0.25, 0.55), canvas)
	Shapes.box(_turret, Vector3(0.18, 0.1, 0.13), Vector3(0.12, 0.26, 0.56), canvas)
	# Commander's cupola with vision blocks and a hatch.
	var cupola := Vector3(0.15, 0.29, 0.12)
	Shapes.cylinder(_turret, 0.11, 0.12, 0.09, cupola, _turret_mat)
	for i: int in 6:
		var a: float = TAU * float(i) / 6.0
		Shapes.box(_turret, Vector3(0.04, 0.03, 0.03), cupola + Vector3(sin(a) * 0.11, 0.02, cos(a) * 0.11), black, Vector3(0.0, a, 0.0))
	Shapes.cylinder(_turret, 0.09, 0.09, 0.025, cupola + Vector3(0.0, 0.055, 0.0), trim)
	# Loader's hatch with a roof machine gun.
	Shapes.box(_turret, Vector3(0.16, 0.025, 0.16), Vector3(-0.15, 0.27, 0.1), trim)
	Shapes.box(_turret, Vector3(0.05, 0.08, 0.05), Vector3(-0.15, 0.31, -0.04), steel)
	Shapes.cylinder(_turret, 0.015, 0.015, 0.34, Vector3(-0.15, 0.35, -0.16), black, Vector3(PI * 0.5, 0.0, 0.0))
	Shapes.box(_turret, Vector3(0.05, 0.05, 0.12), Vector3(-0.15, 0.35, -0.02), black)
	# Gunner's sight.
	Shapes.box(_turret, Vector3(0.1, 0.07, 0.1), Vector3(0.18, 0.28, -0.14), _turret_mat)
	Shapes.box(_turret, Vector3(0.08, 0.04, 0.01), Vector3(0.18, 0.29, -0.195), glass)
	# Smoke grenade launchers on both cheeks.
	for side: float in [-1.0, 1.0]:
		for i: int in 3:
			var at := Vector3(side * (0.27 + 0.04 * float(i)), 0.2, -0.12 - 0.05 * float(i))
			Shapes.cylinder(_turret, 0.025, 0.025, 0.1, at, black, Vector3(PI * 0.4, 0.0, -side * 0.6))
	# Two whip antennas at the back.
	for side: float in [-1.0, 1.0]:
		Shapes.cylinder(_turret, 0.025, 0.03, 0.04, Vector3(side * 0.22, 0.26, 0.4), steel)
		Shapes.cylinder(_turret, 0.006, 0.01, 0.6, Vector3(side * 0.22, 0.57, 0.4), black)
	# Gun mantlet, then the barrel (its own node so it can recoil).
	Shapes.box(_turret, Vector3(0.26, 0.17, 0.12), Vector3(0.0, 0.12, -0.38), _turret_mat)
	_barrel = Node3D.new()
	_barrel.position = Vector3(0.0, 0.12, BARREL_REST_Z)
	_turret.add_child(_barrel)
	var along := Vector3(PI * 0.5, 0.0, 0.0)  # cylinder laid along Z
	Shapes.cylinder(_barrel, 0.045, 0.055, 1.02, Vector3(0.0, 0.0, -0.51), _turret_mat, along)
	Shapes.cylinder(_barrel, 0.075, 0.075, 0.2, Vector3(0.0, 0.0, -0.5), _turret_mat, along)
	Shapes.cylinder(_barrel, 0.06, 0.06, 0.03, Vector3(0.0, 0.0, -0.2), trim, along)
	Shapes.box(_barrel, Vector3(0.15, 0.1, 0.15), Vector3(0.0, 0.0, -1.06), trim)
	for side: float in [-1.0, 1.0]:
		Shapes.box(_barrel, Vector3(0.01, 0.06, 0.04), Vector3(side * 0.076, 0.0, -1.06), black)


func _update_treads() -> void:
	var count: int = TREADS_PER_TRACK
	for i: int in _treads.size():
		var slot: int = i % count
		var z: float = -TREAD_RUN * 0.5 + TREAD_SPACING * float(slot) + _track_offset
		# Moving forward means the top of the track slides backward (+Z).
		_treads[i].position.z = -z
	_recoil = move_toward(_recoil, 0.0, get_physics_process_delta_time() * 0.9)
	_barrel.position.z = BARREL_REST_Z + _recoil
