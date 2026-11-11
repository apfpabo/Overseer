class_name Hud
extends Control
## On-screen text over the feed: feed name and station time, the list of
## feeds, controls help, red alert banner and the FPS counter.
## Plain Labels for now; the real UI (law panel, radio) comes later.

const SHIFT_START_SECONDS := 8 * 3600

var show_fps: bool = false

var _feed_title: Label
var _feed_list: Label
var _help: Label
var _alert: Label
var _fps: Label
var _feed_title_text: String = ""


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_feed_title = _label(Vector2(8, 6), 10, Palette.AI_OK)
	_feed_list = _label(Vector2(8, 300), 8, Palette.TEXT)
	_help = _label(Vector2(8, 22), 7, Palette.TEXT_DIM)
	_help.text = "Click door: open/close   R: red alert   WASD: drive borg (its feed)   F3: FPS   F4: stress test"
	_alert = _label(Vector2(520, 6), 10, Palette.AI_ROGUE)
	_alert.text = "RED ALERT"
	_alert.visible = false
	_fps = _label(Vector2(560, 22), 8, Palette.AI_WARN)
	_fps.visible = false


func _process(_delta: float) -> void:
	_feed_title.text = "%s   %s" % [_feed_title_text, _clock_text()]
	_fps.visible = show_fps
	if show_fps:
		_fps.text = "%d FPS" % Engine.get_frames_per_second()


func set_feeds(names: Array[String], current: int) -> void:
	_feed_title_text = names[current] if current < names.size() else ""
	var lines: PackedStringArray = []
	for i in names.size():
		var marker: String = ">" if i == current else " "
		lines.append("%s [%d] %s" % [marker, i + 1, names[i]])
	_feed_list.text = "\n".join(lines)
	# Keep the list anchored to the bottom whatever its length.
	_feed_list.position.y = 352.0 - 10.0 * names.size()


func set_red_alert(enabled: bool) -> void:
	_alert.visible = enabled


func _clock_text() -> String:
	var total: int = SHIFT_START_SECONDS + int(GameState.shift_time)
	var hours: int = floori(total / 3600.0) % 24
	var minutes: int = floori(total / 60.0) % 60
	return "%02d:%02d:%02d" % [hours, minutes, total % 60]


func _label(at: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.position = at
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_color", color)
	label.add_theme_color_override(&"font_shadow_color", Color(0, 0, 0, 0.8))
	label.add_theme_constant_override(&"shadow_offset_x", 1)
	label.add_theme_constant_override(&"shadow_offset_y", 1)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label
