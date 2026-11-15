class_name DesertMap
extends Node3D
## The desert battlefield: sand ground, sun and haze, the ruined town, cover,
## the map edge, and drifting sand. Built from code with a fixed random seed,
## so the map looks the same every game.

const SIZE: Vector2 = Vector2(40.0, 22.5)  # playable area in meters, X by Z
const SEED: int = 1337
const SAND_LIGHT: Color = Color(0.68, 0.58, 0.44)
const SAND_DARK: Color = Color(0.48, 0.39, 0.29)
const HAZE: Color = Color(0.78, 0.68, 0.52)

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = SEED
	_build_lighting()
	_build_ground()
	_build_edge()
	_build_town()
	add_child(TrackMarks.new())
	add_child(DustLayer.new())


func _build_lighting() -> void:
	# A hot, low sun so everything casts long shadows.
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52.0, 28.0, 0.0)
	sun.light_color = Color(1.0, 0.88, 0.7)
	sun.light_energy = 1.6
	sun.shadow_enabled = true
	sun.shadow_opacity = 0.85
	sun.directional_shadow_max_distance = 40.0
	add_child(sun)

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = HAZE
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.42, 0.45, 0.66)  # cool blue-purple shadows
	env.ambient_light_energy = 0.32
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 0.95
	# Sand haze: the whole scene is seen through a light veil of dust.
	env.fog_enabled = true
	env.fog_light_color = HAZE
	env.fog_light_energy = 0.8
	env.fog_density = 0.0025
	env.fog_sky_affect = 0.0
	# Washed-out, slightly gritty color grade.
	env.adjustment_enabled = true
	env.adjustment_brightness = 1.0
	env.adjustment_contrast = 1.25
	env.adjustment_saturation = 0.95
	env.glow_enabled = true
	env.glow_intensity = 0.5
	env.glow_hdr_threshold = 1.2
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)


const GROUND_SHADER: String = """
shader_type spatial;
render_mode diffuse_lambert, specular_disabled;
uniform sampler2D base_tex : source_color, filter_nearest_mipmap, repeat_enable;
uniform sampler2D crack_tex : filter_nearest_mipmap, repeat_enable;
uniform sampler2D speck_tex : filter_nearest_mipmap, repeat_enable;
uniform float base_scale = 0.04;
uniform float crack_scale = 0.07;
uniform float speck_scale = 0.5;
varying vec2 world_xz;

void vertex() {
	world_xz = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

void fragment() {
	vec3 sand = texture(base_tex, world_xz * base_scale).rgb;
	// Dried, cracked earth: thin dark lines along cell borders.
	float crack = texture(crack_tex, world_xz * crack_scale).r;
	float crack_line = 1.0 - smoothstep(0.0, 0.035, crack);
	// Patchy: cracks only show in some areas.
	float patch = smoothstep(0.5, 0.56, texture(base_tex, world_xz * base_scale * 0.6 + 0.3).g);
	sand *= 1.0 - crack_line * patch * 0.35;
	// Pebbles and grit.
	float speck = texture(speck_tex, world_xz * speck_scale).r;
	sand *= mix(0.82, 1.08, speck);
	ALBEDO = sand;
	ROUGHNESS = 1.0;
}
"""


func _build_ground() -> void:
	# Large patches of lighter and darker sand.
	var noise := FastNoiseLite.new()
	noise.seed = SEED
	noise.frequency = 0.02
	noise.fractal_octaves = 5
	var ramp := Gradient.new()
	ramp.set_color(0, SAND_DARK)
	ramp.set_color(1, SAND_LIGHT)
	ramp.add_point(0.55, Color(0.6, 0.51, 0.38))
	var base := NoiseTexture2D.new()
	base.width = 512
	base.height = 512
	base.seamless = true
	base.noise = noise
	base.color_ramp = ramp
	# Crack network (distance to cell borders).
	var crack_noise := FastNoiseLite.new()
	crack_noise.seed = SEED + 2
	crack_noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	crack_noise.cellular_return_type = FastNoiseLite.RETURN_DISTANCE2_SUB
	crack_noise.frequency = 0.03
	crack_noise.fractal_type = FastNoiseLite.FRACTAL_NONE
	var cracks := NoiseTexture2D.new()
	cracks.width = 512
	cracks.height = 512
	cracks.seamless = true
	cracks.noise = crack_noise
	# Fine grit.
	var speck_noise := FastNoiseLite.new()
	speck_noise.seed = SEED + 3
	speck_noise.noise_type = FastNoiseLite.TYPE_VALUE
	speck_noise.frequency = 0.5
	speck_noise.fractal_type = FastNoiseLite.FRACTAL_NONE
	var specks := NoiseTexture2D.new()
	specks.width = 128
	specks.height = 128
	specks.seamless = true
	specks.noise = speck_noise

	var shader := Shader.new()
	shader.code = GROUND_SHADER
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("base_tex", base)
	mat.set_shader_parameter("crack_tex", cracks)
	mat.set_shader_parameter("speck_tex", specks)
	var plane := PlaneMesh.new()
	plane.size = SIZE + Vector2(40.0, 30.0)
	var ground := MeshInstance3D.new()
	ground.mesh = plane
	ground.material_override = mat
	ground.position = Vector3(SIZE.x * 0.5, 0.0, SIZE.y * 0.5)
	add_child(ground)


func _build_edge() -> void:
	# Invisible walls keep tanks and shells inside.
	var t: float = 1.0
	var w: float = SIZE.x
	var h: float = SIZE.y
	Block.collider(self, Vector3(w * 0.5, 0.0, -t * 0.5), Vector3(w + 2.0 * t, 3.0, t))
	Block.collider(self, Vector3(w * 0.5, 0.0, h + t * 0.5), Vector3(w + 2.0 * t, 3.0, t))
	Block.collider(self, Vector3(-t * 0.5, 0.0, h * 0.5), Vector3(t, 3.0, h))
	Block.collider(self, Vector3(w + t * 0.5, 0.0, h * 0.5), Vector3(t, 3.0, h))
	# Rocky ridges along the edge so it doesn't look like a box.
	var x: float = 0.0
	while x <= w:
		Props.rock(self, Vector3(x + _rng.randf_range(-0.5, 0.5), 0.0, -0.4 + _rng.randf_range(-0.3, 0.2)), _rng.randf_range(1.0, 1.8), _rng, false)
		Props.rock(self, Vector3(x + _rng.randf_range(-0.5, 0.5), 0.0, h + 0.4 + _rng.randf_range(-0.2, 0.3)), _rng.randf_range(1.0, 1.8), _rng, false)
		x += _rng.randf_range(1.6, 2.6)
	var z: float = 0.0
	while z <= h:
		Props.rock(self, Vector3(-0.4 + _rng.randf_range(-0.3, 0.2), 0.0, z), _rng.randf_range(1.0, 1.8), _rng, false)
		Props.rock(self, Vector3(w + 0.4 + _rng.randf_range(-0.2, 0.3), 0.0, z), _rng.randf_range(1.0, 1.8), _rng, false)
		z += _rng.randf_range(1.6, 2.6)


func _build_town() -> void:
	# Ruined buildings (center, width, depth).
	Props.ruin(self, Vector3(10.5, 0.0, 4.6), 6.0, 4.4, _rng)
	Props.ruin(self, Vector3(11.0, 0.0, 18.0), 5.0, 4.0, _rng)
	Props.ruin(self, Vector3(20.0, 0.0, 11.25), 5.5, 4.5, _rng)
	Props.ruin(self, Vector3(28.5, 0.0, 4.6), 5.0, 4.4, _rng)
	Props.ruin(self, Vector3(28.5, 0.0, 18.0), 6.0, 4.0, _rng)
	# Rubble spilled into the streets.
	for spot: Vector3 in [Vector3(14.8, 0.0, 7.6), Vector3(24.4, 0.0, 14.0), Vector3(16.4, 0.0, 20.6), Vector3(33.2, 0.0, 9.0)]:
		Props.rubble(self, spot, 1.1, _rng)
	# Sandbag positions and road barriers.
	Props.sandbags(self, Vector3(6.4, 0.0, 9.0), 2.5, 0.5, _rng)
	Props.sandbags(self, Vector3(24.8, 0.0, 11.25), 3.0, PI * 0.5, _rng)
	Props.sandbags(self, Vector3(15.2, 0.0, 14.6), 2.5, 0.2, _rng)
	Props.barrier(self, Vector3(16.0, 0.0, 3.4), 0.6, _rng)
	Props.barrier(self, Vector3(23.8, 0.0, 19.6), -0.3, _rng)
	Props.barrier(self, Vector3(33.0, 0.0, 6.6), 1.3, _rng)
	Props.barrier(self, Vector3(33.0, 0.0, 15.8), 1.8, _rng)
	# Wrecked vehicles.
	Props.car_wreck(self, Vector3(5.6, 0.0, 3.6), 0.4, _rng)
	Props.car_wreck(self, Vector3(24.0, 0.0, 7.4), -0.8, _rng)
	Props.car_wreck(self, Vector3(6.0, 0.0, 19.4), 1.4, _rng)
	Tank.make_hulk(self, Vector3(16.8, 0.0, 17.4), 2.2, 0.9)
	Tank.make_hulk(self, Vector3(22.4, 0.0, 3.0), -1.2, -0.6)
	# Breakable wooden crates.
	var crate_color := Color(0.5, 0.4, 0.27)
	for spot: Vector3 in [Vector3(6.2, 0.0, 7.2), Vector3(6.2, 0.0, 6.2), Vector3(6.4, 0.0, 15.4),
			Vector3(15.8, 0.0, 6.0), Vector3(24.2, 0.0, 3.4), Vector3(24.2, 0.0, 4.4),
			Vector3(32.0, 0.0, 11.25), Vector3(32.0, 0.0, 12.25), Vector3(19.6, 0.0, 20.6)]:
		var crate := Block.make(spot, Vector3(0.95, 0.95, 0.95), crate_color, true)
		crate.rotation.y = _rng.randf_range(-0.3, 0.3)
		add_child(crate)
	# Small stuff.
	for spot: Vector3 in [Vector3(13.9, 0.0, 9.0), Vector3(14.6, 0.0, 9.3), Vector3(26.2, 0.0, 14.2), Vector3(31.8, 0.0, 9.9)]:
		Props.drum(self, spot, _rng)
	Props.dead_palm(self, Vector3(2.4, 0.0, 19.8), _rng)
	Props.dead_palm(self, Vector3(16.6, 0.0, 1.4), _rng)
	Props.dead_palm(self, Vector3(38.4, 0.0, 11.25), _rng)
	Props.pole(self, Vector3(19.2, 0.0, 6.6), false, 0.3)
	Props.pole(self, Vector3(31.6, 0.0, 12.8), false, 0.1)
	Props.pole(self, Vector3(21.5, 0.0, 20.9), true, 1.9)
	for c: Array in [[Vector3(8.0, 0.0, 11.6), 1.2], [Vector3(16.6, 0.0, 10.4), 0.9], [Vector3(26.6, 0.0, 9.6), 1.3],
			[Vector3(33.4, 0.0, 19.0), 1.0], [Vector3(13.2, 0.0, 13.0), 0.8], [Vector3(36.0, 0.0, 5.4), 1.1],
			[Vector3(3.2, 0.0, 6.8), 0.9]]:
		Props.crater(self, c[0], c[1], _rng)
	for r: Vector3 in [Vector3(35.2, 0.0, 21.0), Vector3(2.0, 0.0, 15.0), Vector3(20.2, 0.0, 16.4)]:
		Props.rock(self, r, 0.9, _rng)
