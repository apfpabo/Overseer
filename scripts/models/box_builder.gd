class_name BoxBuilder
extends RefCounted
## Builds the chunky box meshes every model is made of (D-007).
## Materials are cached per color so identical boxes share one material.
## Regular boxes use a cel shader: light falls into a few flat bands instead
## of smooth gradients, like hand-shaded pixel art (D-013).

const CEL_SHADER_CODE := """
shader_type spatial;
render_mode specular_disabled;

uniform vec4 albedo : source_color = vec4(1.0);
// Number of flat light steps between dark and fully lit. 0 = smooth (off).
uniform float bands = 3.0;

void fragment() {
	ALBEDO = albedo.rgb;
	ROUGHNESS = 1.0;
}

void light() {
	float lit = clamp(dot(NORMAL, LIGHT), 0.0, 1.0) * ATTENUATION;
	if (bands > 0.0) {
		lit = floor(lit * bands + 0.5) / bands;
	}
	DIFFUSE_LIGHT += lit * LIGHT_COLOR / PI;
}
"""

const CEL_BANDS := 3.0

static var _cel_shader: Shader
static var _cel_enabled: bool = true
static var _materials: Dictionary = {}
static var _meshes: Dictionary = {}


## Adds a box to `parent`. `center` is the box centre in the parent's space.
static func box(parent: Node3D, box_size: Vector3, center: Vector3, color: Color) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = _mesh_for(box_size)
	mesh_instance.material_override = material(color)
	mesh_instance.position = center
	parent.add_child(mesh_instance)
	return mesh_instance


## Same as box(), but glowing (screens, lamps, status lights). Gets its own
## material so its color can change without affecting other boxes.
static func glow_box(parent: Node3D, box_size: Vector3, center: Vector3, color: Color, energy: float = 1.0) -> MeshInstance3D:
	var mesh_instance := box(parent, box_size, center, color)
	mesh_instance.material_override = glow_material(color, energy)
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mesh_instance


## Shared cel-shaded, untextured material for a color.
static func material(color: Color) -> ShaderMaterial:
	var key: String = color.to_html()
	if not _materials.has(key):
		if _cel_shader == null:
			_cel_shader = Shader.new()
			_cel_shader.code = CEL_SHADER_CODE
		var mat := ShaderMaterial.new()
		mat.shader = _cel_shader
		mat.set_shader_parameter(&"albedo", color)
		mat.set_shader_parameter(&"bands", CEL_BANDS if _cel_enabled else 0.0)
		_materials[key] = mat
	return _materials[key]


static func glow_material(color: Color, energy: float = 1.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = energy
	return mat


## Turns banded (cel) lighting on or off for every box, e.g. to compare looks.
static func set_cel_enabled(enabled: bool) -> void:
	_cel_enabled = enabled
	for mat: ShaderMaterial in _materials.values():
		mat.set_shader_parameter(&"bands", CEL_BANDS if enabled else 0.0)


static func _mesh_for(box_size: Vector3) -> BoxMesh:
	var key: Vector3 = box_size.snapped(Vector3(0.001, 0.001, 0.001))
	if not _meshes.has(key):
		var mesh := BoxMesh.new()
		mesh.size = box_size
		_meshes[key] = mesh
	return _meshes[key]
