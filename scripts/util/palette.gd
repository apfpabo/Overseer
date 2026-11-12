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

# --- Rendering ---
const OUTLINE := Color("120e1a")     # 1-pixel outline around everything (art test sprite outline)

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
const DOOR_FRAME := Color("23262c")
const BED := Color("d0d7de")
const BED_SHEET := Color("4493f8")
const CAMERA_BODY := Color("2b2f36")
const CAMERA_LENS := Color("f85149")
const LAMP := Color("ffe0b0")
const PIPE := Color("6b7480")
const PIPE_VALVE := Color("da3633")
const CRATE := Color("8a6a3e")
const CRATE_BAND := Color("4e3b22")
const VENT := Color("2a2e35")
const SIGN_DARK := Color("1c1c22")
const CABINET := Color("c9d1d9")
const MED_CROSS := Color("e5484d")
const IV_BAG := Color("9ad7ff")

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
const EYES := Color("08090b")
const HARD_HAT := Color("f2c12e")
const VISOR := Color("11151c")
const BOOTS := Color("1c1c22")

# --- Borg module colors ---
const BORG_SECURITY := Color("da3633")
const BORG_MEDICAL := Color("4493f8")
const BORG_ENGINEERING := Color("e3b341")
const BORG_BODY := Color("6e7681")
const BORG_TRACKS := Color("1c1c22")

# --- Light presets ---
const LIGHT_NORMAL := Color("ffe0b0")
const LIGHT_ENGINEERING := Color("ffcf91")   # warm amber: machines, work light
const LIGHT_MEDBAY := Color("c8ecff")        # cool, clinical
const LIGHT_ALERT := Color("ff2a1a")
const LIGHT_SUN := Color("9fb4d8")      # cool fill light through the station windows
const AMBIENT := Color("2e3d63")      # deep blue: what unlit areas fall to
