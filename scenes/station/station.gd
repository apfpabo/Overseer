class_name Station
extends Node3D
## The M1 test station: two rooms (Engineering, Medbay) joined by a sliding
## door, one camera per room, three crew and six borgs (one per module). Also owns lighting
## (normal / red alert / borg night view), the cut-away walls and the stress test.

signal feeds_changed

const CUTAWAY_SCALE := 0.12
const ROOM_SIZE := 5
const STRESS_GRID := 7
const STRESS_SPACING := 7
const STRESS_ORIGIN := Vector2i(0, 9)

## One borg per module file, placed in the test rooms (module id -> spot).
const BORG_SPOTS: Dictionary = {
	&"engineering": Vector3(2.2, 0.0, 3.1),
	&"security": Vector3(3.9, 0.0, 3.9),
	&"black_ops": Vector3(1.2, 0.0, 1.5),
	&"medical": Vector3(7.0, 0.0, 1.7),
	&"services": Vector3(8.6, 0.0, 3.7),
	&"quartermaster": Vector3(6.5, 0.0, 4.1),
}
const BORG_DATA_DIR := "res://data/borgs/"

var door: Door
var borgs: Array[Borg] = []
var red_alert: bool = false

## Room id -> Rect2 on the floor (x, z).
var _rooms: Dictionary = {}
## Each entry: { "node": Node3D, "front_of": Array[StringName] }.
var _walls: Array[Dictionary] = []
var _room_lights: Array[OmniLight3D] = []
## Each room's normal light color (its mood), same order as _room_lights.
var _room_light_colors: Array[Color] = []
## Furniture footprints (x, z) that crew and the borg walk around.
var _blockers: Array[Rect2] = []
var _cameras: Array[StationCamera] = []
var _sun: DirectionalLight3D
var _environment: Environment
var _borg_vision: bool = false
var _alert_clock: float = 0.0
var _stress_spawned: bool = false


func _ready() -> void:
	_build_environment()
	_build_room(&"engineering", "ENGINEERING", Rect2i(0, 0, ROOM_SIZE, ROOM_SIZE), true, Palette.LIGHT_ENGINEERING)
	_build_room(&"medbay", "MEDBAY", Rect2i(ROOM_SIZE, 0, ROOM_SIZE, ROOM_SIZE), true, Palette.LIGHT_MEDBAY)
	_build_walls_and_door()
	_build_furniture()
	_spawn_crew()
	_spawn_borgs()
	_apply_lighting()


func _process(delta: float) -> void:
	if red_alert:
		_alert_clock += delta
		_apply_lighting()


func get_cameras() -> Array[StationCamera]:
	return _cameras


## Lowers the walls that face the camera for `room_id`, so the room reads like
## a dollhouse. Pass &"*" to lower every front wall (overview feeds).
func set_cutaway(room_id: StringName) -> void:
	for wall: Dictionary in _walls:
		var front_of: Array = wall["front_of"]
		var lowered: bool = room_id == &"*" or front_of.has(room_id)
		(wall["node"] as Node3D).scale.y = CUTAWAY_SCALE if lowered else 1.0


## Id of the room containing `pos`, or &"" if none.
func room_at(pos: Vector3) -> StringName:
	for room_id: StringName in _rooms:
		if (_rooms[room_id] as Rect2).has_point(Vector2(pos.x, pos.z)):
			return room_id
	return &""


## Can the borg's centre be at `pos`? Keeps its body clear of walls, and only
## lets it through the doorway while the door is open.
func is_walkable(pos: Vector3) -> bool:
	var point := Vector2(pos.x, pos.z)
	for blocker: Rect2 in _blockers:
		if blocker.grow(0.3).has_point(point):
			return false
	var clearance: float = RoomBuilder.WALL_THICKNESS * 0.5 + 0.3
	for room_id: StringName in _rooms:
		if (_rooms[room_id] as Rect2).grow(-clearance).has_point(point):
			return true
	if door != null and door.is_passable():
		var doorway := Rect2(door.position.x - 1.0, door.position.z - 0.4, 2.0, 0.8)
		return doorway.has_point(point)
	return false


func toggle_red_alert() -> void:
	red_alert = not red_alert
	_alert_clock = 0.0
	_apply_lighting()


## Borg feeds are dark outside the borg's headlamp.
func set_borg_vision(enabled: bool) -> void:
	_borg_vision = enabled
	_apply_lighting()


## Debug: adds a grid of rooms with crew to measure performance. Runs once.
func spawn_stress_rooms() -> void:
	if _stress_spawned:
		return
	_stress_spawned = true
	var count: int = 0
	for gx in STRESS_GRID:
		for gz in STRESS_GRID:
			var origin := STRESS_ORIGIN + Vector2i(gx * STRESS_SPACING, gz * STRESS_SPACING)
			var cells := Rect2i(origin, Vector2i(ROOM_SIZE, ROOM_SIZE))
			var room_id := StringName("stress_%d" % count)
			_build_room(room_id, "", cells, false)
			_build_box_walls(room_id, cells)
			var rect := Rect2(cells)
			for i in 3:
				var suits: Array[Color] = [Palette.JOB_ENGINEERING, Palette.JOB_SECURITY, Palette.JOB_MEDICAL]
				var jobs: Array[StringName] = [CrewModel.JOB_ENGINEERING, CrewModel.JOB_SECURITY, CrewModel.JOB_MEDICAL]
				var crew := _make_crew("Crew", suits[i], jobs[i])
				crew.rooms = [rect]
				crew.position = Vector3(rect.get_center().x + i - 1.0, 0.0, rect.get_center().y)
			count += 1
	var span: float = float(STRESS_GRID * STRESS_SPACING)
	var overview := _add_camera("STRESS OVERVIEW", &"*", Vector3(STRESS_ORIGIN.x, 1.5, STRESS_ORIGIN.y))
	overview.view_target = Vector3(STRESS_ORIGIN.x + span * 0.5, 0.0, STRESS_ORIGIN.y + span * 0.5)
	overview.view_height = span * 0.75
	_apply_lighting()
	feeds_changed.emit()


func _build_environment() -> void:
	_environment = Environment.new()
	_environment.background_mode = Environment.BG_COLOR
	_environment.background_color = Palette.BACKGROUND
	_environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_environment.ambient_light_color = Palette.AMBIENT
	# Linear = the art test's "Standard" view transform: palette colors stay true.
	_environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	var world_environment := WorldEnvironment.new()
	world_environment.environment = _environment
	add_child(world_environment)

	_sun = DirectionalLight3D.new()
	_sun.rotation = Vector3(deg_to_rad(-55.0), deg_to_rad(25.0), 0.0)
	_sun.light_color = Palette.LIGHT_SUN
	_sun.shadow_enabled = true
	add_child(_sun)


## Floor, ceiling light and (optionally) a station camera for one room.
func _build_room(room_id: StringName, camera_name: String, cells: Rect2i, with_camera: bool, mood: Color = Palette.LIGHT_NORMAL) -> void:
	_rooms[room_id] = Rect2(cells)
	RoomBuilder.build_floor(self, cells)
	var center := Vector3(cells.position.x + cells.size.x * 0.5, 0.0, cells.position.y + cells.size.y * 0.5)
	var lamp := OmniLight3D.new()
	lamp.position = center + Vector3(0.0, 2.3, 0.0)
	lamp.omni_range = 9.0
	lamp.omni_attenuation = 0.8
	# Only the two main rooms cast shadows: shadowed lights are the expensive ones.
	lamp.shadow_enabled = with_camera
	add_child(lamp)
	_room_lights.append(lamp)
	_room_light_colors.append(mood)
	# Lamp fixture on the back wall, so the light has a visible source.
	BoxBuilder.glow_box(self, Vector3(1.2, 0.08, 0.06), Vector3(center.x, 1.45, cells.position.y + 0.13), Palette.LAMP, 2.5)
	if with_camera:
		var cam := _add_camera("CAM-%02d  %s" % [_cameras.size() + 1, camera_name], room_id,
			Vector3(cells.position.x + 0.3, 1.45, cells.position.y + 0.3))
		cam.view_target = center


func _add_camera(feed_name: String, room_id: StringName, mount: Vector3) -> StationCamera:
	var cam := StationCamera.new()
	cam.feed_name = feed_name
	cam.room_id = room_id
	cam.position = mount
	cam.rotation.y = PI * 0.25 # face into the room (+X, +Z)
	add_child(cam)
	_cameras.append(cam)
	return cam


## Walls of the two main rooms, with the door in the shared wall at x = 5.
## The camera looks toward -X/-Z, so the walls at the high X/Z side of a room
## are its "front" walls and get lowered for that room's feed.
func _build_walls_and_door() -> void:
	var s: float = ROOM_SIZE
	_add_wall(Vector2(0, 0), Vector2(s, 0), [])
	_add_wall(Vector2(s, 0), Vector2(s * 2, 0), [])
	_add_wall(Vector2(0, 0), Vector2(0, s), [])
	_add_wall(Vector2(0, s), Vector2(s, s), [&"engineering"])
	_add_wall(Vector2(s, s), Vector2(s * 2, s), [&"medbay"])
	_add_wall(Vector2(s * 2, 0), Vector2(s * 2, s), [&"medbay"])
	# Shared wall: two pieces with a 1 m gap for the door (z 2..3).
	_add_wall(Vector2(s, 0), Vector2(s, 2), [&"engineering"])
	_add_wall(Vector2(s, 3), Vector2(s, s), [&"engineering"])

	door = Door.new()
	door.device_name = "Engineering / Medbay door"
	door.position = Vector3(s, 0.0, 2.5)
	door.rotation.y = PI * 0.5 # door is built along X; turn it to run along Z
	add_child(door)


func _build_box_walls(room_id: StringName, cells: Rect2i) -> void:
	var a := Vector2(cells.position)
	var b := Vector2(cells.end)
	_add_wall(a, Vector2(b.x, a.y), [])
	_add_wall(a, Vector2(a.x, b.y), [])
	_add_wall(Vector2(a.x, b.y), b, [room_id])
	_add_wall(Vector2(b.x, a.y), b, [room_id])


func _add_wall(from: Vector2, to: Vector2, front_of: Array[StringName]) -> void:
	var node := RoomBuilder.build_wall(self, from, to)
	_walls.append({ "node": node, "front_of": front_of })


func _build_furniture() -> void:
	_blockers.append_array(StationProps.build_engineering(self))
	_blockers.append_array(StationProps.build_medbay(self))


func _spawn_crew() -> void:
	var rooms: Array[Rect2] = [_rooms[&"engineering"], _rooms[&"medbay"]]
	var door_sides: Array[Vector3] = [Vector3(4.3, 0.0, 2.5), Vector3(5.7, 0.0, 2.5)]
	var roster: Array[Array] = [
		["Engineer Vasquez", Palette.JOB_ENGINEERING, CrewModel.JOB_ENGINEERING, Vector3(1.5, 0.0, 3.0)],
		["Officer Brandt", Palette.JOB_SECURITY, CrewModel.JOB_SECURITY, Vector3(3.5, 0.0, 2.0)],
		["Doctor Okafor", Palette.JOB_MEDICAL, CrewModel.JOB_MEDICAL, Vector3(7.5, 0.0, 3.5)],
	]
	for entry: Array in roster:
		var crew := _make_crew(entry[0], entry[1], entry[2])
		crew.rooms = rooms
		crew.blockers = _blockers
		crew.door = door
		crew.door_sides = door_sides
		crew.position = entry[3]


func _make_crew(display_name: String, suit: Color, job: StringName) -> CrewMember:
	var crew := CrewMember.new()
	crew.display_name = display_name
	crew.setup(suit, job, GameState.rng)
	add_child(crew)
	return crew


func _spawn_borgs() -> void:
	for id: StringName in BORG_SPOTS:
		var module := load(BORG_DATA_DIR + String(id) + ".tres") as BorgModule
		if module == null:
			push_error("Borg module missing: %s%s.tres" % [BORG_DATA_DIR, id])
			continue
		var borg := Borg.new()
		borg.setup(module)
		borg.position = BORG_SPOTS[id]
		borg.rotation.y = PI * 0.25 # face the camera
		borg.walkable_check = is_walkable
		add_child(borg)
		borgs.append(borg)


## One place decides every light's color and brightness from the current
## state (normal or red alert, station view or borg view).
func _apply_lighting() -> void:
	var energy: float = 3.0
	if red_alert:
		energy = 2.2 + 1.0 * sin(_alert_clock * 4.0)
	if _borg_vision:
		energy *= 0.12
	for i in _room_lights.size():
		_room_lights[i].light_color = Palette.LIGHT_ALERT if red_alert else _room_light_colors[i]
		_room_lights[i].light_energy = energy
	_sun.visible = not _borg_vision
	_sun.light_energy = 0.4 if red_alert else 1.0
	_environment.ambient_light_energy = 0.15 if _borg_vision else 0.8
