class_name Shapes
extends RefCounted
## Small helpers for building models out of boxes and cylinders in code.

static var _material_cache: Dictionary = {}
static var _grime: NoiseTexture2D = null


## A shared speckled "dirt and wear" texture. Materials multiply their color by
## it, projected from the world (triplanar) so every box gets a gritty surface.
static func grime_texture() -> NoiseTexture2D:
	if _grime == null:
		var noise := FastNoiseLite.new()
		noise.seed = 4242
		noise.noise_type = FastNoiseLite.TYPE_CELLULAR
		noise.frequency = 0.06
		noise.fractal_type = FastNoiseLite.FRACTAL_FBM
		noise.fractal_octaves = 3
		var ramp := Gradient.new()
		ramp.set_color(0, Color(0.55, 0.53, 0.5))
		ramp.set_color(1, Color(1.08, 1.06, 1.02))
		ramp.add_point(0.3, Color(0.86, 0.84, 0.8))
		ramp.add_point(0.75, Color(0.98, 0.97, 0.95))
		_grime = NoiseTexture2D.new()
		_grime.width = 256
		_grime.height = 256
		_grime.seamless = true
		_grime.noise = noise
		_grime.color_ramp = ramp
	return _grime


## Applies the grime texture to a material (world-projected, crisp pixels).
static func add_grime(m: StandardMaterial3D, scale: float = 1.0) -> void:
	m.albedo_texture = grime_texture()
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3.ONE * scale
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS


## A plain material. Materials with the same settings are shared (saves memory),
## unless `unique` is true (needed when the color will change later).
static func mat(color: Color, metal: float = 0.15, rough: float = 0.8, unique: bool = false) -> StandardMaterial3D:
	var key: String = "%s|%.2f|%.2f" % [color.to_html(), metal, rough]
	if not unique and _material_cache.has(key):
		return _material_cache[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metal
	m.roughness = rough
	add_grime(m)
	if not unique:
		_material_cache[key] = m
	return m


static func box(parent: Node3D, size: Vector3, at: Vector3, material: Material,
		rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	inst.material_override = material
	inst.position = at
	inst.rotation = rot
	parent.add_child(inst)
	return inst


static func cylinder(parent: Node3D, top: float, bottom: float, height: float, at: Vector3,
		material: Material, rot: Vector3 = Vector3.ZERO, sides: int = 14) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = height
	mesh.radial_segments = sides
	mesh.rings = 1
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	inst.material_override = material
	inst.position = at
	inst.rotation = rot
	parent.add_child(inst)
	return inst
