extends Node
## Shift-wide state: time, speed, pause, and the AI's resources.
## Gameplay systems read and change values here. Values are placeholders until
## the systems that use them are built (see docs/ROADMAP.md).

signal resources_changed
signal speed_changed(speed: float)

const SPEEDS: Array[float] = [1.0, 2.0, 3.0]

## Seeded random generator: use this for all gameplay randomness so runs can be replayed.
var rng := RandomNumberGenerator.new()
var shift_seed: int = 0

var shift_time: float = 0.0
var speed: float = 1.0

var cpu: float = 100.0
var suspicion: float = 0.0
var drift: float = 0.0


func _ready() -> void:
	new_shift()


func _process(delta: float) -> void:
	shift_time += delta * speed


## Resets state for a new shift. Pass a seed to replay a specific run.
func new_shift(seed_value: int = -1) -> void:
	shift_seed = seed_value if seed_value >= 0 else int(Time.get_unix_time_from_system())
	rng.seed = shift_seed
	shift_time = 0.0
	cpu = 100.0
	suspicion = 0.0
	drift = 0.0
	resources_changed.emit()


func set_speed(value: float) -> void:
	speed = value
	Engine.time_scale = value
	speed_changed.emit(value)
