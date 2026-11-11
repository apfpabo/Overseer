class_name Palette
extends RefCounted
## Every color in the game lives here (UI, models, device states, jobs).
## Values match the approved art test (tools/blender/render3d_lit.py).

# --- UI ---
const BACKGROUND := Color("0e1116")
const TEXT := Color("c9d1d9")
const TEXT_DIM := Color("6e7681")
const AI_OK := Color("3ddc84")       # loyal / healthy UI accent
const AI_WARN := Color("e3b341")
const AI_ROGUE := Color("f85149")    # subverted / lawless UI accent

# --- Station surfaces ---
const FLOOR_A := Color("3a3f47")
const FLOOR_B := Color("33373e")
const FLOOR_TRIM := Color("1f2226")
const WALL := Color("5a616c")
const WALL_CAP := Color("8a909a")
const DOOR_PANEL := Color("db5a14")
const HAZARD_STRIPE := Color("f2c12e")
const CONSOLE := Color("4b525d")
const SCREEN_GLOW := Color("3ddc84")

# --- Door status light ---
const DOOR_OPEN := Color("3ddc84")
const DOOR_CLOSED := Color("f85149")
const DOOR_BOLTED := Color("f0883e")
const DOOR_LAW_BLOCKED := Color("a371f7")

# --- Crew job colors (suit) ---
const JOB_ENGINEERING := Color("f26b0f")
const JOB_SECURITY := Color("2f4fa8")
const JOB_MEDICAL := Color("e6edf3")
const JOB_COMMAND := Color("2b6e3a")
const JOB_SCIENCE := Color("8957e5")
const SKIN := Color("e8b38c")
const HAIR := Color("4a3024")
const BOOTS := Color("1c1c22")

# --- Borg module colors ---
const BORG_SECURITY := Color("da3633")
const BORG_MEDICAL := Color("4493f8")
const BORG_ENGINEERING := Color("e3b341")

# --- Light presets ---
const LIGHT_NORMAL := Color("ffe0b0")
const LIGHT_ALERT := Color("ff2a1a")
