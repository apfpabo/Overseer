class_name FX
extends RefCounted
## Visual effects built from particles and lights: muzzle blasts, shell
## impacts, explosions, fire, smoke, debris and dust. Every function spawns
## its effect into `parent` (the game world) and cleans itself up.

const SAND: Color = Color(0.72, 0.62, 0.46)
const WIND: Vector3 = Vector3(0.6, 0.0, 0.15)  # smoke drifts with the wind

static var _soft: GradientTexture2D = null
static var _materials: Dictionary = {}


# --- Building blocks ---------------------------------------------------------

## A soft round dot, used as the shape of every smoke/fire/dust particle.
static func _soft_texture() -> GradientTexture2D:
	if _soft == null:
		var g := Gradient.new()
		g.set_color(0, Color(1.0, 1.0, 1.0, 1.0))
		g.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
		g.add_point(0.5, Color(1.0, 1.0, 1.0, 0.75))
		_soft = GradientTexture2D.new()
		_soft.gradient = g
		_soft.fill = GradientTexture2D.FILL_RADIAL
		_soft.fill_from = Vector2(0.5, 0.5)
		_soft.fill_to = Vector2(1.0, 0.5)
		_soft.width = 32
		_soft.height = 32
	return _soft


## Particle materials: "add" glows (fire, flashes), "mix" covers (smoke, dust),
## "solid" is lit and opaque (debris chunks), "spark" glows without a soft shape.
static func _material(kind: String) -> StandardMaterial3D:
	if _materials.has(kind):
		return _materials[kind]
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	match kind:
		"add", "mix":
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
			m.albedo_texture = _soft_texture()
			if kind == "add":
				m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		"spark":
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		"solid":
			m.roughness = 1.0
	_materials[kind] = m
	return m


static func _ramp(colors: Array[Color]) -> Gradient:
	var g := Gradient.new()
	g.set_color(0, colors[0])
	g.set_color(1, colors[colors.size() - 1])
	for i: int in range(1, colors.size() - 1):
		g.add_point(float(i) / float(colors.size() - 1), colors[i])
	return g


static func _curve(start: float, peak_at: float, end: float) -> Curve:
	var c := Curve.new()
	c.max_value = 4.0
	c.add_point(Vector2(0.0, start))
	if peak_at > 0.0:
		c.add_point(Vector2(peak_at, 1.0))
	c.add_point(Vector2(1.0, end))
	return c


## Creates a particle emitter. Options (all optional):
## amount, life, burst (bool), dir, spread, vmin, vmax, gravity, damping,
## smin, smax, grow (Curve), colors (Array[Color]), kind ("add"/"mix"/"solid"/"spark"),
## mesh (Mesh), size (quad size), box (emission box half-size), align (bool), random.
static func emitter(parent: Node, at: Vector3, o: Dictionary) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	var burst: bool = o.get("burst", true)
	var life: float = o.get("life", 1.0)
	p.amount = o.get("amount", 12)
	p.lifetime = life
	p.one_shot = burst
	p.explosiveness = 1.0 if burst else 0.0
	p.randomness = o.get("random", 0.5)
	p.lifetime_randomness = o.get("life_rand", 0.4)
	p.direction = o.get("dir", Vector3.UP)
	p.spread = o.get("spread", 45.0)
	p.initial_velocity_min = o.get("vmin", 1.0)
	p.initial_velocity_max = o.get("vmax", 3.0)
	p.gravity = o.get("gravity", Vector3.ZERO)
	p.damping_min = o.get("damping", 0.0)
	p.damping_max = o.get("damping", 0.0)
	p.scale_amount_min = o.get("smin", 1.0)
	p.scale_amount_max = o.get("smax", 1.0)
	if o.has("grow"):
		p.scale_amount_curve = o["grow"]
	if o.has("colors"):
		p.color_ramp = _ramp(o["colors"])
	p.particle_flag_align_y = o.get("align", false)
	if o.has("box"):
		p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		p.emission_box_extents = o["box"]
	var kind: String = o.get("kind", "mix")
	var mesh: Mesh = o.get("mesh", null)
	if mesh == null:
		var quad := QuadMesh.new()
		quad.size = Vector2.ONE * float(o.get("size", 1.0))
		mesh = quad
	p.mesh = mesh
	p.material_override = _material(kind)
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if kind == "solid" else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.position = at
	p.emitting = true
	# Hidden for its first frames: a brand-new emitter briefly draws as a
	# black blob before its particles are set up.
	p.visible = false
	parent.add_child(p)
	p.get_tree().create_timer(0.034, false, true).timeout.connect(p.show)
	if burst:
		_free_later(p, life * 1.5 + 0.3)
	return p


static func _free_later(node: Node, seconds: float) -> void:
	node.get_tree().create_timer(seconds).timeout.connect(node.queue_free)


## A short flash of light.
static func light_flash(parent: Node, at: Vector3, color: Color, energy: float, reach: float, seconds: float) -> void:
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = energy
	light.omni_range = reach
	light.position = at
	parent.add_child(light)
	var tween := light.create_tween()
	tween.tween_property(light, "light_energy", 0.0, seconds).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_callback(light.queue_free)


## A flat ring that races outward along the ground.
static func shockwave(parent: Node, at: Vector3, radius: float, color: Color) -> void:
	var torus := TorusMesh.new()
	torus.inner_radius = 0.85
	torus.outer_radius = 1.0
	torus.rings = 24
	torus.ring_segments = 4
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = color
	var ring := MeshInstance3D.new()
	ring.mesh = torus
	ring.material_override = m
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ring.position = Vector3(at.x, 0.08, at.z)
	ring.scale = Vector3(0.3, 0.05, 0.3)
	parent.add_child(ring)
	var tween := ring.create_tween().set_parallel(true)
	tween.tween_property(ring, "scale", Vector3(radius, 0.05, radius), 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(m, "albedo_color:a", 0.0, 0.4)
	tween.chain().tween_callback(ring.queue_free)


static func _chunk_mesh(size: float) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = Vector3(size, size * 0.6, size * 0.8)
	return b


static func _spark_mesh(length: float) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = Vector3(0.03, length, 0.03)
	return b


# --- Effects -----------------------------------------------------------------

## Cannon firing: flash out of the barrel, side blasts from the muzzle brake,
## a burst of gun smoke, and sand blown up from the ground below.
static func muzzle_blast(parent: Node, muzzle: Vector3, dir: Vector3) -> void:
	var side := dir.cross(Vector3.UP).normalized()
	var fire_colors: Array[Color] = [Color(1.0, 0.95, 0.75, 0.9), Color(1.0, 0.6, 0.2, 0.6), Color(0.8, 0.25, 0.05, 0.0)]
	# Flash: a tight cone of flame thrown forward out of the barrel.
	emitter(parent, muzzle, {"amount": 12, "life": 0.09, "dir": dir, "spread": 8.0, "vmin": 8.0, "vmax": 18.0,
		"damping": 80.0, "smin": 0.25, "smax": 0.55, "size": 0.8, "kind": "add", "colors": fire_colors,
		"grow": _curve(1.0, 0.0, 0.3)})
	# Side jets from the muzzle brake.
	for s: float in [-1.0, 1.0]:
		emitter(parent, muzzle, {"amount": 5, "life": 0.08, "dir": side * s + dir * 0.25, "spread": 8.0, "vmin": 5.0,
			"vmax": 10.0, "damping": 60.0, "smin": 0.2, "smax": 0.4, "size": 0.7, "kind": "add", "colors": fire_colors})
	# Gun smoke: a ring of grey-brown smoke pushed forward, then hanging in the air.
	emitter(parent, muzzle + dir * 0.3, {"amount": 14, "life": 1.6, "dir": dir, "spread": 50.0, "vmin": 1.0, "vmax": 5.0,
		"damping": 5.0, "gravity": WIND + Vector3.UP * 0.3, "smin": 0.35, "smax": 0.7, "size": 1.0,
		"colors": [Color(0.55, 0.5, 0.44, 0.55), Color(0.5, 0.47, 0.43, 0.3), Color(0.45, 0.43, 0.4, 0.0)] as Array[Color],
		"grow": _curve(0.5, 0.0, 2.4)})
	# Sand blown off the ground by the blast.
	var ground := Vector3(muzzle.x, 0.1, muzzle.z) - dir * 0.3
	emitter(parent, ground, {"amount": 14, "life": 1.1, "dir": Vector3(dir.x, 0.1, dir.z), "spread": 75.0,
		"vmin": 1.5, "vmax": 4.0, "damping": 3.5, "gravity": WIND, "smin": 0.4, "smax": 0.8, "size": 1.0,
		"colors": [Color(SAND, 0.5), Color(SAND, 0.0)] as Array[Color], "grow": _curve(0.6, 0.0, 2.0)})
	_flash_shape(parent, muzzle, dir)
	light_flash(parent, muzzle + Vector3.UP * 0.4, Color(1.0, 0.75, 0.45), 3.0, 5.0, 0.1)
	FollowCamera.shake(0.18)


## The muzzle flame itself: a bright spike forward, two side jets and a hot
## core, shown for a split second.
static func _flash_shape(parent: Node, muzzle: Vector3, dir: Vector3) -> void:
	var node := Node3D.new()
	node.position = muzzle
	parent.add_child(node)
	node.rotation.y = Tank.yaw_of(dir)
	var hot := StandardMaterial3D.new()
	hot.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	hot.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	hot.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	hot.albedo_color = Color(1.0, 0.8, 0.45, 1.0)
	var core := hot.duplicate() as StandardMaterial3D
	core.albedo_color = Color(1.0, 1.0, 0.85, 1.0)
	# Forward spike (tapered: two boxes), side jets, core.
	Shapes.box(node, Vector3(0.32, 0.08, 0.9), Vector3(0.0, 0.0, -0.45), hot)
	Shapes.box(node, Vector3(0.14, 0.09, 1.3), Vector3(0.0, 0.0, -0.65), core)
	Shapes.box(node, Vector3(0.7, 0.07, 0.14), Vector3(0.0, 0.0, -0.05), hot)
	Shapes.cylinder(node, 0.22, 0.22, 0.1, Vector3(0.0, 0.0, -0.1), core, Vector3.ZERO, 10)
	for child: Node in node.get_children():
		(child as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.scale = Vector3(0.6, 1.0, 0.6)
	var tween := node.create_tween().set_parallel(true)
	tween.tween_property(node, "scale", Vector3(1.2, 1.0, 1.25), 0.07)
	tween.tween_property(hot, "albedo_color:a", 0.0, 0.08)
	tween.tween_property(core, "albedo_color:a", 0.0, 0.07)
	tween.chain().tween_callback(node.queue_free)


## Shell hitting something. `kind`: "armor" (tank), "concrete", "metal", "wood", "sand".
static func impact(parent: Node, at: Vector3, kind: String) -> void:
	var spark_colors: Array[Color] = [Color(1.0, 0.95, 0.7, 1.0), Color(1.0, 0.6, 0.2, 1.0), Color(0.8, 0.25, 0.05, 0.0)]
	# Small fireball.
	emitter(parent, at, {"amount": 8, "life": 0.25, "spread": 180.0, "vmin": 0.5, "vmax": 2.5, "damping": 8.0,
		"smin": 0.5, "smax": 0.9, "size": 0.9, "kind": "add",
		"colors": [Color(1.0, 0.95, 0.75, 1.0), Color(1.0, 0.55, 0.15, 0.7), Color(0.5, 0.15, 0.05, 0.0)] as Array[Color],
		"grow": _curve(0.5, 0.25, 1.3)})
	light_flash(parent, at + Vector3.UP * 0.3, Color(1.0, 0.7, 0.4), 4.0, 5.0, 0.15)
	match kind:
		"armor", "metal":
			emitter(parent, at, {"amount": 26, "life": 0.45, "spread": 180.0, "vmin": 4.0, "vmax": 10.0,
				"gravity": Vector3(0.0, -18.0, 0.0), "damping": 2.0, "kind": "spark", "mesh": _spark_mesh(0.3),
				"align": true, "colors": spark_colors})
			smoke_puffs(parent, at, 6, Color(0.18, 0.17, 0.16), 1.2, 1.6)
		"concrete":
			debris(parent, at, Color(0.48, 0.46, 0.43), 10, 6.0, 0.14)
			dust_cloud(parent, at, Color(0.62, 0.59, 0.54), 10, 1.2)
		"wood":
			debris(parent, at, Color(0.45, 0.33, 0.2), 12, 6.0, 0.12)
			dust_cloud(parent, at, Color(0.6, 0.5, 0.36), 6, 0.9)
		_:
			dust_cloud(parent, at, SAND, 10, 1.2)
	FollowCamera.shake(0.12)


## A full explosion. `size` 1.0 is a tank being destroyed.
static func explosion(parent: Node, at: Vector3, size: float) -> void:
	var s: float = size
	light_flash(parent, at + Vector3.UP * 0.6, Color(1.0, 0.65, 0.3), 10.0 * s, 9.0 * s, 0.45)
	# Blinding core flash.
	emitter(parent, at, {"amount": 6, "life": 0.12, "spread": 180.0, "vmin": 0.0, "vmax": 1.0,
		"smin": 1.6 * s, "smax": 2.2 * s, "size": 1.0, "kind": "add",
		"colors": [Color(1.0, 1.0, 0.95, 1.0), Color(1.0, 0.85, 0.5, 0.0)] as Array[Color]})
	# Rolling fireball.
	emitter(parent, at + Vector3.UP * 0.3, {"amount": int(30 * s), "life": 0.7, "spread": 180.0,
		"vmin": 1.0 * s, "vmax": 4.5 * s, "damping": 5.0, "gravity": Vector3.UP * 1.5, "smin": 0.7 * s,
		"smax": 1.5 * s, "size": 1.0, "kind": "add", "grow": _curve(0.4, 0.2, 1.6),
		"colors": [Color(1.0, 0.95, 0.7, 1.0), Color(1.0, 0.6, 0.15, 0.95), Color(0.85, 0.25, 0.05, 0.6), Color(0.2, 0.08, 0.03, 0.0)] as Array[Color]})
	# Sparks and burning fragments.
	emitter(parent, at + Vector3.UP * 0.3, {"amount": int(36 * s), "life": 0.9, "spread": 180.0,
		"vmin": 5.0, "vmax": 13.0 * s, "gravity": Vector3(0.0, -14.0, 0.0), "damping": 1.5, "kind": "spark",
		"mesh": _spark_mesh(0.35), "align": true,
		"colors": [Color(1.0, 0.95, 0.7, 1.0), Color(1.0, 0.55, 0.15, 1.0), Color(0.6, 0.15, 0.05, 0.0)] as Array[Color]})
	debris(parent, at, Color(0.12, 0.11, 0.1), int(14 * s), 9.0 * s, 0.16)
	# Thick black smoke that lingers and drifts.
	smoke_puffs(parent, at + Vector3.UP * 0.5, int(18 * s), Color(0.1, 0.09, 0.08), 3.2, 2.8 * s)
	# Sand thrown out along the ground, and the shockwave.
	emitter(parent, Vector3(at.x, 0.15, at.z), {"amount": int(28 * s), "life": 1.4, "dir": Vector3.UP,
		"spread": 88.0, "vmin": 3.0 * s, "vmax": 7.0 * s, "damping": 5.0, "gravity": WIND, "smin": 0.8,
		"smax": 1.4, "size": 1.0, "grow": _curve(0.6, 0.0, 2.4),
		"colors": [Color(SAND, 0.65), Color(SAND.darkened(0.15), 0.3), Color(SAND, 0.0)] as Array[Color]})
	shockwave(parent, at, 4.5 * s, Color(1.0, 0.9, 0.7, 0.55))
	Smoke.scorch(parent, at, s)
	FollowCamera.shake(0.7 * s)


## Billowing smoke puffs (one burst).
static func smoke_puffs(parent: Node, at: Vector3, amount: int, color: Color, life: float, size: float) -> void:
	emitter(parent, at, {"amount": amount, "life": life, "spread": 180.0, "vmin": 0.3, "vmax": 1.5,
		"damping": 0.8, "gravity": WIND + Vector3.UP * 0.8, "smin": 0.6 * size, "smax": 1.0 * size,
		"size": 1.0, "grow": _curve(0.4, 0.0, 2.0),
		"colors": [Color(color, 0.0), Color(color, 0.75), Color(color.lightened(0.2), 0.4), Color(color, 0.0)] as Array[Color]})


## A low cloud of dust (collapsing walls, hits on concrete or sand).
static func dust_cloud(parent: Node, at: Vector3, color: Color, amount: int, size: float) -> void:
	emitter(parent, at, {"amount": amount, "life": 2.2, "spread": 180.0, "vmin": 0.5, "vmax": 2.5 * size,
		"damping": 2.0, "gravity": WIND + Vector3.UP * 0.2, "smin": 0.8 * size, "smax": 1.4 * size,
		"size": 1.0, "grow": _curve(0.5, 0.0, 2.2),
		"colors": [Color(color, 0.7), Color(color, 0.45), Color(color, 0.0)] as Array[Color]})


## Chunks thrown into the air that fall back down.
static func debris(parent: Node, at: Vector3, color: Color, amount: int, power: float, chunk: float) -> void:
	emitter(parent, at + Vector3.UP * 0.3, {"amount": amount, "life": 1.1, "dir": Vector3.UP, "spread": 70.0,
		"vmin": power * 0.4, "vmax": power, "gravity": Vector3(0.0, -22.0, 0.0), "kind": "solid",
		"mesh": _chunk_mesh(chunk), "smin": 0.6, "smax": 1.6, "colors": [color, color] as Array[Color],
		"random": 1.0})


## Continuous flames and smoke (a burning wreck). Returns the node so the
## caller can stop it; call `stop_fire()` to let it die out.
static func fire(parent: Node3D, at: Vector3, size: float) -> Node3D:
	var node := Node3D.new()
	node.position = at
	parent.add_child(node)
	var flames := emitter(node, Vector3.ZERO, {"burst": false, "amount": int(28 * size), "life": 0.6,
		"spread": 18.0, "vmin": 0.8, "vmax": 2.2, "gravity": WIND * 0.6 + Vector3.UP * 1.5, "box": Vector3(0.3, 0.05, 0.4) * size,
		"smin": 0.28 * size, "smax": 0.5 * size, "size": 1.0, "kind": "add", "grow": _curve(0.8, 0.15, 0.2),
		"colors": [Color(1.0, 0.85, 0.45, 0.0), Color(1.0, 0.65, 0.25, 0.6), Color(0.95, 0.32, 0.06, 0.45), Color(0.5, 0.1, 0.02, 0.0)] as Array[Color]})
	flames.name = "Flames"
	var smoke := emitter(node, Vector3.UP * 0.6, {"burst": false, "amount": int(20 * size), "life": 3.0,
		"spread": 15.0, "vmin": 0.8, "vmax": 1.6, "gravity": WIND * 1.4 + Vector3.UP * 0.6, "box": Vector3(0.25, 0.05, 0.25),
		"smin": 0.7 * size, "smax": 1.1 * size, "size": 1.0, "grow": _curve(0.5, 0.0, 2.8),
		"colors": [Color(0.08, 0.07, 0.06, 0.0), Color(0.1, 0.09, 0.08, 0.55), Color(0.22, 0.21, 0.2, 0.25), Color(0.3, 0.29, 0.28, 0.0)] as Array[Color]})
	smoke.name = "Smoke"
	return node


## Lets a fire from fire() die out and removes it afterwards.
static func stop_fire(node: Node3D) -> void:
	if node == null or not is_instance_valid(node):
		return
	for child: Node in node.get_children():
		if child is CPUParticles3D:
			(child as CPUParticles3D).emitting = false
	_free_later(node, 3.5)


## A continuous thin smoke trail (a badly damaged tank). Returns the emitter.
static func damage_smoke(parent: Node3D, at: Vector3) -> CPUParticles3D:
	return emitter(parent, at, {"burst": false, "amount": 14, "life": 1.8, "spread": 20.0, "vmin": 0.6,
		"vmax": 1.2, "gravity": WIND + Vector3.UP * 0.4, "smin": 0.4, "smax": 0.7, "size": 1.0,
		"grow": _curve(0.5, 0.0, 2.2),
		"colors": [Color(0.12, 0.11, 0.1, 0.0), Color(0.12, 0.11, 0.1, 0.65), Color(0.25, 0.24, 0.23, 0.0)] as Array[Color]})
