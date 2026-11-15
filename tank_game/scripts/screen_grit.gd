class_name ScreenGrit
extends CanvasLayer
## Full-screen post-processing for the "3D pixel art" look. It reads the
## rendered picture and:
## - darkens pixels on hard edges (gives models crisp dark outlines),
## - reduces the colors to a limited palette with ordered dithering,
## - adds dark corners (vignette) and a light film grain.
## The HUD is drawn on a higher layer, so it stays clean.

const SHADER_CODE: String = """
shader_type canvas_item;
uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform float levels = 14.0;
uniform float outline = 0.35;
uniform float vignette = 0.6;
uniform float grain = 0.035;

float luma(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

float bayer4(vec2 p) {
	int x = int(mod(p.x, 4.0));
	int y = int(mod(p.y, 4.0));
	int i = x + y * 4;
	float m[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);
	return m[i] / 16.0 - 0.5;
}

float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }

void fragment() {
	vec2 px = SCREEN_PIXEL_SIZE;
	vec3 c = texture(screen_tex, SCREEN_UV).rgb;
	// Outlines: if a neighbour is much darker, this pixel is on an edge.
	float l = luma(c);
	float n = min(min(luma(texture(screen_tex, SCREEN_UV + vec2(px.x, 0.0)).rgb),
			luma(texture(screen_tex, SCREEN_UV - vec2(px.x, 0.0)).rgb)),
			min(luma(texture(screen_tex, SCREEN_UV + vec2(0.0, px.y)).rgb),
			luma(texture(screen_tex, SCREEN_UV - vec2(0.0, px.y)).rgb)));
	float edge = smoothstep(0.08, 0.22, l - n);
	c *= 1.0 - edge * outline;
	// Vignette and grain.
	vec2 uv = SCREEN_UV - 0.5;
	float v = smoothstep(0.25, 0.8, length(uv * vec2(1.0, 0.75)));
	c *= 1.0 - v * vignette;
	c += (hash(FRAGCOORD.xy + fract(TIME * 7.0) * 100.0) - 0.5) * grain;
	// Limited palette with ordered dithering.
	c = floor(c * levels + 0.5 + bayer4(FRAGCOORD.xy)) / levels;
	COLOR = vec4(clamp(c, 0.0, 1.0), 1.0);
}
"""


func _ready() -> void:
	layer = 5
	var shader := Shader.new()
	shader.code = SHADER_CODE
	var mat := ShaderMaterial.new()
	mat.shader = shader
	var rect := ColorRect.new()
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.material = mat
	add_child(rect)
