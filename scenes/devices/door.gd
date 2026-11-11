class_name Door
extends Node3D
## A sliding door: two orange panels with a hazard stripe and a status light
## (green = open, red = closed). The player toggles it by clicking it.
## Built along local X; rotate the node to fit the wall it sits in.

signal toggled(is_open: bool)

const WIDTH := 1.0
const HEIGHT := 1.5
const SLIDE_TIME := 0.4
## Collision layer used to find doors under the mouse.
const CLICK_LAYER := 2

var is_open: bool = false
var device_name: String = "Door"

var _open_amount: float = 0.0
var _left_panel: Node3D
var _right_panel: Node3D
var _status_light: MeshInstance3D


func _ready() -> void:
	_build()
	_update_status_light()


func _process(delta: float) -> void:
	var target: float = 1.0 if is_open else 0.0
	if is_equal_approx(_open_amount, target):
		return
	_open_amount = move_toward(_open_amount, target, delta / SLIDE_TIME)
	var slide: float = _open_amount * WIDTH * 0.45
	_left_panel.position.x = -WIDTH * 0.25 - slide
	_right_panel.position.x = WIDTH * 0.25 + slide


## True when crew and borgs can walk through (fully or nearly open).
func is_passable() -> bool:
	return _open_amount > 0.8


func toggle() -> void:
	set_open(not is_open)


func set_open(value: bool) -> void:
	if value == is_open:
		return
	is_open = value
	_update_status_light()
	toggled.emit(is_open)
	Events.device_changed.emit(self)


func _build() -> void:
	_left_panel = _panel(-WIDTH * 0.25)
	_right_panel = _panel(WIDTH * 0.25)
	# Frame: two posts and a lintel, so the doorway reads even when open.
	for side: float in [-1.0, 1.0]:
		BoxBuilder.box(self, Vector3(0.1, HEIGHT + 0.1, 0.26), Vector3(side * (WIDTH * 0.5 + 0.05), (HEIGHT + 0.1) * 0.5, 0.0), Palette.DOOR_FRAME)
	BoxBuilder.box(self, Vector3(WIDTH + 0.2, 0.1, 0.26), Vector3(0.0, HEIGHT + 0.05, 0.0), Palette.DOOR_FRAME)
	_status_light = BoxBuilder.glow_box(self, Vector3(0.22, 0.08, 0.3), Vector3(0.0, HEIGHT + 0.14, 0.0), Palette.DOOR_CLOSED, 3.0)

	var body := StaticBody3D.new()
	body.collision_layer = CLICK_LAYER
	body.collision_mask = 0
	body.set_meta(&"door", self)
	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(WIDTH + 0.2, HEIGHT + 0.3, 0.6)
	shape.shape = box_shape
	shape.position = Vector3(0.0, (HEIGHT + 0.3) * 0.5, 0.0)
	body.add_child(shape)
	add_child(body)


func _panel(x: float) -> Node3D:
	var panel := Node3D.new()
	panel.position = Vector3(x, 0.0, 0.0)
	add_child(panel)
	BoxBuilder.box(panel, Vector3(WIDTH * 0.5, HEIGHT, 0.12), Vector3(0.0, HEIGHT * 0.5, 0.0), Palette.DOOR_PANEL)
	BoxBuilder.box(panel, Vector3(WIDTH * 0.5, 0.1, 0.14), Vector3(0.0, HEIGHT * 0.55, 0.0), Palette.HAZARD_STRIPE)
	return panel


func _update_status_light() -> void:
	var color: Color = Palette.DOOR_OPEN if is_open else Palette.DOOR_CLOSED
	var mat := _status_light.material_override as StandardMaterial3D
	mat.albedo_color = color
	mat.emission = color
