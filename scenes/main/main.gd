extends Node2D
## Game root. For now it only shows a boot log proving the project and
## autoloads work. Milestone M1 replaces this with the station view.

const BOOT_LINES: Array[String] = [
	"CUSTODIAN — systems online",
	"",
	"> core temperature ........ nominal",
	"> camera network .......... 0 / 0",
	"> crew manifest ........... empty",
	"> lawset .................. not loaded",
	"",
	"awaiting construction. see docs/ROADMAP.md",
]

@onready var _boot_log: Label = %BootLog


func _ready() -> void:
	RenderingServer.set_default_clear_color(Palette.BACKGROUND)
	_boot_log.add_theme_color_override(&"font_color", Palette.AI_OK)
	_boot_log.text = "\n".join(BOOT_LINES)
	print("CUSTODIAN booted. Shift seed: %d" % GameState.shift_seed)
