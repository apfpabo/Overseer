class_name OutlinePass
extends MeshInstance3D
## Draws a 1-pixel dark outline around everything in the pixel view, like the
## sprite outline in the approved art test (tools/blender/pixel_lit.py).
## It's a full-screen quad attached to the feed camera. Its shader reads the
## depth of each pixel: a pixel gets darkened when a neighbour is clearly
## closer to the camera, so the line sits just outside each silhouette.

const SHADER_CODE := """
shader_type spatial;
render_mode unshaded, depth_draw_never, depth_test_disabled, cull_disabled, fog_disabled, shadows_disabled;

uniform sampler2D depth_tex : hint_depth_texture, filter_nearest, repeat_disable;
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
	float jump = 0.0;
	jump = max(jump, here - view_depth(SCREEN_UV + vec2(pixel.x, 0.0), INV_PROJECTION_MATRIX));
	jump = max(jump, here - view_depth(SCREEN_UV - vec2(pixel.x, 0.0), INV_PROJECTION_MATRIX));
	jump = max(jump, here - view_depth(SCREEN_UV + vec2(0.0, pixel.y), INV_PROJECTION_MATRIX));
	jump = max(jump, here - view_depth(SCREEN_UV - vec2(0.0, pixel.y), INV_PROJECTION_MATRIX));
	if (jump < threshold) {
		discard;
	}
	ALBEDO = outline_color.rgb;
	ALPHA = 1.0;
}
"""


func _ready() -> void:
	var quad := QuadMesh.new()
	quad.size = Vector2(2.0, 2.0)
	mesh = quad
	var shader := Shader.new()
	shader.code = SHADER_CODE
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter(&"outline_color", Palette.OUTLINE)
	material_override = mat
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# The quad is placed by the shader, so never let Godot cull it.
	extra_cull_margin = 16384.0
	position = Vector3(0.0, 0.0, -1.0)
