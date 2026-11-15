class_name EnemyTank
extends Tank
## A computer-controlled tank. Drives toward the player, keeps some distance,
## and fires when it has a clear shot.

const PREFERRED_DISTANCE: float = 260.0
const WALL_MASK: int = 1

var target: Node2D = null
var _stuck_time: float = 0.0
var _unstick_left: float = 0.0
var _unstick_steer: float = 1.0
var _strafe_sign: float = 1.0
var _think_left: float = 0.0


func _ready() -> void:
	super()
	_strafe_sign = 1.0 if randf() < 0.5 else -1.0
	var bar := HealthBar.new()
	bar.tank = self
	add_child(bar)


func _physics_process(delta: float) -> void:
	super(delta)
	if target == null or not is_instance_valid(target):
		velocity = Vector2.ZERO
		return
	var to_target: Vector2 = target.global_position - global_position
	var distance: float = to_target.length()
	var sees_target: bool = _has_line_of_sight(target.global_position)

	# Occasionally change strafing direction so they're less predictable.
	_think_left -= delta
	if _think_left <= 0.0:
		_think_left = randf_range(1.5, 3.5)
		_strafe_sign = -_strafe_sign

	# Pick where the hull wants to go.
	var wanted_dir: Vector2
	var drive: float = 1.0
	if _unstick_left > 0.0:
		_unstick_left -= delta
		drive_tank(-0.8, _unstick_steer, delta)
	else:
		if not sees_target or distance > PREFERRED_DISTANCE + 40.0:
			wanted_dir = to_target.normalized()
		elif distance < PREFERRED_DISTANCE - 60.0:
			wanted_dir = -to_target.normalized()
		else:
			wanted_dir = to_target.normalized().orthogonal() * _strafe_sign
			drive = 0.6
		var angle_diff: float = wrapf(wanted_dir.angle() - rotation, -PI, PI)
		var steer: float = clampf(angle_diff * 2.0, -1.0, 1.0)
		# Slow down while turning sharply.
		if absf(angle_diff) > 1.2:
			drive *= 0.2
		drive_tank(drive, steer, delta)
		# If we're trying to move but not getting anywhere, back up and turn.
		if get_real_velocity().length() < 15.0:
			_stuck_time += delta
			if _stuck_time > 0.6:
				_stuck_time = 0.0
				_unstick_left = randf_range(0.5, 0.9)
				_unstick_steer = 1.0 if randf() < 0.5 else -1.0
		else:
			_stuck_time = 0.0

	# Turret: aim at the player, fire when lined up and the shot is clear.
	aim_turret_toward(to_target.angle(), delta)
	var aim_error: float = absf(wrapf(to_target.angle() - turret_angle, -PI, PI))
	if sees_target and aim_error < 0.12 and distance < 650.0:
		fire()


func _has_line_of_sight(point: Vector2) -> bool:
	var query := PhysicsRayQueryParameters2D.create(global_position, point, WALL_MASK)
	var hit: Dictionary = get_world_2d().direct_space_state.intersect_ray(query)
	return hit.is_empty()
