class_name CrewMember
extends Node3D
## A crew member who wanders between rooms. To change rooms they walk to the
## door; if it is closed they wait in front of it, and give up after a while.
## Real needs, jobs and orders come in later milestones.

enum State { IDLE, WALKING, WAITING_FOR_DOOR }

const SPEED := 1.3
const STRIDE_RATE := 7.0
const ARRIVE_DISTANCE := 0.05
const DOOR_PATIENCE := 6.0
const ROOM_MARGIN := 0.7

var display_name: String = "Crew"
## Walkable rooms as rectangles on the floor (x, z). Set before adding to the tree.
var rooms: Array[Rect2] = []
## Optional door joining rooms[0] and rooms[1].
var door: Door
## Where to stand in front of the door, one point per room: [side of room 0, side of room 1].
var door_sides: Array[Vector3] = []
## Furniture footprints (x, z) to avoid when picking where to walk.
var blockers: Array[Rect2] = []

var _model: CrewModel
var _state: State = State.IDLE
var _route: Array[Vector3] = []
## Index in _route that needs the door open before walking toward it (-1 = none).
var _door_step: int = -1
var _timer: float = 0.0
var _walk_phase: float = 0.0
var _rng: RandomNumberGenerator


## Builds the model. `suit` is the job color from Palette, `job` one of
## the CrewModel.JOB_* constants.
func setup(suit: Color, job: StringName, rng: RandomNumberGenerator) -> void:
	_rng = rng
	_model = CrewModel.new()
	add_child(_model)
	_model.build(suit, job)
	_timer = _rng.randf_range(0.2, 2.0)


func _process(delta: float) -> void:
	match _state:
		State.IDLE:
			_model.set_walk_pose(0.0, 0.0)
			_timer -= delta
			if _timer <= 0.0:
				_plan_new_route()
		State.WAITING_FOR_DOOR:
			_model.set_walk_pose(0.0, 0.0)
			_timer -= delta
			if door != null and door.is_passable():
				_state = State.WALKING
			elif _timer <= 0.0:
				_go_idle()
		State.WALKING:
			_walk(delta)


func _walk(delta: float) -> void:
	if _route.is_empty():
		_go_idle()
		return
	if _door_step == 0 and door != null and not door.is_passable():
		_state = State.WAITING_FOR_DOOR
		_timer = DOOR_PATIENCE
		return
	var target: Vector3 = _route[0]
	var to_target: Vector3 = target - position
	to_target.y = 0.0
	var distance: float = to_target.length()
	if distance <= ARRIVE_DISTANCE:
		position = Vector3(target.x, position.y, target.z)
		_route.remove_at(0)
		_door_step -= 1
		return
	var direction: Vector3 = to_target / distance
	position += direction * minf(SPEED * delta, distance)
	rotation.y = atan2(direction.x, direction.z)
	_walk_phase += delta * STRIDE_RATE
	_model.set_walk_pose(_walk_phase, 1.0)


func _plan_new_route() -> void:
	_route.clear()
	_door_step = -1
	var here: int = _room_index_at(position)
	if here < 0:
		here = 0
	var there: int = _rng.randi_range(0, rooms.size() - 1)
	if there != here and door != null and door_sides.size() == 2:
		_route.append(door_sides[here])
		_route.append(door_sides[there])
		_door_step = 1
	else:
		there = here
	_route.append(_random_point_in(rooms[there]))
	_state = State.WALKING


func _go_idle() -> void:
	_route.clear()
	_door_step = -1
	_state = State.IDLE
	_timer = _rng.randf_range(1.0, 4.0)


func _room_index_at(pos: Vector3) -> int:
	for i in rooms.size():
		if rooms[i].has_point(Vector2(pos.x, pos.z)):
			return i
	return -1


## A random spot in `room`, away from the walls and not inside furniture.
func _random_point_in(room: Rect2) -> Vector3:
	var inner: Rect2 = room.grow(-ROOM_MARGIN)
	var point := Vector3.ZERO
	for attempt in 10:
		point = Vector3(
			_rng.randf_range(inner.position.x, inner.end.x),
			0.0,
			_rng.randf_range(inner.position.y, inner.end.y))
		if not _is_blocked(point):
			break
	return point


func _is_blocked(point: Vector3) -> bool:
	for blocker: Rect2 in blockers:
		if blocker.grow(0.35).has_point(Vector2(point.x, point.z)):
			return true
	return false
