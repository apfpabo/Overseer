class_name Block
extends StaticBody2D
## A solid rectangle: an unbreakable wall, or a breakable crate.

var size: Vector2 = Vector2(32.0, 32.0)
var color: Color = Color(0.4, 0.4, 0.42)
var breakable: bool = false
var health: int = 3


static func make(at: Vector2, block_size: Vector2, block_color: Color, is_breakable: bool) -> Block:
	var block := Block.new()
	block.position = at
	block.size = block_size
	block.color = block_color
	block.breakable = is_breakable
	return block


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	add_child(shape)


func take_damage(amount: int) -> void:
	if not breakable:
		return
	health -= amount
	queue_redraw()
	if health <= 0:
		Explosion.spawn(get_parent(), global_position, 28.0, Color(0.85, 0.6, 0.3))
		queue_free()


func _draw() -> void:
	var rect := Rect2(-size * 0.5, size)
	draw_rect(rect, color)
	draw_rect(rect, color.darkened(0.35), false, 2.0)
	if breakable:
		# Wooden crate: cross planks, darker the more damaged it is.
		var plank: Color = color.darkened(0.25 + 0.15 * float(3 - health))
		draw_line(rect.position, rect.end, plank, 3.0)
		draw_line(Vector2(rect.end.x, rect.position.y), Vector2(rect.position.x, rect.end.y), plank, 3.0)
