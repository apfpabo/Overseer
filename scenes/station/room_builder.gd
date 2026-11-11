class_name RoomBuilder
extends RefCounted
## Builds room pieces from boxes on the 1 m grid (D-005): floors and walls.
## Matches the art test: alternating grey floor cells over a dark trim, and
## 1.6 m walls with a lighter cap.

const WALL_HEIGHT := 1.6
const WALL_THICKNESS := 0.2
const CELL_GAP := 0.04


## Floor for a rectangle of cells (x, z in meters, whole numbers).
static func build_floor(parent: Node3D, cells: Rect2i) -> void:
	var center := Vector3(cells.position.x + cells.size.x * 0.5, -0.07, cells.position.y + cells.size.y * 0.5)
	BoxBuilder.box(parent, Vector3(cells.size.x + 0.2, 0.1, cells.size.y + 0.2), center, Palette.FLOOR_TRIM)
	for x in range(cells.position.x, cells.end.x):
		for z in range(cells.position.y, cells.end.y):
			var color: Color = Palette.FLOOR_A if (x + z) % 2 == 0 else Palette.FLOOR_B
			BoxBuilder.box(parent, Vector3(1.0 - CELL_GAP, 0.1, 1.0 - CELL_GAP), Vector3(x + 0.5, -0.05, z + 0.5), color)


## A straight wall between two floor points (x, z) that share an x or a z.
## Returns its node: scale its y to lower it for the cut-away view.
static func build_wall(parent: Node3D, from: Vector2, to: Vector2) -> Node3D:
	var wall := Node3D.new()
	var mid: Vector2 = (from + to) * 0.5
	wall.position = Vector3(mid.x, 0.0, mid.y)
	parent.add_child(wall)
	var length: float = from.distance_to(to) + WALL_THICKNESS
	var along_x: bool = is_equal_approx(from.y, to.y)
	var body_size := Vector3(length, WALL_HEIGHT, WALL_THICKNESS) if along_x else Vector3(WALL_THICKNESS, WALL_HEIGHT, length)
	var cap_size := Vector3(body_size.x + 0.02, 0.05, body_size.z + 0.02)
	BoxBuilder.box(wall, body_size, Vector3(0.0, WALL_HEIGHT * 0.5, 0.0), Palette.WALL)
	BoxBuilder.box(wall, cap_size, Vector3(0.0, WALL_HEIGHT + 0.025, 0.0), Palette.WALL_CAP)
	return wall
