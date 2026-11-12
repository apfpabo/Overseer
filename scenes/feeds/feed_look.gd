class_name FeedLook
extends RefCounted
## The "security camera" finish on the pixel view, applied as a 2D shader on
## the PixelView: a saturation boost (like the art test), faint scanlines,
## a vignette, a little moving noise, and an optional tint (borg feeds).

const SHADER_CODE := """
shader_type canvas_item;

uniform bool enabled = true;
uniform float saturation = 1.25;
uniform float scanlines = 0.10;
uniform float vignette = 0.45;
uniform float noise = 0.035;
uniform vec4 tint : source_color = vec4(1.0);
uniform float tint_amount = 0.0;
uniform vec2 pixel_count = vec2(640.0, 360.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	vec3 col = source.rgb;
	if (enabled) {
		float luma = dot(col, vec3(0.299, 0.587, 0.114));
		col = mix(vec3(luma), col, saturation);
		col = mix(col, luma * tint.rgb * 1.5, tint_amount);
		vec2 pixel = floor(UV * pixel_count);
		col *= 1.0 - scanlines * mod(pixel.y, 2.0);
		vec2 from_center = UV - 0.5;
		col *= 1.0 - vignette * dot(from_center, from_center) * 2.0;
		col += (hash(pixel + floor(TIME * 12.0)) - 0.5) * noise;
	}
	COLOR = vec4(col, source.a);
}
"""

const BORG_TINT_AMOUNT := 0.22


static func create_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = SHADER_CODE
	var mat := ShaderMaterial.new()
	mat.shader = shader
	return mat


static func set_enabled(mat: ShaderMaterial, enabled: bool) -> void:
	mat.set_shader_parameter(&"enabled", enabled)


## Tints the feed toward `color` (a borg's module color), or clears it.
static func set_tint(mat: ShaderMaterial, color: Color, active: bool) -> void:
	mat.set_shader_parameter(&"tint", color)
	mat.set_shader_parameter(&"tint_amount", BORG_TINT_AMOUNT if active else 0.0)
