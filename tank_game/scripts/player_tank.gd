class_name PlayerTank
extends Tank
## The tank you control. W/S drive, A/D turn, the turret follows the mouse,
## left click or Space fires.

## The camera used to work out where the mouse points on the ground.
var aim_camera: Camera3D = null


func _physics_process(delta: float) -> void:
	super(delta)
	if is_wreck:
		return
	var drive: float = Input.get_axis("tank_back", "tank_forward")
	var turn: float = Input.get_axis("tank_right", "tank_left")
	# When reversing, flip steering so it feels like backing up a car.
	if drive < 0.0:
		turn = -turn
	drive_tank(drive, turn, delta)
	var aim_point: Variant = _mouse_on_ground()
	if aim_point != null:
		var to_mouse: Vector3 = (aim_point as Vector3) - global_position
		to_mouse.y = 0.0
		if to_mouse.length() > 0.1:
			aim_turret_toward(yaw_of(to_mouse), delta)
	if Input.is_action_pressed("tank_fire"):
		fire()


## Returns the point on the ground under the mouse, or null.
func _mouse_on_ground() -> Variant:
	if aim_camera == null:
		return null
	var mouse: Vector2 = get_viewport().get_mouse_position()
	var origin: Vector3 = aim_camera.project_ray_origin(mouse)
	var normal: Vector3 = aim_camera.project_ray_normal(mouse)
	return Plane(Vector3.UP, 0.0).intersects_ray(origin, normal)
