class_name StaticOverlay
extends ColorRect
## The "static cut": a short burst of TV noise over the pixel view when the
## feed changes. Drawn at pixel-view resolution so it looks chunky.

const SHADER_CODE := """
shader_type canvas_item;
uniform float strength = 1.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 cell = floor(UV * vec2(320.0, 180.0));
	float noise = hash(cell + floor(TIME * 40.0) * 7.31);
	float band = step(0.85, fract(UV.y * 6.0 - TIME * 3.0)) * 0.25;
	COLOR = vec4(vec3(noise * 0.75 + band), strength);
}
"""

const DURATION := 0.22

var _time_left: float = 0.0
var _material: ShaderMaterial


func _ready() -> void:
	var shader := Shader.new()
	shader.code = SHADER_CODE
	_material = ShaderMaterial.new()
	_material.shader = shader
	material = _material
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visible = false


func _process(delta: float) -> void:
	if _time_left <= 0.0:
		return
	_time_left -= delta
	_material.set_shader_parameter(&"strength", clampf(_time_left / DURATION, 0.0, 1.0) * 0.6 + 0.4)
	if _time_left <= 0.0:
		visible = false


func play() -> void:
	_time_left = DURATION
	visible = true
