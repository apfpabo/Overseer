class_name NavGrid
extends Node
## Pathfinding for enemy tanks. Splits the map into half-meter cells, marks the
## cells a tank can't fit in (near walls, rubble, wrecks...), and finds routes
## around them with A*. Call refresh_area() when the map changes (crate broken,
## new wreck).

const CELL: float = 0.5
const TANK_RADIUS: float = 0.62
const OBSTACLE_MASK: int = 1

static var current: NavGrid = null

var _grid := AStarGrid2D.new()
var _probe := SphereShape3D.new()
var _space: PhysicsDirectSpaceState3D
var _ready_to_use: bool = false
## Places that must stay reachable from each other (player start, enemy spawns).
var key_points: Array[Vector3] = []


## Finds a route between two ground positions. Returns world points (may be empty).
static func find_path(from: Vector3, to: Vector3) -> PackedVector3Array:
	if current == null or not current._ready_to_use:
		return PackedVector3Array()
	return current._find_path(from, to)


## True if every key point can still reach the first one.
static func all_connected() -> bool:
	if current == null or not current._ready_to_use or current.key_points.size() < 2:
		return true
	var g: NavGrid = current
	var start: Vector2i = g._nearest_open(g._cell_of(g.key_points[0]))
	for i: int in range(1, g.key_points.size()):
		var goal: Vector2i = g._nearest_open(g._cell_of(g.key_points[i]))
		if start.x < 0 or goal.x < 0 or g._grid.get_id_path(start, goal).is_empty():
			return false
	return true


## Re-checks the cells around a position (call after the map changed there).
static func refresh_area(at: Vector3, radius: float) -> void:
	if current == null or not current._ready_to_use:
		return
	current._refresh(at, radius)


func _ready() -> void:
	current = self


func _exit_tree() -> void:
	if current == self:
		current = null


## Scans the whole map. `space` is the 3D physics world to check against.
## `open_spot` is any point in the open streets (e.g. the player's start):
## pockets that can't be reached from it are sealed off.
func build(space: PhysicsDirectSpaceState3D, map_size: Vector2, open_spot: Vector3) -> void:
	_space = space
	_probe.radius = TANK_RADIUS
	_grid.region = Rect2i(0, 0, ceili(map_size.x / CELL), ceili(map_size.y / CELL))
	_grid.cell_size = Vector2(CELL, CELL)
	_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_grid.update()
	for x: int in _grid.region.size.x:
		for y: int in _grid.region.size.y:
			var cell := Vector2i(x, y)
			_grid.set_point_solid(cell, _blocked(cell))
	_seal_pockets(_cell_of(open_spot))
	_ready_to_use = true


## Marks every open cell that can't be reached from `start` as blocked, so
## tanks never plan routes into closed-off corners of the ruins.
func _seal_pockets(start: Vector2i) -> void:
	var reached: Dictionary = {start: true}
	var queue: Array[Vector2i] = [start]
	var steps: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_back()
		for step: Vector2i in steps:
			var next: Vector2i = cell + step
			if _grid.is_in_boundsv(next) and not reached.has(next) and not _grid.is_point_solid(next):
				reached[next] = true
				queue.append(next)
	for x: int in _grid.region.size.x:
		for y: int in _grid.region.size.y:
			var cell := Vector2i(x, y)
			if not reached.has(cell):
				_grid.set_point_solid(cell, true)


func _refresh(at: Vector3, radius: float) -> void:
	var c: Vector2i = _cell_of(at)
	var r: int = ceili((radius + TANK_RADIUS) / CELL)
	for x: int in range(c.x - r, c.x + r + 1):
		for y: int in range(c.y - r, c.y + r + 1):
			var cell := Vector2i(x, y)
			if _grid.is_in_boundsv(cell):
				_grid.set_point_solid(cell, _blocked(cell))


func _blocked(cell: Vector2i) -> bool:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = _probe
	query.collision_mask = OBSTACLE_MASK
	query.transform = Transform3D(Basis.IDENTITY, _center_of(cell) + Vector3.UP * 0.5)
	return not _space.intersect_shape(query, 1).is_empty()


func _find_path(from: Vector3, to: Vector3) -> PackedVector3Array:
	var start: Vector2i = _nearest_open(_cell_of(from))
	var goal: Vector2i = _cell_of(to)
	var points := PackedVector3Array()
	if start.x < 0:
		return points
	var ids: Array[Vector2i] = _grid.get_id_path(start, goal, true)
	for cell: Vector2i in ids:
		points.append(_center_of(cell))
	return points


## The closest walkable cell (a tank hugging a wall stands in a "blocked" cell).
func _nearest_open(cell: Vector2i) -> Vector2i:
	for r: int in 5:
		for x: int in range(cell.x - r, cell.x + r + 1):
			for y: int in range(cell.y - r, cell.y + r + 1):
				var c := Vector2i(x, y)
				if _grid.is_in_boundsv(c) and not _grid.is_point_solid(c):
					return c
	return Vector2i(-1, -1)


func _cell_of(at: Vector3) -> Vector2i:
	var c := Vector2i(floori(at.x / CELL), floori(at.z / CELL))
	return c.clamp(_grid.region.position, _grid.region.end - Vector2i.ONE)


func _center_of(cell: Vector2i) -> Vector3:
	return Vector3((float(cell.x) + 0.5) * CELL, 0.0, (float(cell.y) + 0.5) * CELL)
