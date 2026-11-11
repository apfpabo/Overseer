class_name BoxBuilder
extends RefCounted
## Builds the chunky box meshes every model is made of (D-007).
## Materials are cached per color so identical boxes share one material.

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
static func glow_box(parent: Node3D, box_size: Vector3, center: Vector3, color: Color, energy: float = 2.0) -> MeshInstance3D:
	var mesh_instance := box(parent, box_size, center, color)
	mesh_instance.material_override = glow_material(color, energy)
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mesh_instance


## Shared rough, untextured material for a color.
static func material(color: Color) -> StandardMaterial3D:
	var key: String = color.to_html()
	if not _materials.has(key):
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		mat.roughness = 0.8
		_materials[key] = mat
	return _materials[key]


static func glow_material(color: Color, energy: float = 2.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = energy
	return mat


static func _mesh_for(box_size: Vector3) -> BoxMesh:
	var key: Vector3 = box_size.snapped(Vector3(0.001, 0.001, 0.001))
	if not _meshes.has(key):
		var mesh := BoxMesh.new()
		mesh.size = box_size
		_meshes[key] = mesh
	return _meshes[key]
