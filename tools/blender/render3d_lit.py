"""Option 1 with real lighting: Cycles renderer, sun + lamp shadows, glowing
screens, then reduced to pixel art. Run with the bpy venv:
    /tmp/bvenv/bin/python render3d_lit.py OUT_DIR
"""
import math
import sys
from pathlib import Path

import bpy

OUT = Path(sys.argv[1])
OUT.mkdir(parents=True, exist_ok=True)

C = {
    "floor_a": (0.20, 0.22, 0.25), "floor_b": (0.16, 0.18, 0.21),
    "trim": (0.07, 0.08, 0.09), "wall": (0.30, 0.33, 0.38),
    "wall_top": (0.50, 0.53, 0.58), "frame": (0.12, 0.13, 0.16),
    "door": (0.85, 0.32, 0.06), "stripe": (0.95, 0.75, 0.10),
    "suit": (0.95, 0.38, 0.04), "suit_dark": (0.45, 0.16, 0.03),
    "skin": (0.85, 0.55, 0.38), "hair": (0.16, 0.09, 0.06),
    "boots": (0.05, 0.05, 0.06), "eyes": (0.02, 0.02, 0.03),
    "console": (0.22, 0.25, 0.30), "pipe": (0.40, 0.42, 0.46),
    "sec": (0.12, 0.22, 0.55), "sec_dark": (0.06, 0.10, 0.25),
}
EMIT = {"screen": ((0.20, 1.0, 0.45), 6.0), "lamp_ok": ((0.20, 1.0, 0.45), 8.0),
        "lamp_bad": ((1.0, 0.35, 0.10), 8.0), "ceiling": ((1.0, 0.85, 0.6), 6.0),
        "alarm": ((1.0, 0.05, 0.03), 12.0)}


def reset(samples=96) -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"
    sc.cycles.device = "CPU"
    sc.cycles.samples = samples
    sc.cycles.use_denoising = True
    try:
        sc.cycles.denoiser = "OPENIMAGEDENOISE"
    except Exception:
        pass
    sc.cycles.max_bounces = 4
    sc.cycles.pixel_filter_type = "BOX"
    sc.cycles.filter_width = 0.01          # no anti-aliasing: crisp pixel edges
    sc.render.film_transparent = True
    sc.view_settings.view_transform = "Standard"
    sc.view_settings.look = "None"
    sc.render.image_settings.file_format = "PNG"
    sc.render.image_settings.color_mode = "RGBA"
    world = bpy.data.worlds.new("w")
    sc.world = world
    world.use_nodes = True
    bg = world.node_tree.nodes["Background"]
    bg.inputs[0].default_value = (0.05, 0.06, 0.09, 1)
    bg.inputs[1].default_value = 1.0


def mat(name: str):
    m = bpy.data.materials.get(name)
    if m:
        return m
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    bsdf = m.node_tree.nodes["Principled BSDF"]
    if name in EMIT:
        col, strength = EMIT[name]
        bsdf.inputs["Base Color"].default_value = (*col, 1)
        bsdf.inputs["Emission Color"].default_value = (*col, 1)
        bsdf.inputs["Emission Strength"].default_value = strength
    else:
        bsdf.inputs["Base Color"].default_value = (*C[name], 1)
        bsdf.inputs["Roughness"].default_value = 0.65
        if name in ("pipe", "door", "frame"):
            bsdf.inputs["Metallic"].default_value = 0.4
    return m


def box(color, size, loc, parent=None):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
    o = bpy.context.active_object
    o.scale = size
    bpy.ops.object.transform_apply(scale=True)
    o.data.materials.append(mat(color))
    if parent:
        o.parent = parent
    return o


def light(kind, loc, energy, color=(1, 1, 1), rot=(0, 0, 0), size=0.1):
    data = bpy.data.lights.new("l", kind)
    data.energy = energy
    data.color = color
    if kind == "SUN":
        data.angle = math.radians(3)
    else:
        data.shadow_soft_size = size
    o = bpy.data.objects.new("l", data)
    bpy.context.collection.objects.link(o)
    o.location = loc
    o.rotation_euler = rot
    return o


def camera(ortho_scale, res, target=(0, 0, 0)):
    cd = bpy.data.cameras.new("cam")
    cd.type = "ORTHO"
    cd.ortho_scale = ortho_scale
    cam = bpy.data.objects.new("cam", cd)
    bpy.context.collection.objects.link(cam)
    cam.rotation_euler = (math.radians(60), 0, math.radians(45))
    dist = 20
    cam.location = (target[0] + dist * math.sin(math.radians(45)) * math.sin(math.radians(60)),
                    target[1] - dist * math.cos(math.radians(45)) * math.sin(math.radians(60)),
                    target[2] + dist * math.cos(math.radians(60)))
    sc = bpy.context.scene
    sc.camera = cam
    sc.render.resolution_x, sc.render.resolution_y = res
    sc.render.resolution_percentage = 100


def crew(loc=(0, 0, 0), facing_deg=0.0, step=0.0, suit="suit", suit_dark="suit_dark"):
    root = bpy.data.objects.new("crew", None)
    bpy.context.collection.objects.link(root)
    s = 0.12 * step
    for side in (-1, 1):
        box("boots", (0.13, 0.17, 0.10), (side * 0.09, -s * side, 0.05), root)
        box(suit_dark, (0.13, 0.15, 0.38), (side * 0.09, -s * side, 0.28), root)
        box(suit, (0.10, 0.11, 0.36), (side * 0.25, s * side, 0.66), root)
        box("skin", (0.09, 0.09, 0.08), (side * 0.25, s * side, 0.45), root)
    box(suit, (0.38, 0.28, 0.42), (0, 0, 0.68), root)
    box(suit_dark, (0.39, 0.29, 0.05), (0, 0, 0.50), root)
    box("stripe", (0.08, 0.02, 0.06), (-0.1, -0.145, 0.78), root)
    box("skin", (0.26, 0.24, 0.24), (0, 0, 1.03), root)
    box("hair", (0.28, 0.26, 0.08), (0, 0.01, 1.17), root)
    box("hair", (0.28, 0.08, 0.14), (0, 0.10, 1.08), root)
    for side in (-1, 1):
        box("eyes", (0.04, 0.02, 0.05), (side * 0.06, -0.125, 1.04), root)
    root.location = loc
    root.rotation_euler = (0, 0, math.radians(facing_deg))
    return root


def room(door_open: bool, alert: bool):
    n = 4
    for i in range(n):
        for j in range(n):
            box("floor_a" if (i + j) % 2 == 0 else "floor_b", (0.96, 0.96, 0.1), (i - 1.5, j - 1.5, -0.05))
            box("trim", (1.0, 1.0, 0.05), (i - 1.5, j - 1.5, -0.12))
    wy = 2.05
    for x in (-1.5, 1.5):
        box("wall", (1.0, 0.2, 1.6), (x, wy, 0.8))
        box("wall_top", (1.0, 0.22, 0.06), (x, wy, 1.63))
    box("frame", (0.12, 0.26, 1.6), (-0.94, wy, 0.8))
    box("frame", (0.12, 0.26, 1.6), (0.94, wy, 0.8))
    box("frame", (2.0, 0.26, 0.3), (0, wy, 1.5))
    box("wall_top", (2.0, 0.28, 0.06), (0, wy, 1.68))
    box("lamp_ok" if door_open else "lamp_bad", (0.25, 0.05, 0.06), (0, wy - 0.15, 1.5))
    gap = 0.75 if door_open else 0.0
    for sgn in (-1, 1):
        box("door", (0.88, 0.1, 1.33), (sgn * (0.44 + gap), wy, 0.67))
        box("stripe", (0.88, 0.11, 0.08), (sgn * (0.44 + gap), wy, 0.35))
    for j in range(n):
        box("wall", (0.2, 1.0, 1.6), (-2.05, j - 1.5, 0.8))
        box("wall_top", (0.22, 1.0, 0.06), (-2.05, j - 1.5, 1.63))
    # pipes along the left wall
    box("pipe", (0.08, 4.0, 0.08), (-1.9, 0, 1.35))
    box("pipe", (0.06, 4.0, 0.06), (-1.9, 0, 1.22))
    # console + glowing screen
    box("console", (0.5, 0.8, 0.7), (-1.6, 0.5, 0.35))
    box("screen", (0.06, 0.6, 0.3), (-1.33, 0.5, 0.8))
    box("console", (0.6, 0.5, 0.4), (-1.55, -1.1, 0.2))
    # wall lamp fixture
    box("alarm" if alert else "ceiling", (0.06, 0.5, 0.08), (-1.93, -0.6, 1.5))

    if alert:
        light("SUN", (0, 0, 10), 0.4, (0.6, 0.7, 1.0), rot=(math.radians(40), math.radians(-25), math.radians(-30)))
        light("POINT", (-1.6, -0.6, 1.5), 120, (1.0, 0.08, 0.05), size=0.2)
        light("POINT", (0.0, 1.6, 1.4), 25, (1.0, 0.1, 0.05), size=0.1)
        light("POINT", (-1.2, 0.5, 0.9), 15, (0.2, 1.0, 0.45), size=0.1)
        bpy.context.scene.world.node_tree.nodes["Background"].inputs[1].default_value = 0.25
    else:
        light("SUN", (0, 0, 10), 1.6, (0.85, 0.9, 1.0), rot=(math.radians(40), math.radians(-25), math.radians(-30)))
        light("POINT", (0.3, 0.2, 2.6), 90, (1.0, 0.82, 0.6), size=0.3)
        light("POINT", (-1.2, 0.5, 0.9), 15, (0.2, 1.0, 0.45), size=0.1)


def shadow_catcher(size=3.0):
    bpy.ops.mesh.primitive_plane_add(size=size, location=(0, 0, 0))
    bpy.context.active_object.is_shadow_catcher = True


def render(path: Path):
    bpy.context.scene.render.filepath = str(path)
    bpy.ops.render.render(write_still=True)


for name, door_open, alert in (("closed", False, False), ("open", True, False), ("alert", False, True)):
    reset(samples=384)
    room(door_open=door_open, alert=alert)
    crew((0.3, -0.3, 0), facing_deg=20)
    crew((0.2, 1.4, 0), facing_deg=180, step=0.8, suit="sec", suit_dark="sec_dark")
    camera(ortho_scale=7.2, res=(192, 160), target=(0, 0, 0.55))
    render(OUT / f"lit_room_{name}.png")

# Sprite renders with a shadow on the floor (shadow catcher keeps it transparent).
for d in range(8):
    for f, step in enumerate((0.0, 1.0, 0.0, -1.0)):
        reset(samples=48)
        shadow_catcher()
        crew((0, 0, 0), facing_deg=d * 45, step=step)
        light("SUN", (0, 0, 10), 4.5, (0.95, 0.95, 1.0), rot=(math.radians(40), math.radians(-25), math.radians(-30)))
        light("POINT", (1.5, -1.5, 2.0), 70, (1.0, 0.85, 0.7))
        camera(ortho_scale=2.67, res=(56, 52), target=(0, 0, 0.6))
        render(OUT / f"lit_crew_d{d}_f{f}.png")
print("done")
