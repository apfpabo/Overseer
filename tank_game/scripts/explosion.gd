class_name Explosion
extends Node2D
## A short expanding flash used for shots, hits and destroyed tanks.

const DURATION: float = 0.35

var radius: float = 20.0
var color: Color = Color.ORANGE
var _age: float = 0.0


static func spawn(parent: Node, at: Vector2, size: float, tint: Color) -> void:
	if parent == null:
		return
	var boom := Explosion.new()
	boom.global_position = at
	boom.radius = size
	boom.color = tint
	boom.z_index = 5
	parent.add_child(boom)


func _process(delta: float) -> void:
	_age += delta
	if _age >= DURATION:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var t: float = _age / DURATION
	var r: float = radius * (0.4 + 0.6 * t)
	draw_circle(Vector2.ZERO, r, Color(color, 1.0 - t))
	draw_circle(Vector2.ZERO, r * 0.5, Color(1.0, 1.0, 0.85, 1.0 - t))
