extends Node
## Game root for the M1 technical test. Builds the pixel view (a 640x360 3D
## render scaled up with sharp pixels), the station, the one feed camera and
## the HUD, and turns key presses and clicks into feed switches and actions.

const PIXEL_SIZE := Vector2i(640, 360)
const ROOM_VIEW_HEIGHT := 7.0
const BORG_VIEW_HEIGHT := 6.0
const RAY_LENGTH := 300.0
const HIGHLIGHT_AMOUNT := 0.35

var _station: Station
var _camera: FeedCamera
var _static: StaticOverlay
var _hud: Hud
var _feed_look: ShaderMaterial
## Stylized look (cel bands, highlights, camera finish). F6 compares with the plain look.
var _stylized: bool = true
## Each entry: { "name": String, "camera": StationCamera } or { "name": String, "borg": true }.
var _feeds: Array[Dictionary] = []
var _current_feed: int = 0
var _cutaway_room: StringName = &""
var _has_pending_click: bool = false
var _pending_click: Vector2 = Vector2.ZERO


func _ready() -> void:
	RenderingServer.set_default_clear_color(Palette.BACKGROUND)
	_build_pixel_view()
	_build_ui()
	_station.feeds_changed.connect(_on_feeds_changed)
	_rebuild_feeds()
	_switch_feed(0, false)
	print("CUSTODIAN booted. Shift seed: %d" % GameState.shift_seed)


func _process(_delta: float) -> void:
	if _is_borg_feed(_current_feed):
		var room: StringName = _station.room_at(_station.borg.position)
		if room != &"" and room != _cutaway_room:
			_cutaway_room = room
			_station.set_cutaway(room)


func _physics_process(_delta: float) -> void:
	if _has_pending_click:
		_has_pending_click = false
		_click_at(_pending_click)


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo:
		_on_key(key.physical_keycode)
		return
	var click := event as InputEventMouseButton
	if click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		# Physics queries are safest in _physics_process, so do it there.
		_pending_click = click.position
		_has_pending_click = true


func _on_key(keycode: Key) -> void:
	if keycode >= KEY_1 and keycode <= KEY_9:
		var index: int = keycode - KEY_1
		if index < _feeds.size() and index != _current_feed:
			_switch_feed(index, true)
		return
	match keycode:
		KEY_R:
			_station.toggle_red_alert()
			_hud.set_red_alert(_station.red_alert)
		KEY_F3:
			_hud.show_fps = not _hud.show_fps
		KEY_F4:
			_hud.show_fps = true
			_station.spawn_stress_rooms()
		KEY_F6:
			_set_stylized(not _stylized)


func _build_pixel_view() -> void:
	var pixel_view := SubViewportContainer.new()
	pixel_view.name = "PixelView"
	# No stretch: with the window's canvas_items scaling, a stretched SubViewport
	# would render at full window resolution and lose the pixel look. A fixed
	# 640x360 render, drawn with nearest filtering, gives chunky pixels.
	pixel_view.stretch = false
	pixel_view.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pixel_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_feed_look = FeedLook.create_material()
	pixel_view.material = _feed_look
	add_child(pixel_view)
	pixel_view.position = Vector2.ZERO
	pixel_view.size = Vector2(PIXEL_SIZE)

	var viewport := SubViewport.new()
	viewport.name = "SubViewport"
	viewport.own_world_3d = true
	viewport.size = PIXEL_SIZE
	viewport.msaa_3d = Viewport.MSAA_DISABLED
	pixel_view.add_child(viewport)

	_station = Station.new()
	_station.name = "Station"
	viewport.add_child(_station)

	_camera = FeedCamera.new()
	_camera.name = "FeedCamera"
	viewport.add_child(_camera)
	_camera.current = true
	_set_stylized(_stylized)


func _build_ui() -> void:
	var ui := CanvasLayer.new()
	ui.name = "UI"
	add_child(ui)
	_static = StaticOverlay.new()
	ui.add_child(_static)
	_hud = Hud.new()
	ui.add_child(_hud)
	_hud.show_rec = _stylized


## Feed order: room cameras first, then the borg, then any extra cameras
## (the stress-test overview).
func _rebuild_feeds() -> void:
	_feeds.clear()
	var cameras: Array[StationCamera] = _station.get_cameras()
	for i in cameras.size():
		if i == 2:
			_feeds.append({ "name": "BORG-1  (possessed)", "borg": true })
		_feeds.append({ "name": cameras[i].feed_name, "camera": cameras[i] })
	if cameras.size() <= 2:
		_feeds.append({ "name": "BORG-1  (possessed)", "borg": true })


func _on_feeds_changed() -> void:
	_rebuild_feeds()
	# Jump straight to the newest feed (the stress-test overview).
	_switch_feed(_feeds.size() - 1, true)


func _switch_feed(index: int, with_static: bool) -> void:
	_current_feed = index
	var borg_feed: bool = _is_borg_feed(index)
	_station.borg.possessed = borg_feed
	_station.set_borg_vision(borg_feed)
	if borg_feed:
		_camera.show_following(_station.borg, BORG_VIEW_HEIGHT)
		_station.borg.screen_forward = _camera.screen_forward_on_floor()
		_station.borg.screen_right = _camera.screen_right_on_floor()
		_cutaway_room = _station.room_at(_station.borg.position)
		_station.set_cutaway(_cutaway_room)
	else:
		var cam: StationCamera = _feeds[index]["camera"]
		_camera.show_fixed(cam.view_target, cam.view_height)
		_cutaway_room = cam.room_id
		_station.set_cutaway(cam.room_id)
	var names: Array[String] = []
	for feed: Dictionary in _feeds:
		names.append(feed["name"])
	_hud.set_feeds(names, index)
	FeedLook.set_tint(_feed_look, _station.borg.module_color, borg_feed)
	if with_static:
		_static.play()


func _set_stylized(enabled: bool) -> void:
	_stylized = enabled
	BoxBuilder.set_cel_enabled(enabled)
	_camera.outline.set_highlight(HIGHLIGHT_AMOUNT if enabled else 0.0)
	FeedLook.set_enabled(_feed_look, enabled)
	if _hud != null:
		_hud.show_rec = enabled


func _is_borg_feed(index: int) -> bool:
	return index < _feeds.size() and _feeds[index].get("borg", false)


## Left click on the pixel view: find what's under the mouse and act on it.
func _click_at(screen_pos: Vector2) -> void:
	var from: Vector3 = _camera.project_ray_origin(screen_pos)
	var to: Vector3 = from + _camera.project_ray_normal(screen_pos) * RAY_LENGTH
	var query := PhysicsRayQueryParameters3D.create(from, to, Door.CLICK_LAYER)
	var hit: Dictionary = _camera.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return
	var collider: Object = hit["collider"]
	if collider != null and collider.has_meta(&"door"):
		var door: Door = collider.get_meta(&"door")
		door.toggle()
