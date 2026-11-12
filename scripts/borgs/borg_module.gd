class_name BorgModule
extends Resource
## A cyborg module (Engineering, Medical, Security...): its name, colors and
## which parts its body is built from. One .tres file per module in
## data/borgs/. A new module is a new data file; a new kind of part needs code
## in scripts/models/borg_parts.gd.

## Body build: STANDARD is the chunky armored frame; SLEEK is tapered and slim.
enum Frame { STANDARD, SLEEK }
enum Chassis { TREADS, HOVER, LEGS, WHEELS }
enum Head { VISOR, DOME, SLIT, EYE, TWIN_EYES, NVG }
enum Tool { NONE, WELDER, CLAW, SYRINGE, SCANNER, SHIELD, BATON, BLADE, MOP, TRAY, FORKS }
enum Back { NONE, VENTS, CANISTER, BUCKET, SHOULDER_GUN, CLOAK }
enum Topper { NONE, ANTENNA, SIREN }
enum Emblem { NONE, CORE, CROSS, STRIPES, SEAMS }

@export var id: StringName = &""
@export var display_name: String = ""
## Short code shown on the feed, e.g. "ENG".
@export var code: String = ""

@export_group("Colors")
## The module's identity color: shoulder plates, light strips, feed tint.
@export var color: Color = Color.WHITE
@export var plate_color: Color = Color.WHITE
@export var body_color: Color = Color.GRAY
## Shoulder plates. Fully transparent (the default) = use `color`.
@export var shoulder_color: Color = Color(0, 0, 0, 0)
## Visor / eye glow.
@export var eye_color: Color = Color.WHITE
## Antenna beacon, canister fluid and other secondary glows.
@export var glow_color: Color = Color.RED

@export_group("Parts")
@export var frame: Frame = Frame.STANDARD
@export var chassis: Chassis = Chassis.TREADS
@export var head: Head = Head.VISOR
@export var right_tool: Tool = Tool.NONE
@export var left_tool: Tool = Tool.NONE
@export var back: Back = Back.NONE
@export var topper: Topper = Topper.NONE
@export var emblem: Emblem = Emblem.CORE
## White headlamp for its feed. Off for borgs that light their own way
## (Black Ops sees by the green glow of its night-vision lenses).
@export var headlamp: bool = true
## Overall size: (width, height, depth) multipliers.
@export var size: Vector3 = Vector3.ONE
