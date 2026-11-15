class_name EnemyTank
extends Tank
## A computer-controlled tank. Drives toward the player, keeps some distance,
## and fires when it has a clear shot.

const PREFERRED_DISTANCE: float = 8.0
const FIRE_RANGE: float = 20.0
const WALL_MASK: int = 1 | 8  # walls and wrecks block sight

var target: Node3D = null
var _stuck_time: float = 0.0
var _unstick_left: float = 0.0
var _unstick_turn: float = 1.0
var _strafe_sign: float = 1.0
var _think_left: float = 0.0
var _path := PackedVector3Array()
var _path_index: int = 0
var _repath_left: float = 0.0


func _ready() -> void:
	super()
	_strafe_sign = 1.0 if randf() < 0.5 else -1.0
	var bar := HealthBar.new()
	bar.tank = self
	add_child(bar)


func _physics_process(delta: float) -> void:
	super(delta)
	if is_wreck:
		return
	if target == null or not is_instance_valid(target) or (target is Tank and (target as Tank).is_wreck):
		velocity = Vector3.ZERO
		return
	var to_target: Vector3 = target.global_position - global_position
	to_target.y = 0.0
	var distance: float = to_target.length()
	var toward: Vector3 = to_target.normalized()
	var sees_target: bool = _has_line_of_sight(target.global_position)

	# Occasionally change strafing direction so they're less predictable.
	_think_left -= delta
	if _think_left <= 0.0:
		_think_left = randf_range(1.5, 3.5)
		_strafe_sign = -_strafe_sign

	if _unstick_left > 0.0:
		_unstick_left -= delta
		drive_tank(-0.8, _unstick_turn, delta)
	else:
		var wanted_dir: Vector3
		var drive: float = 1.0
		if not sees_target or distance > PREFERRED_DISTANCE + 1.25:
			wanted_dir = _route_toward(target.global_position, toward, delta)
		elif distance < PREFERRED_DISTANCE - 1.9:
			wanted_dir = -toward
		else:
			wanted_dir = toward.cross(Vector3.UP) * _strafe_sign
			drive = 0.6
		var angle_diff: float = wrapf(yaw_of(wanted_dir) - rotation.y, -PI, PI)
		var turn: float = clampf(angle_diff * 2.0, -1.0, 1.0)
		# Slow down while turning sharply.
		if absf(angle_diff) > 1.2:
			drive *= 0.2
		drive_tank(drive, turn, delta)
		# If we're trying to move but not getting anywhere, back up and turn.
		if get_real_velocity().length() < 0.5:
			_stuck_time += delta
			if _stuck_time > 0.6:
				_stuck_time = 0.0
				_unstick_left = randf_range(0.5, 0.9)
				_unstick_turn = 1.0 if randf() < 0.5 else -1.0
		else:
			_stuck_time = 0.0

	# Turret: aim at the player, fire when lined up and the shot is clear.
	var target_yaw: float = yaw_of(toward)
	aim_turret_toward(target_yaw, delta)
	var aim_error: float = absf(wrapf(target_yaw - turret_yaw, -PI, PI))
	if sees_target and aim_error < 0.12 and distance < FIRE_RANGE:
		fire()


## Direction to drive to reach `goal` around obstacles, using the nav grid.
## Falls back to `direct` if there is no route.
func _route_toward(goal: Vector3, direct: Vector3, delta: float) -> Vector3:
	_repath_left -= delta
	if _repath_left <= 0.0 or _path_index >= _path.size():
		_repath_left = randf_range(0.5, 0.8)
		_path = NavGrid.find_path(global_position, goal)
		_path_index = 0
	var flat_pos := Vector3(global_position.x, 0.0, global_position.z)
	while _path_index < _path.size() and flat_pos.distance_to(_path[_path_index]) < 0.8:
		_path_index += 1
	if _path_index >= _path.size():
		return direct
	return (_path[_path_index] - flat_pos).normalized()


func _has_line_of_sight(point: Vector3) -> bool:
	var from: Vector3 = global_position + Vector3.UP * MUZZLE_HEIGHT
	var to: Vector3 = Vector3(point.x, MUZZLE_HEIGHT, point.z)
	var query := PhysicsRayQueryParameters3D.create(from, to, WALL_MASK)
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	return hit.is_empty()
