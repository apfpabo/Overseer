class_name PlayerTank
extends Tank
## The tank you control. W/S drive, A/D turn, the turret follows the mouse,
## left click or Space fires.


func _physics_process(delta: float) -> void:
	super(delta)
	var drive: float = Input.get_axis("tank_back", "tank_forward")
	var steer: float = Input.get_axis("tank_left", "tank_right")
	# When reversing, flip steering so it feels like backing up a car.
	if drive < 0.0:
		steer = -steer
	drive_tank(drive, steer, delta)
	var to_mouse: Vector2 = get_global_mouse_position() - global_position
	aim_turret_toward(to_mouse.angle(), delta)
	if Input.is_action_pressed("tank_fire"):
		fire()
