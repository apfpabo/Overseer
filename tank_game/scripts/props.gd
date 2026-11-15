class_name Props
extends RefCounted
## Builders for the desert map's scenery: ruined buildings, rubble, sandbags,
## barriers, wrecked cars, drums, dead palms, poles, craters and rocks.
## Each one draws its model from boxes/cylinders and adds invisible collision
## where tanks should not drive through.
##
## Heights matter: shells fly at about 0.7 m, so anything lower (sandbags,
## rubble) stops tanks but lets shells pass over it.

const CONCRETE: Array[Color] = [
	Color(0.46, 0.45, 0.43), Color(0.4, 0.39, 0.37), Color(0.5, 0.48, 0.45), Color(0.35, 0.34, 0.32),
]
const SOOT: Color = Color(0.2, 0.18, 0.16)
const RUST: Color = Color(0.35, 0.2, 0.12)
const REBAR: Color = Color(0.22, 0.16, 0.12)
const SAND: Color = Color(0.6, 0.5, 0.35)


static func _concrete(rng: RandomNumberGenerator, sooty: bool = false) -> StandardMaterial3D:
	var c: Color = CONCRETE[rng.randi_range(0, CONCRETE.size() - 1)]
	if sooty:
		c = c.lerp(SOOT, rng.randf_range(0.3, 0.6))
	return Shapes.mat(c, 0.0, 0.95)


# --- Ruined building -------------------------------------------------------

## A bombed-out building: a floor slab, broken outer walls with gaps, rubble
## and a collapsed roof slab. `w` and `d` are the outer size in meters.
static func ruin(parent: Node3D, center: Vector3, w: float, d: float, rng: RandomNumberGenerator) -> void:
	var node := Node3D.new()
	node.position = center
	parent.add_child(node)
	# Floor slab (cracked: a few pieces at slightly different heights).
	var floor_mat := Shapes.mat(Color(0.26, 0.24, 0.22), 0.0, 1.0)
	Shapes.box(node, Vector3(w, 0.06, d), Vector3(0.0, 0.03, 0.0), floor_mat)
	for i: int in 4:
		var piece := Vector3(rng.randf_range(0.8, 1.6), 0.08, rng.randf_range(0.8, 1.6))
		var at := Vector3(rng.randf_range(-w, w) * 0.35, 0.05, rng.randf_range(-d, d) * 0.35)
		Shapes.box(node, piece, at, Shapes.mat(Color(0.22, 0.2, 0.18), 0.0, 1.0), Vector3(0.0, rng.randf() * PI, 0.0))
	# Four walls. Each side gets one guaranteed wide breach so tanks can get in.
	var half := Vector2(w * 0.5, d * 0.5)
	_wall_line(node, Vector3(-half.x, 0.0, -half.y), Vector3(half.x, 0.0, -half.y), rng)
	_wall_line(node, Vector3(-half.x, 0.0, half.y), Vector3(half.x, 0.0, half.y), rng)
	_wall_line(node, Vector3(-half.x, 0.0, -half.y), Vector3(-half.x, 0.0, half.y), rng)
	_wall_line(node, Vector3(half.x, 0.0, -half.y), Vector3(half.x, 0.0, half.y), rng)
	# A corner pillar that survived, taller than the rest.
	var corner := Vector3(half.x * (1.0 if rng.randf() < 0.5 else -1.0), 0.0, half.y * (1.0 if rng.randf() < 0.5 else -1.0))
	_wall_piece(node, corner, Vector3(0.5, rng.randf_range(2.6, 3.2), 0.5), 0.0, rng)
	# Collapsed roof slab leaning inside, and rubble heaps.
	var slab := Block.make(Vector3(rng.randf_range(-0.4, 0.4) * w * 0.4, 0.0, rng.randf_range(-0.4, 0.4) * d * 0.4),
		Vector3(w * 0.45, 0.22, d * 0.4), CONCRETE[3].darkened(0.2), false)
	slab.rotation = Vector3(rng.randf_range(-0.18, 0.18), rng.randf() * PI, rng.randf_range(0.12, 0.24))
	node.add_child(slab)
	for i: int in 3:
		rubble(node, Vector3(rng.randf_range(-0.3, 0.3) * w, 0.0, rng.randf_range(-0.3, 0.3) * d), 1.0, rng)


## Walks from `a` to `b` placing wall segments of random height, with gaps.
static func _wall_line(node: Node3D, a: Vector3, b: Vector3, rng: RandomNumberGenerator) -> void:
	var length: float = a.distance_to(b)
	var dir: Vector3 = (b - a) / length
	var yaw: float = atan2(dir.x, dir.z) + PI * 0.5
	var count: int = maxi(int(length / 1.1), 3)
	var seg: float = length / float(count)
	var breach: int = rng.randi_range(1, count - 2)
	for i: int in count:
		var mid: Vector3 = a + dir * seg * (float(i) + 0.5)
		if i == breach or i == breach + 1 or rng.randf() < 0.15:
			# Blown-out section: a low rubble heap instead of wall.
			rubble(node, mid, 0.8, rng)
			continue
		var height: float = rng.randf_range(0.9, 2.3)
		_wall_piece(node, mid, Vector3(seg + 0.02, height, 0.35), yaw, rng)


## One standing chunk of wall with a jagged top and exposed rebar.
static func _wall_piece(node: Node3D, at: Vector3, size: Vector3, yaw: float, rng: RandomNumberGenerator) -> void:
	var block := Block.make(at, size, Color.WHITE, false)
	block.show_mesh = false
	block.rotation.y = yaw
	node.add_child(block)
	var mat := _concrete(rng, rng.randf() < 0.35)
	Shapes.box(block, size, Vector3(0.0, size.y * 0.5, 0.0), mat)
	# Jagged broken top: a few smaller chunks of different heights.
	for i: int in 2:
		var chunk := Vector3(size.x * rng.randf_range(0.2, 0.45), rng.randf_range(0.15, 0.5), size.z * 0.95)
		var x: float = rng.randf_range(-0.5, 0.5) * (size.x - chunk.x)
		Shapes.box(block, chunk, Vector3(x, size.y + chunk.y * 0.5 - 0.05, 0.0), mat,
			Vector3(0.0, 0.0, rng.randf_range(-0.25, 0.25)))
	# Twisted steel bars sticking out of the top.
	if rng.randf() < 0.6:
		var steel := Shapes.mat(REBAR, 0.5, 0.7)
		for i: int in rng.randi_range(2, 4):
			var x: float = rng.randf_range(-0.45, 0.45) * size.x
			var bar_len: float = rng.randf_range(0.3, 0.7)
			Shapes.cylinder(block, 0.015, 0.015, bar_len, Vector3(x, size.y + bar_len * 0.4, 0.0), steel,
				Vector3(rng.randf_range(-0.6, 0.6), 0.0, rng.randf_range(-0.6, 0.6)), 4)


## A low heap of broken concrete. Blocks tanks, shells fly over it.
static func rubble(node: Node3D, at: Vector3, spread: float, rng: RandomNumberGenerator) -> void:
	Block.collider(node, at, Vector3(spread * 0.9, 0.4, spread * 0.9), rng.randf() * PI)
	for i: int in rng.randi_range(6, 10):
		var chunk := Vector3(rng.randf_range(0.15, 0.5), rng.randf_range(0.1, 0.3), rng.randf_range(0.15, 0.5)) * spread
		var off := Vector3(rng.randf_range(-0.5, 0.5) * spread, chunk.y * 0.4, rng.randf_range(-0.5, 0.5) * spread)
		Shapes.box(node, chunk, at + off, _concrete(rng),
			Vector3(rng.randf_range(-0.5, 0.5), rng.randf() * TAU, rng.randf_range(-0.5, 0.5)))
	# Sand drifted over the base of the heap.
	Shapes.cylinder(node, spread * 0.45, spread * 0.65, 0.12, at + Vector3(0.0, 0.06, 0.0), Shapes.mat(SAND, 0.0, 1.0), Vector3.ZERO, 8)


# --- Cover -----------------------------------------------------------------

## A line of sandbags, 3 layers high (about 0.55 m). Shells pass over it.
static func sandbags(parent: Node3D, center: Vector3, length: float, yaw: float, rng: RandomNumberGenerator) -> void:
	var node := Node3D.new()
	node.position = center
	node.rotation.y = yaw
	parent.add_child(node)
	Block.collider(parent, center, Vector3(length, 0.55, 0.55), yaw)
	var bag_len: float = 0.5
	for layer: int in 3:
		var offset: float = bag_len * 0.5 if layer % 2 == 1 else 0.0
		var count: int = int((length - offset) / bag_len)
		for i: int in count:
			var shade: float = rng.randf_range(0.85, 1.05)
			var mat := Shapes.mat(Color(0.6 * shade, 0.53 * shade, 0.38 * shade), 0.0, 1.0)
			var x: float = -length * 0.5 + offset + bag_len * (float(i) + 0.5)
			var bag := Shapes.box(node, Vector3(bag_len * 0.95, 0.17, 0.42 - 0.06 * float(layer)),
				Vector3(x, 0.09 + 0.17 * float(layer), 0.0), mat, Vector3(0.0, rng.randf_range(-0.08, 0.08), 0.0))
			bag.scale = Vector3(1.0, rng.randf_range(0.85, 1.0), 1.0)


## A concrete road barrier (about 0.9 m), chipped and stained.
static func barrier(parent: Node3D, at: Vector3, yaw: float, rng: RandomNumberGenerator) -> void:
	var block := Block.make(at, Vector3(1.8, 0.95, 0.6), Color.WHITE, false)
	block.show_mesh = false
	block.rotation.y = yaw
	parent.add_child(block)
	var mat := _concrete(rng)
	Shapes.box(block, Vector3(1.8, 0.35, 0.6), Vector3(0.0, 0.175, 0.0), mat)
	Shapes.box(block, Vector3(1.8, 0.62, 0.3), Vector3(0.0, 0.62, 0.0), mat)
	Shapes.box(block, Vector3(0.3, 0.2, 0.32), Vector3(rng.randf_range(-0.6, 0.6), 0.9, 0.0), Shapes.mat(SOOT, 0.0, 1.0),
		Vector3(0.0, 0.0, 0.4))


## A burnt-out car: rusted body, collapsed cabin, no tires.
static func car_wreck(parent: Node3D, at: Vector3, yaw: float, rng: RandomNumberGenerator) -> void:
	var block := Block.make(at, Vector3(1.0, 1.0, 2.2), Color.WHITE, false)
	block.show_mesh = false
	block.rotation.y = yaw
	parent.add_child(block)
	var body := Shapes.mat(RUST.lerp(SOOT, rng.randf_range(0.2, 0.6)), 0.4, 0.8)
	var dark := Shapes.mat(Color(0.08, 0.07, 0.06), 0.2, 0.9)
	Shapes.box(block, Vector3(0.95, 0.45, 2.15), Vector3(0.0, 0.35, 0.0), body, Vector3(rng.randf_range(-0.06, 0.06), 0.0, 0.05))
	Shapes.box(block, Vector3(0.85, 0.32, 1.0), Vector3(0.0, 0.72, 0.15), body, Vector3(0.0, 0.0, -0.08))
	Shapes.box(block, Vector3(0.7, 0.05, 0.85), Vector3(0.0, 0.89, 0.15), dark)  # burnt-through roof
	Shapes.box(block, Vector3(0.8, 0.05, 0.5), Vector3(0.0, 0.6, -0.75), body, Vector3(0.3, 0.0, 0.0))  # popped hood
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-0.7, 0.7]:
			Shapes.cylinder(block, 0.17, 0.17, 0.1, Vector3(sx * 0.45, 0.14, sz), dark, Vector3(0.0, 0.0, PI * 0.5), 8)
	Smoke.scorch(parent, at, 0.8)


## Rusty fuel drum (one standing, sometimes one lying down beside it).
static func drum(parent: Node3D, at: Vector3, rng: RandomNumberGenerator) -> void:
	Block.collider(parent, at, Vector3(0.6, 0.9, 0.6))
	var colors: Array[Color] = [RUST, Color(0.3, 0.33, 0.24), Color(0.45, 0.32, 0.18)]
	var mat := Shapes.mat(colors[rng.randi_range(0, colors.size() - 1)], 0.5, 0.75)
	Shapes.cylinder(parent, 0.28, 0.28, 0.85, at + Vector3(0.0, 0.425, 0.0), mat)
	Shapes.cylinder(parent, 0.29, 0.29, 0.04, at + Vector3(0.0, 0.3, 0.0), mat)
	Shapes.cylinder(parent, 0.29, 0.29, 0.04, at + Vector3(0.0, 0.6, 0.0), mat)
	Shapes.cylinder(parent, 0.05, 0.05, 0.03, at + Vector3(0.12, 0.86, 0.0), Shapes.mat(Color(0.1, 0.1, 0.1)))


## A dead palm: a leaning trunk with drooping dry fronds.
static func dead_palm(parent: Node3D, at: Vector3, rng: RandomNumberGenerator) -> void:
	Block.collider(parent, at, Vector3(0.4, 2.0, 0.4))
	var node := Node3D.new()
	node.position = at
	node.rotation = Vector3(rng.randf_range(-0.2, 0.2), rng.randf() * TAU, rng.randf_range(-0.2, 0.2))
	parent.add_child(node)
	var trunk := Shapes.mat(Color(0.36, 0.29, 0.21), 0.0, 1.0)
	var frond := Shapes.mat(Color(0.42, 0.36, 0.22), 0.0, 1.0)
	for i: int in 6:
		Shapes.cylinder(node, 0.12, 0.15, 0.62, Vector3(0.0, 0.3 + 0.6 * float(i), 0.0), trunk, Vector3.ZERO, 8)
	for i: int in 7:
		var a: float = TAU * float(i) / 7.0 + rng.randf_range(-0.3, 0.3)
		var arm := Node3D.new()
		arm.position = Vector3(0.0, 3.6, 0.0)
		arm.rotation = Vector3(0.0, a, 0.0)
		node.add_child(arm)
		Shapes.box(arm, Vector3(0.18, 0.03, 1.4), Vector3(0.0, -0.25, 0.65), frond, Vector3(rng.randf_range(0.35, 0.7), 0.0, 0.0))


## A wooden telegraph pole, standing or fallen over.
static func pole(parent: Node3D, at: Vector3, fallen: bool, yaw: float) -> void:
	var wood := Shapes.mat(Color(0.3, 0.24, 0.18), 0.0, 1.0)
	var node := Node3D.new()
	node.position = at
	node.rotation.y = yaw
	parent.add_child(node)
	if fallen:
		Block.collider(parent, at + Vector3(0.0, 0.0, 0.0), Vector3(0.3, 0.3, 0.3))
		Shapes.cylinder(node, 0.09, 0.11, 4.5, Vector3(0.0, 0.1, -2.2), wood, Vector3(PI * 0.5, 0.0, 0.05), 8)
		Shapes.box(node, Vector3(1.2, 0.08, 0.08), Vector3(0.0, 0.25, -4.1), wood, Vector3(0.0, 0.0, 1.2))
	else:
		Block.collider(parent, at, Vector3(0.35, 2.0, 0.35))
		Shapes.cylinder(node, 0.09, 0.11, 4.5, Vector3(0.0, 2.25, 0.0), wood, Vector3(0.0, 0.0, 0.04), 8)
		Shapes.box(node, Vector3(1.3, 0.09, 0.09), Vector3(0.08, 4.1, 0.0), wood)


## A shell crater: a dark scorched hollow with a low ring of thrown-up sand.
static func crater(parent: Node3D, at: Vector3, radius: float, rng: RandomNumberGenerator) -> void:
	var inner := Shapes.mat(Color(0.3, 0.24, 0.17), 0.0, 1.0)
	var rim := Shapes.mat(Color(0.56, 0.46, 0.32), 0.0, 1.0)
	Shapes.cylinder(parent, radius * 0.8, radius * 0.8, 0.02, at + Vector3(0.0, 0.01, 0.0), inner, Vector3.ZERO, 14)
	Shapes.cylinder(parent, radius * 0.4, radius * 0.4, 0.025, at + Vector3(0.0, 0.015, 0.0), Shapes.mat(SOOT, 0.0, 1.0), Vector3.ZERO, 10)
	# Rim: short chunks laid around the edge (tangent to the circle).
	var count: int = 14
	for i: int in count:
		var a: float = TAU * float(i) / float(count)
		var r: float = radius * rng.randf_range(0.85, 1.0)
		var p := at + Vector3(cos(a), 0.0, sin(a)) * r
		var piece := Vector3(radius * 0.5, rng.randf_range(0.06, 0.14), radius * 0.28)
		Shapes.box(parent, piece, p + Vector3(0.0, piece.y * 0.4, 0.0), rim,
			Vector3(0.0, PI * 0.5 - a, rng.randf_range(-0.15, 0.15)))


## A desert rock, made of a few overlapping angular boxes.
static func rock(parent: Node3D, at: Vector3, size: float, rng: RandomNumberGenerator, solid: bool = true) -> void:
	if solid:
		Block.collider(parent, at, Vector3(size, size * 0.7, size), rng.randf() * PI)
	var shades: Array[Color] = [Color(0.55, 0.45, 0.34), Color(0.48, 0.39, 0.3), Color(0.62, 0.52, 0.39)]
	for i: int in rng.randi_range(2, 4):
		var s := Vector3(rng.randf_range(0.5, 1.0), rng.randf_range(0.35, 0.8), rng.randf_range(0.5, 1.0)) * size
		var off := Vector3(rng.randf_range(-0.25, 0.25) * size, s.y * 0.35, rng.randf_range(-0.25, 0.25) * size)
		Shapes.box(parent, s, at + off, Shapes.mat(shades[rng.randi_range(0, 2)], 0.0, 1.0),
			Vector3(rng.randf_range(-0.4, 0.4), rng.randf() * TAU, rng.randf_range(-0.4, 0.4)))
