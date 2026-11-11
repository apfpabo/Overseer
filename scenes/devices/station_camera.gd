class_name StationCamera
extends Node3D
## A fixed station camera mounted on a wall: a small box with a lens light.
## It is a feed marker; the one render camera (FeedCamera) jumps to its view.

var feed_name: String = "CAM"
var room_id: StringName = &""
## Point on the floor the feed is centred on.
var view_target: Vector3 = Vector3.ZERO
## Zoom: meters of world shown from the top to the bottom of the screen.
var view_height: float = 7.0


func _ready() -> void:
	BoxBuilder.box(self, Vector3(0.22, 0.16, 0.3), Vector3.ZERO, Palette.CAMERA_BODY)
	BoxBuilder.glow_box(self, Vector3(0.1, 0.08, 0.06), Vector3(0.0, 0.0, 0.17), Palette.CAMERA_LENS, 1.0)
