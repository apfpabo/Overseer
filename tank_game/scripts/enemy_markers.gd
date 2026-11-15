class_name EnemyMarkers
extends Control
## Small red arrows at the screen edge pointing at enemy tanks that are
## off-screen.

const MARGIN: float = 10.0
const COLOR_ARROW: Color = Color(0.95, 0.3, 0.2)

var camera: Camera3D = null
var game: Node = null


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if camera == null or game == null:
		return
	var rect := Rect2(Vector2.ZERO, size)
	var center: Vector2 = size * 0.5
	for child: Node in game.get_children():
		if not (child is EnemyTank) or (child as EnemyTank).is_wreck:
			continue
		var enemy: EnemyTank = child
		var p: Vector2 = camera.unproject_position(enemy.global_position)
		if rect.grow(-4.0).has_point(p):
			continue
		var dir: Vector2 = (p - center).normalized()
		# Push the arrow out from the center until it reaches the margin.
		var half: Vector2 = center - Vector2(MARGIN, MARGIN)
		var t: float = minf(half.x / maxf(absf(dir.x), 0.001), half.y / maxf(absf(dir.y), 0.001))
		var at: Vector2 = (center + dir * t).floor()
		var side := Vector2(-dir.y, dir.x)
		var tip: Vector2 = at + dir * 5.0
		draw_colored_polygon(PackedVector2Array([tip, at - dir * 3.0 + side * 4.0, at - dir * 3.0 - side * 4.0]), COLOR_ARROW)
		draw_polyline(PackedVector2Array([tip, at - dir * 3.0 + side * 4.0, at - dir * 3.0 - side * 4.0, tip]), Color.BLACK, 1.0)
