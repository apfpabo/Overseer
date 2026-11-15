extends Node3D
## Builds the desert map, spawns the player and waves of enemy tanks, and runs the HUD.

const PLAYER_START: Vector3 = Vector3(3.0, 0.0, 11.25)
const ENEMY_SPAWNS: Array[Vector3] = [
	Vector3(37.0, 0.0, 3.0), Vector3(37.0, 0.0, 8.2), Vector3(37.0, 0.0, 14.4),
	Vector3(37.0, 0.0, 19.6), Vector3(34.6, 0.0, 11.25), Vector3(34.4, 0.0, 2.4),
]
const WAVE_DELAY: float = 2.0
const ENEMY_HULL: Color = Color(0.25, 0.27, 0.31)
const ENEMY_TURRET: Color = Color(0.29, 0.31, 0.35)

var player: PlayerTank = null
var camera: FollowCamera = null
var wave: int = 0
var score: int = 0
var enemies_alive: int = 0
var game_over: bool = false
var _next_wave_in: float = -1.0

var _hud_label: Label
var _message_label: Label


func _ready() -> void:
	randomize()
	_setup_input()
	_build_world()
	_build_hud()
	_spawn_player()
	_start_wave()


func _process(delta: float) -> void:
	if _next_wave_in > 0.0:
		_next_wave_in -= delta
		if _next_wave_in <= 0.0:
			_start_wave()
	_update_hud()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("tank_restart"):
		get_tree().reload_current_scene()
	elif event.is_action_pressed("ui_cancel"):
		get_tree().quit()


# --- Setup ---------------------------------------------------------------

func _setup_input() -> void:
	_add_key_action("tank_forward", [KEY_W, KEY_UP])
	_add_key_action("tank_back", [KEY_S, KEY_DOWN])
	_add_key_action("tank_left", [KEY_A, KEY_LEFT])
	_add_key_action("tank_right", [KEY_D, KEY_RIGHT])
	_add_key_action("tank_fire", [KEY_SPACE])
	_add_key_action("tank_restart", [KEY_R])
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	InputMap.action_add_event("tank_fire", click)


func _add_key_action(action: String, keys: Array[Key]) -> void:
	if InputMap.has_action(action):
		InputMap.erase_action(action)
	InputMap.add_action(action)
	for key: Key in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = key
		InputMap.action_add_event(action, ev)


func _build_world() -> void:
	add_child(DesertMap.new())
	# Bird's-eye camera that follows the player (its target is set on spawn).
	camera = FollowCamera.new()
	camera.map_size = DesertMap.SIZE
	add_child(camera)
	camera.make_current()
	add_child(ScreenGrit.new())
	var nav := NavGrid.new()
	add_child(nav)
	# Scan the map for pathfinding once the physics world has all the walls in it.
	# (Everything above is already set up; this part finishes one frame later.)
	await get_tree().physics_frame
	nav.key_points.assign([PLAYER_START] + ENEMY_SPAWNS)
	nav.build(get_world_3d().direct_space_state, DesertMap.SIZE, PLAYER_START)


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10  # above the screen grit overlay
	add_child(layer)
	_hud_label = Label.new()
	_hud_label.position = Vector2(12.0, 8.0)
	_hud_label.add_theme_font_size_override("font_size", 11)
	_hud_label.add_theme_color_override("font_color", Color(0.95, 0.88, 0.7))
	_hud_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_hud_label.add_theme_constant_override("outline_size", 3)
	layer.add_child(_hud_label)
	_message_label = Label.new()
	_message_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_message_label.add_theme_font_size_override("font_size", 22)
	_message_label.add_theme_color_override("font_color", Color(0.95, 0.88, 0.7))
	_message_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_message_label.add_theme_constant_override("outline_size", 5)
	_message_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_message_label)
	var markers := EnemyMarkers.new()
	markers.camera = camera
	markers.game = self
	layer.add_child(markers)


# --- Tanks ---------------------------------------------------------------

func _spawn_player() -> void:
	player = PlayerTank.new()
	player.team = "player"
	player.max_health = 8
	player.position = PLAYER_START
	player.rotation.y = -PI * 0.5  # face right
	player.collision_layer = 2
	player.collision_mask = 1 | 4
	player.aim_camera = camera
	camera.target = player
	player.died.connect(_on_player_died)
	add_child(player)


func _start_wave() -> void:
	if game_over:
		return
	wave += 1
	if wave > 1 and player != null:
		player.health = mini(player.health + 2, player.max_health)
	var count: int = mini(wave + 1, ENEMY_SPAWNS.size())
	var spots: Array[Vector3] = ENEMY_SPAWNS.duplicate()
	spots.shuffle()
	for i: int in count:
		_spawn_enemy(spots[i])
	_show_message("WAVE %d" % wave, 1.5)


func _spawn_enemy(at: Vector3) -> void:
	var enemy := EnemyTank.new()
	enemy.team = "enemy"
	enemy.max_health = 2 + floori(wave / 3.0)
	enemy.move_speed = 3.4 + 0.19 * float(mini(wave, 8))
	enemy.fire_cooldown = maxf(1.6 - 0.1 * float(wave), 0.8)
	enemy.turret_turn_speed = 2.2
	enemy.shell_speed = 13.0
	enemy.hull_color = ENEMY_HULL
	enemy.turret_color = ENEMY_TURRET
	enemy.position = at
	enemy.rotation.y = PI * 0.5  # face left, toward the player's side
	enemy.collision_layer = 4
	enemy.collision_mask = 1 | 2 | 4
	enemy.target = player
	enemy.died.connect(_on_enemy_died)
	add_child(enemy)
	enemies_alive += 1


func _on_enemy_died(_tank: Tank) -> void:
	enemies_alive -= 1
	score += 100
	if enemies_alive <= 0 and not game_over:
		_show_message("WAVE %d CLEARED" % wave, WAVE_DELAY)
		_next_wave_in = WAVE_DELAY


func _on_player_died(_tank: Tank) -> void:
	game_over = true
	player = null
	_next_wave_in = -1.0
	_show_message("DESTROYED\nWave %d  -  Score %d\nPress R to restart" % [wave, score], 0.0)


# --- HUD -----------------------------------------------------------------

func _update_hud() -> void:
	var hp_text: String = "0"
	if player != null and is_instance_valid(player):
		hp_text = "%d / %d" % [player.health, player.max_health]
	_hud_label.text = "ARMOR %s   WAVE %d   ENEMIES %d   SCORE %d" % [
		hp_text, wave, enemies_alive, score]


## Shows a big centered message. A duration of 0 keeps it on screen.
func _show_message(text: String, duration: float) -> void:
	_message_label.text = text
	if duration > 0.0:
		get_tree().create_timer(duration).timeout.connect(func() -> void:
			if _message_label.text == text:
				_message_label.text = "")
