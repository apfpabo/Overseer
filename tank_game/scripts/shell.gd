class_name Shell
extends Area2D
## A tank shell. Flies straight, damages the first tank or crate it hits,
## and disappears on walls.

const LIFETIME: float = 2.5

var team: String = "player"
var damage: int = 1
var velocity: Vector2 = Vector2.ZERO
var _age: float = 0.0
var _done: bool = false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 | 2 | 4  # walls/crates, player, enemies
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 4.0
	shape.shape = circle
	add_child(shape)
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	position += velocity * delta
	_age += delta
	if _age > LIFETIME:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
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
	Explosion.spawn(get_parent(), global_position, 12.0, Color(1.0, 0.75, 0.3))
	queue_free()


func _draw() -> void:
	var color: Color = Color(1.0, 0.95, 0.6) if team == "player" else Color(1.0, 0.5, 0.4)
	draw_line(Vector2.ZERO, -velocity.normalized() * 10.0, Color(color, 0.4), 3.0)
	draw_circle(Vector2.ZERO, 4.0, color)
