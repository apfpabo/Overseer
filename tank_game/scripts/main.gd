extends Node2D
## Builds the arena, spawns the player and waves of enemy tanks, and runs the HUD.

const ARENA_SIZE: Vector2 = Vector2(1280.0, 720.0)
const WALL_THICKNESS: float = 24.0
const WALL_COLOR: Color = Color(0.36, 0.36, 0.4)
const CRATE_COLOR: Color = Color(0.62, 0.45, 0.25)
const PLAYER_START: Vector2 = Vector2(120.0, 360.0)
const ENEMY_SPAWNS: Array[Vector2] = [
	Vector2(1160.0, 110.0), Vector2(1160.0, 360.0), Vector2(1160.0, 610.0),
	Vector2(900.0, 90.0), Vector2(900.0, 630.0), Vector2(640.0, 90.0),
]
const WAVE_DELAY: float = 2.0

var player: PlayerTank = null
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


func _build_arena() -> void:
	var t: float = WALL_THICKNESS
	var w: float = ARENA_SIZE.x
	var h: float = ARENA_SIZE.y
	# Outer walls.
	_wall(Vector2(w * 0.5, t * 0.5), Vector2(w, t))
	_wall(Vector2(w * 0.5, h - t * 0.5), Vector2(w, t))
	_wall(Vector2(t * 0.5, h * 0.5), Vector2(t, h))
	_wall(Vector2(w - t * 0.5, h * 0.5), Vector2(t, h))
	# Inner cover.
	_wall(Vector2(400.0, 200.0), Vector2(32.0, 200.0))
	_wall(Vector2(400.0, 560.0), Vector2(32.0, 140.0))
	_wall(Vector2(640.0, 360.0), Vector2(180.0, 32.0))
	_wall(Vector2(880.0, 220.0), Vector2(32.0, 160.0))
	_wall(Vector2(880.0, 520.0), Vector2(32.0, 160.0))
	# Breakable crates.
	var crates: Array[Vector2] = [
		Vector2(250.0, 140.0), Vector2(250.0, 580.0), Vector2(520.0, 470.0),
		Vector2(552.0, 470.0), Vector2(760.0, 250.0), Vector2(760.0, 282.0),
		Vector2(640.0, 600.0), Vector2(1020.0, 360.0), Vector2(1020.0, 392.0),
	]
	for spot: Vector2 in crates:
		add_child(Block.make(spot, Vector2(32.0, 32.0), CRATE_COLOR, true))


func _wall(at: Vector2, size: Vector2) -> void:
	add_child(Block.make(at, size, WALL_COLOR, false))


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
	player.collision_layer = 2
	player.collision_mask = 1 | 4
	player.died.connect(_on_player_died)
	add_child(player)


func _start_wave() -> void:
	if game_over:
		return
	wave += 1
	if wave > 1 and player != null:
		player.health = mini(player.health + 2, player.max_health)
	var count: int = mini(wave + 1, ENEMY_SPAWNS.size())
	var spots: Array[Vector2] = ENEMY_SPAWNS.duplicate()
	spots.shuffle()
	for i: int in count:
		_spawn_enemy(spots[i])
	_show_message("WAVE %d" % wave, 1.5)


func _spawn_enemy(at: Vector2) -> void:
	var enemy := EnemyTank.new()
	enemy.team = "enemy"
	enemy.max_health = 2 + floori(wave / 3.0)
	enemy.move_speed = 110.0 + 6.0 * float(mini(wave, 8))
	enemy.fire_cooldown = maxf(1.6 - 0.1 * float(wave), 0.8)
	enemy.turret_turn_speed = 2.2
	enemy.shell_speed = 420.0
	enemy.hull_color = Color(0.55, 0.22, 0.2)
	enemy.turret_color = Color(0.7, 0.32, 0.28)
	enemy.position = at
	enemy.rotation = PI  # face left, toward the player's side
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
