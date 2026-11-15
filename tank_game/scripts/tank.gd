class_name Tank
extends CharacterBody2D
## Shared code for every tank: movement body, turret, shooting, health.
## The tank faces +X (right) when rotation is 0. Drawn with shapes in _draw().

signal health_changed(current: int, maximum: int)
signal died(tank: Tank)

const BODY_SIZE: Vector2 = Vector2(44.0, 34.0)
const BARREL_LENGTH: float = 30.0

@export var team: String = "player"
@export var max_health: int = 5
@export var move_speed: float = 170.0
@export var turn_speed: float = 2.6  # radians per second
@export var turret_turn_speed: float = 6.0  # radians per second
@export var fire_cooldown: float = 0.5
@export var shell_speed: float = 520.0
@export var shell_damage: int = 1
@export var hull_color: Color = Color(0.32, 0.5, 0.28)
@export var turret_color: Color = Color(0.42, 0.62, 0.36)

var health: int = 0
## Turret direction in world space (radians), independent of the hull.
var turret_angle: float = 0.0
var _cooldown_left: float = 0.0
var _flash_left: float = 0.0
var _track_offset: float = 0.0


func _ready() -> void:
	health = max_health
	turret_angle = rotation
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = BODY_SIZE
	shape.shape = rect
	add_child(shape)


func _physics_process(delta: float) -> void:
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)
	if _flash_left > 0.0:
		_flash_left -= delta
	queue_redraw()


## Drives the hull. `drive` is -1..1 (back/forward), `steer` is -1..1 (left/right).
func drive_tank(drive: float, steer: float, delta: float) -> void:
	rotation += steer * turn_speed * delta
	var speed: float = move_speed if drive >= 0.0 else move_speed * 0.6
	velocity = transform.x * drive * speed
	move_and_slide()
	_track_offset = fmod(_track_offset + drive * speed * delta, 8.0)


## Turns the turret toward a world-space angle, limited by turret_turn_speed.
func aim_turret_toward(target_angle: float, delta: float) -> void:
	var diff: float = wrapf(target_angle - turret_angle, -PI, PI)
	var step: float = turret_turn_speed * delta
	turret_angle += clampf(diff, -step, step)


func can_fire() -> bool:
	return _cooldown_left <= 0.0


func fire() -> void:
	if not can_fire():
		return
	_cooldown_left = fire_cooldown
	var dir := Vector2.from_angle(turret_angle)
	var shell := Shell.new()
	shell.team = team
	shell.damage = shell_damage
	shell.velocity = dir * shell_speed
	shell.global_position = global_position + dir * (BARREL_LENGTH + 6.0)
	get_parent().add_child(shell)
	Explosion.spawn(get_parent(), shell.global_position, 7.0, Color(1.0, 0.85, 0.4))


func take_damage(amount: int) -> void:
	if health <= 0:
		return
	health -= amount
	_flash_left = 0.12
	health_changed.emit(health, max_health)
	if health <= 0:
		Explosion.spawn(get_parent(), global_position, 46.0, Color(1.0, 0.55, 0.15))
		died.emit(self)
		queue_free()


func _draw() -> void:
	var hull: Color = Color.WHITE if _flash_left > 0.0 else hull_color
	var turret: Color = Color.WHITE if _flash_left > 0.0 else turret_color
	var half: Vector2 = BODY_SIZE * 0.5
	var track_color := Color(0.12, 0.12, 0.12)
	# Tracks (top and bottom), with moving tread lines.
	for side: float in [-1.0, 1.0]:
		var track := Rect2(Vector2(-half.x, side * half.y - 5.0), Vector2(BODY_SIZE.x, 10.0))
		draw_rect(track, track_color)
		var x: float = -half.x + _track_offset
		while x < half.x:
			draw_line(Vector2(x, track.position.y), Vector2(x, track.end.y), Color(0.3, 0.3, 0.3), 2.0)
			x += 8.0
	# Hull, with a darker front plate so you can tell which way is forward.
	draw_rect(Rect2(Vector2(-half.x + 2.0, -half.y + 5.0), Vector2(BODY_SIZE.x - 4.0, BODY_SIZE.y - 10.0)), hull)
	draw_rect(Rect2(Vector2(half.x - 8.0, -half.y + 5.0), Vector2(6.0, BODY_SIZE.y - 10.0)), hull.darkened(0.3))
	# Turret: drawn in local space, so undo the hull rotation.
	var local_turret: float = turret_angle - rotation
	var barrel_dir := Vector2.from_angle(local_turret)
	draw_line(Vector2.ZERO, barrel_dir * BARREL_LENGTH, turret.darkened(0.35), 7.0)
	draw_line(Vector2.ZERO, barrel_dir * BARREL_LENGTH, turret, 4.0)
	draw_circle(Vector2.ZERO, 11.0, turret.darkened(0.35))
	draw_circle(Vector2.ZERO, 9.0, turret)
