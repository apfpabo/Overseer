class_name HealthBar
extends Node2D
## A small health bar that floats above a tank and does not rotate with it.

var tank: Tank = null


func _ready() -> void:
	top_level = true
	z_index = 10


func _process(_delta: float) -> void:
	if tank == null or not is_instance_valid(tank):
		return
	global_position = tank.global_position + Vector2(0.0, -36.0)
	queue_redraw()


func _draw() -> void:
	if tank == null or tank.max_health <= 0:
		return
	var width: float = 40.0
	var ratio: float = clampf(float(tank.health) / float(tank.max_health), 0.0, 1.0)
	draw_rect(Rect2(-width * 0.5 - 1.0, -1.0, width + 2.0, 7.0), Color(0.0, 0.0, 0.0, 0.7))
	draw_rect(Rect2(-width * 0.5, 0.0, width * ratio, 5.0), Color(0.9, 0.25, 0.2))
