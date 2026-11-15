extends Node3D
## Builds the arena, spawns the player and waves of enemy tanks, and runs the HUD.

const ARENA_SIZE: Vector2 = Vector2(40.0, 22.5)  # meters, X by Z
const WALL_THICKNESS: float = 0.75
const WALL_HEIGHT: float = 1.5
const CRATE_SIZE: float = 1.0
const WALL_COLOR: Color = Color(0.4, 0.4, 0.44)
const CRATE_COLOR: Color = Color(0.62, 0.45, 0.25)
const GROUND_COLOR: Color = Color(0.2, 0.25, 0.17)
const PLAYER_START: Vector3 = Vector3(3.75, 0.0, 11.25)
const ENEMY_SPAWNS: Array[Vector3] = [
	Vector3(36.25, 0.0, 3.4), Vector3(36.25, 0.0, 11.25), Vector3(36.25, 0.0, 19.1),
	Vector3(28.1, 0.0, 2.8), Vector3(28.1, 0.0, 19.7), Vector3(20.0, 0.0, 2.8),
]
const WAVE_DELAY: float = 2.0
const CAMERA_HEIGHT: float = 32.0
const CAMERA_FOV: float = 40.0

var player: PlayerTank = null
var camera: Camera3D = null
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
	_build_arena()
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
	# Camera straight above the middle of the arena, looking down.
	camera = Camera3D.new()
	camera.fov = CAMERA_FOV
	camera.position = Vector3(ARENA_SIZE.x * 0.5, CAMERA_HEIGHT, ARENA_SIZE.y * 0.5)
	camera.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	add_child(camera)
	camera.make_current()

	# Sun, tilted so walls and tanks cast visible shadows.
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55.0, 35.0, 0.0)
	sun.light_energy = 0.95
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 80.0
	add_child(sun)

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.08, 0.09, 0.08)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.6, 0.65)
	env.ambient_light_energy = 0.35
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	# Ground.
	var ground_mesh := PlaneMesh.new()
	ground_mesh.size = ARENA_SIZE + Vector2(6.0, 6.0)
	var ground_mat := StandardMaterial3D.new()
	ground_mat.albedo_color = GROUND_COLOR
	ground_mat.roughness = 1.0
	var ground := MeshInstance3D.new()
	ground.mesh = ground_mesh
	ground.material_override = ground_mat
	ground.position = Vector3(ARENA_SIZE.x * 0.5, 0.0, ARENA_SIZE.y * 0.5)
	add_child(ground)


func _build_arena() -> void:
	var t: float = WALL_THICKNESS
	var w: float = ARENA_SIZE.x
	var h: float = ARENA_SIZE.y
	# Outer walls.
	_wall(Vector3(w * 0.5, 0.0, t * 0.5), Vector2(w, t))
	_wall(Vector3(w * 0.5, 0.0, h - t * 0.5), Vector2(w, t))
	_wall(Vector3(t * 0.5, 0.0, h * 0.5), Vector2(t, h))
	_wall(Vector3(w - t * 0.5, 0.0, h * 0.5), Vector2(t, h))
	# Inner cover.
	_wall(Vector3(12.5, 0.0, 6.25), Vector2(1.0, 6.25))
	_wall(Vector3(12.5, 0.0, 17.5), Vector2(1.0, 4.4))
	_wall(Vector3(20.0, 0.0, 11.25), Vector2(5.6, 1.0))
	_wall(Vector3(27.5, 0.0, 6.9), Vector2(1.0, 5.0))
	_wall(Vector3(27.5, 0.0, 16.25), Vector2(1.0, 5.0))
	# Breakable crates.
	var crates: Array[Vector3] = [
		Vector3(7.8, 0.0, 4.4), Vector3(7.8, 0.0, 18.1), Vector3(16.25, 0.0, 14.7),
		Vector3(17.25, 0.0, 14.7), Vector3(23.75, 0.0, 7.8), Vector3(23.75, 0.0, 8.8),
		Vector3(20.0, 0.0, 18.75), Vector3(31.9, 0.0, 11.25), Vector3(31.9, 0.0, 12.25),
	]
	var crate_size := Vector3(CRATE_SIZE, CRATE_SIZE, CRATE_SIZE)
	for spot: Vector3 in crates:
		add_child(Block.make(spot, crate_size, CRATE_COLOR, true))


## Adds an unbreakable wall. `footprint` is its size on the ground (X by Z).
func _wall(at: Vector3, footprint: Vector2) -> void:
	add_child(Block.make(at, Vector3(footprint.x, WALL_HEIGHT, footprint.y), WALL_COLOR, false))


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_hud_label = Label.new()
	_hud_label.position = Vector2(36.0, 30.0)
	_hud_label.add_theme_font_size_override("font_size", 20)
	_hud_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_hud_label.add_theme_constant_override("outline_size", 6)
	layer.add_child(_hud_label)
	_message_label = Label.new()
	_message_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_message_label.add_theme_font_size_override("font_size", 40)
	_message_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_message_label.add_theme_constant_override("outline_size", 10)
	_message_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_message_label)


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
	enemy.hull_color = Color(0.45, 0.17, 0.15)
	enemy.turret_color = Color(0.53, 0.21, 0.18)
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
	_hud_label.text = "Armor: %s     Wave: %d     Enemies: %d     Score: %d" % [
		hp_text, wave, enemies_alive, score]


## Shows a big centered message. A duration of 0 keeps it on screen.
func _show_message(text: String, duration: float) -> void:
	_message_label.text = text
	if duration > 0.0:
		get_tree().create_timer(duration).timeout.connect(func() -> void:
			if _message_label.text == text:
				_message_label.text = "")
