class_name OutlinePass
extends MeshInstance3D
## Draws a 1-pixel dark outline around everything in the pixel view, like the
## sprite outline in the approved art test (tools/blender/pixel_lit.py), and a
## 1-pixel light highlight along the top edge of every shape (D-013).
## It's a full-screen quad attached to the feed camera. Its shader reads the
## depth of each pixel: a pixel gets darkened when a neighbour is clearly
## closer to the camera, so the line sits just outside each silhouette.

const SHADER_CODE := """
shader_type spatial;
render_mode unshaded, depth_draw_never, depth_test_disabled, cull_disabled, fog_disabled, shadows_disabled;

uniform sampler2D depth_tex : hint_depth_texture, filter_nearest, repeat_disable;
uniform sampler2D screen_tex : hint_screen_texture, filter_nearest, repeat_disable;
// How much the top-edge pixel is brightened (0 = no highlight).
uniform float highlight = 0.35;
uniform vec4 outline_color : source_color = vec4(0.07, 0.055, 0.1, 1.0);
// Meters of depth jump that count as an edge. Big enough that sloped floors
// and wall caps don't get lines, small enough that a person against a wall does.
uniform float threshold = 0.25;

void vertex() {
	// Cover the whole screen whatever the camera does.
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

float view_depth(vec2 uv, mat4 inv_projection) {
	float raw = texture(depth_tex, uv).r;
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	vec3 ndc = vec3(uv, raw) * 2.0 - 1.0;
#else
	vec3 ndc = vec3(uv * 2.0 - 1.0, raw);
#endif
	vec4 view = inv_projection * vec4(ndc, 1.0);
	return -view.z / view.w;
}

void fragment() {
	vec2 pixel = 1.0 / VIEWPORT_SIZE;
	float here = view_depth(SCREEN_UV, INV_PROJECTION_MATRIX);
	float above = view_depth(SCREEN_UV - vec2(0.0, pixel.y), INV_PROJECTION_MATRIX);
	float below = view_depth(SCREEN_UV + vec2(0.0, pixel.y), INV_PROJECTION_MATRIX);
	float left = view_depth(SCREEN_UV - vec2(pixel.x, 0.0), INV_PROJECTION_MATRIX);
	float right = view_depth(SCREEN_UV + vec2(pixel.x, 0.0), INV_PROJECTION_MATRIX);

	// Outline: a neighbour is clearly closer, so this pixel is just outside a shape.
	float jump = max(max(here - above, here - below), max(here - left, here - right));
	if (jump > threshold) {
		ALBEDO = outline_color.rgb;
	} else if (highlight > 0.0 && above - here > threshold) {
		// Top edge: the pixel above is much farther away (space, or the floor behind).
		ALBEDO = mix(texture(screen_tex, SCREEN_UV).rgb, vec3(1.0), highlight);
	} else {
		discard;
	}
	ALPHA = 1.0;
}
"""


var _material: ShaderMaterial


## Top-edge highlight strength, 0 to turn it off.
func set_highlight(amount: float) -> void:
	_material.set_shader_parameter(&"highlight", amount)


func _ready() -> void:
	var quad := QuadMesh.new()
	quad.size = Vector2(2.0, 2.0)
	mesh = quad
	var shader := Shader.new()
	shader.code = SHADER_CODE
	_material = ShaderMaterial.new()
	_material.shader = shader
	_material.set_shader_parameter(&"outline_color", Palette.OUTLINE)
	material_override = _material
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# The quad is placed by the shader, so never let Godot cull it.
	extra_cull_margin = 16384.0
	position = Vector3(0.0, 0.0, -1.0)
