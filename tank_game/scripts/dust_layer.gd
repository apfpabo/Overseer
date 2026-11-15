class_name DustLayer
extends Node3D
## The light sand fog: two sheets of drifting dust above the battlefield, plus
## sand grains blowing across it. The wind blows toward +X (screen right).

const WIND: Vector2 = Vector2(1.0, 0.25)

var _sheets: Array[StandardMaterial3D] = []
var _speeds: Array[float] = [0.012, 0.02]


func _ready() -> void:
	_add_sheet(2.6, 0.13, 0.012, 7)
	_add_sheet(5.0, 0.1, 0.02, 8)
	_add_blowing_sand()


func _process(delta: float) -> void:
	for i: int in _sheets.size():
		var mat: StandardMaterial3D = _sheets[i]
		mat.uv1_offset -= Vector3(WIND.x, WIND.y, 0.0) * _speeds[i] * delta


## A wide flat sheet of see-through, patchy dust at `height` meters.
func _add_sheet(height: float, max_alpha: float, speed: float, seed_offset: int) -> void:
	var noise := FastNoiseLite.new()
	noise.seed = DesertMap.SEED + seed_offset
	noise.frequency = 0.008
	noise.fractal_octaves = 4
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1.0, 1.0, 1.0, 0.0))
	ramp.set_color(1, Color(1.0, 1.0, 1.0, max_alpha))
	ramp.add_point(0.45, Color(1.0, 1.0, 1.0, 0.0))
	var tex := NoiseTexture2D.new()
	tex.width = 512
	tex.height = 512
	tex.seamless = true
	tex.noise = noise
	tex.color_ramp = ramp
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.85, 0.74, 0.56)
	mat.albedo_texture = tex
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.uv1_scale = Vector3(1.5, 1.0, 1.0)
	var plane := PlaneMesh.new()
	plane.size = DesertMap.SIZE + Vector2(30.0, 20.0)
	var sheet := MeshInstance3D.new()
	sheet.mesh = plane
	sheet.material_override = mat
	sheet.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sheet.position = Vector3(DesertMap.SIZE.x * 0.5, height, DesertMap.SIZE.y * 0.5)
	add_child(sheet)
	_sheets.append(mat)
	_speeds[_sheets.size() - 1] = speed


## Fine sand grains streaking across the map in the wind.
func _add_blowing_sand() -> void:
	var grains := CPUParticles3D.new()
	grains.amount = 260
	grains.lifetime = 4.0
	grains.preprocess = 4.0
	grains.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	grains.emission_box_extents = Vector3(DesertMap.SIZE.x * 0.6, 1.2, DesertMap.SIZE.y * 0.6)
	grains.position = Vector3(DesertMap.SIZE.x * 0.5, 1.4, DesertMap.SIZE.y * 0.5)
	grains.direction = Vector3(WIND.x, 0.0, WIND.y)
	grains.spread = 8.0
	grains.gravity = Vector3.ZERO
	grains.initial_velocity_min = 6.0
	grains.initial_velocity_max = 11.0
	var streak := BoxMesh.new()
	streak.size = Vector3(0.35, 0.02, 0.02)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.8, 0.62, 0.35)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	streak.material = mat
	grains.mesh = streak
	grains.particle_flag_align_y = false
	grains.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(grains)
