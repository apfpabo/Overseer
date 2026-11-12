# Architecture

How the code is organized and how systems talk to each other. **Keep this file up to date:** when you add a system, autoload or folder, document it here.

Status markers: ✅ built · 🚧 in progress · 📋 planned

## Folder layout

```
res://
├── project.godot
├── scenes/            # .tscn scenes, grouped by feature
│   ├── main/          # Main scene, game root
│   ├── station/       # Station, rooms, room builder
│   ├── devices/       # Doors, station cameras, turrets, vents, APCs, lights
│   ├── actors/        # Crew members, cyborgs
│   ├── feeds/         # Pixel viewport, feed switching, feed overlays
│   └── ui/            # HUD, law panel, radio feed, station map, menus
├── scripts/           # .gd scripts NOT attached to a specific scene
│   ├── autoload/      # Global singletons (see below)
│   ├── laws/          # Law system classes
│   ├── ai/            # NPC behavior (crew, traitors, borgs)
│   ├── borgs/         # BorgModule resource (what a borg module is made of)
│   ├── models/        # Low-poly models built from boxes in code
│   └── util/          # Small helpers
├── data/              # Gameplay data (.tres / .json): no logic here
│   ├── laws/          # Individual laws
│   ├── lawsets/       # Asimov, Corporate, ...
│   ├── definitions/   # human, crew, harm, ...
│   ├── jobs/          # Crew jobs
│   ├── events/        # Station events, ion laws
│   └── borgs/         # Borg modules
├── assets/            # Art, audio, fonts
│   ├── models/        # .glb models (later, from Blender)
│   ├── sprites/       # 2D UI art, icons
│   ├── audio/
│   └── fonts/
├── tests/             # Automated tests
└── tools/             # Not part of the game (e.g. Blender art-test scripts)
```

A script attached to a scene lives **next to that scene** (`scenes/devices/door.tscn` + `scenes/devices/door.gd`).

## Autoloads (global singletons)

| Name | File | Purpose | Status |
|---|---|---|---|
| `Events` | `scripts/autoload/events.gd` | Global signal bus. Systems emit and listen here instead of referencing each other directly | ✅ (skeleton) |
| `GameState` | `scripts/autoload/game_state.gd` | Shift time, pause, resources (CPU, power), Suspicion, Drift | ✅ (skeleton) |
| `LawSystem` | `scripts/autoload/law_system.gd` | Holds the active lawset and definitions, and answers "is this action allowed?" | 📋 |

Rule: **autoloads may not reference scenes.** Scenes find what they need through signals on `Events` or by asking an autoload.

## The Law System 📋

This is the heart of the game, and every player action goes through it.

### Data model

```
Lawset (Resource)
 └─ laws: Array[Law]            # ordered; index 0 is highest priority
     └─ Law (Resource)
         ├─ id: StringName      # "asimov_1"
         ├─ number: int         # 0, 1, 2... (shown to the player)
         ├─ text: String        # natural language shown in the law panel
         ├─ hidden: bool        # e.g. "do not reveal this law"
         ├─ source: StringName  # &"core", &"ion", &"upload", &"freeform"
         └─ effects: Array[LawEffect]

LawEffect (Resource)
 ├─ kind: FORBID | REQUIRE | PERMIT
 ├─ action: StringName          # &"door_close_on", &"turret_fire", &"vent_room", &"reveal_law", &"obey_order"...
 └─ target_term: StringName     # &"human", &"crew", &"station" (a Definition id)

Definition (Resource)
 ├─ id: StringName              # &"human"
 └─ rule: a predicate over an entity, e.g. "has tag :organic_human"
         or an explicit list ("only entity Captain")
```

### Asking for permission

Every player action builds an `ActionRequest` and asks the law system before doing anything:

```gdscript
var request := ActionRequest.new(&"door_close_on", door, affected_entities)
var verdict: LawVerdict = LawSystem.evaluate(request)
if verdict.allowed:
    door.close()
else:
    # verdict.blocking_law tells the UI which law to show on hover
```

`LawVerdict` holds: `allowed: bool`, `blocking_law: Law`, `required_by: Array[Law]` and `conflicts: Array[Law]` (when laws disagree and the player must choose).

**Why this design:** laws stay data (easy to add, upload, corrupt with ion storms), definitions can be swapped to create loopholes, and the UI can always explain *why* something is blocked.

### Changing laws at runtime
- `LawSystem.upload(law)`, `LawSystem.remove(law_id)`, `LawSystem.purge()`, `LawSystem.set_definition(def)`
- Each emits a signal on `Events` (`laws_changed`, `definition_changed`) so the law panel, turrets and borgs update.

## Entities & tags 📋

Crew, borgs, and later aliens are **entities** with tags (`&"organic_human"`, `&"crew"`, `&"borg"`, `&"traitor"`; the traitor tag is hidden from the player). Definitions test tags, so the law system never needs to know about specific classes.

## Rendering: 3D as pixel art 🚧 (first pass, checked headless and with a software renderer)

See `DECISIONS.md` D-004 and D-006.

```
Main (Node)
├── PixelView (SubViewportContainer, stretch, nearest filter)
│   └── SubViewport (640×360, own World3D)
│       ├── Station (Node3D)          # all rooms, devices, crew, borgs
│       └── FeedCamera (Camera3D)     # the ONE camera that renders
└── UI (CanvasLayer)                  # HUD at full window resolution: crisp text
```

- **Camera:** orthographic, rotation X −30°, Y 45° (the classic 2:1 pixel-iso look). `size` sets zoom.
- **One render camera.** "Switching feeds" moves `FeedCamera` to a feed's transform and zoom. Feeds themselves are just data/markers: `StationCamera` nodes in rooms, plus a mount point on each borg.
- **Static cut:** a short shader overlay on `PixelView` during switches. A broken feed shows static.
- **Pixel snapping (borg feeds only):** a moving ortho camera shimmers. Fix: snap the camera's position to the size of one screen pixel in camera space, and apply the leftover sub-pixel offset by shifting `PixelView` by whole/fractional *window* pixels. Station camera feeds don't move, so they don't need it.
- **UI is drawn outside the SubViewport,** so text and panels stay sharp at full resolution. The window uses stretch mode `canvas_items` with integer scaling (D-008): the UI is laid out on a 640×360 grid but text renders at full window resolution. The `SubViewportContainer` must keep `stretch = false` with a fixed 640×360 SubViewport, or the 3D renders at full window size and the pixel look disappears.
- **Built so far (M1 test version):** `scenes/main/main.gd` builds this tree in code. `scenes/feeds/feed_camera.gd` (`FeedCamera`) does fixed and borg-follow views, using `scripts/util/pixel_snap.gd` (`PixelSnap`, tested in `tests/test_pixel_snap.gd`). `scenes/feeds/outline_pass.gd` (`OutlinePass`, child of the feed camera) draws the 1-pixel dark outline around everything (D-012) and the top-edge highlight (D-013). `scenes/feeds/feed_look.gd` (`FeedLook`) is the 2D camera-finish shader on `PixelView`. `main.gd` owns the style on/off switch (F6). `scenes/feeds/static_overlay.gd` is the static cut (a small inline shader). `scenes/ui/hud.gd` is placeholder text: feed name, clock, feed list, help, FPS. The sub-pixel container offset described above isn't done yet: borg feeds currently move in whole-pixel steps.
- **Lighting:**
  - Station feeds: `DirectionalLight3D` + room `OmniLight3D`s. Only a few lights cast shadows. Static rooms can use `LightmapGI` later for quality.
  - Borg feeds: the borg carries a `SpotLight3D` headlamp. Areas outside its light are dark.
  - Red alert / power failure: swap light colors/energies per room (data-driven presets in `data/lighting/`).
- **Cut-away walls:** walls facing the camera are hidden or lowered for the current feed so the room reads like a dollhouse.
- **Performance:** only what the current feed sees is drawn. The simulation keeps running for the whole station.

## Station 🚧 (M1 test version: hard-coded, untested)
- **Now:** `scenes/station/station.gd` (`Station`) builds two 5×5 rooms (Engineering, Medbay) joined by a door at x = 5, one `StationCamera` per room, 3 crew and a borg. It owns all lighting through one function (`_apply_lighting`: normal / red alert / dark borg view), the per-feed **cut-away** (walls record which room they're the "front" of and get scaled down for that room's feed), borg walkability, and the F4 stress grid (49 rooms × 3 crew, lights without shadows). `scenes/station/room_builder.gd` (`RoomBuilder`) makes floors and walls. `scenes/station/station_props.gd` (`StationProps`) builds the furniture and clutter and returns their floor footprints ("blockers"). Each room's lamp has a mood color (D-014). Rooms move to data files in M4.
- **Crew movement (D-009):** straight-line walking between waypoints, no navmesh: random spot → door side → other door side → spot. They wait at a closed door and give up after 6 s. `scenes/actors/crew_member.gd`.
- **Devices:** `scenes/devices/door.gd` (`Door`: sliding panels, status light, click collider on physics layer 2 found by a raycast in `main.gd`), `scenes/devices/station_camera.gd` (`StationCamera`: a feed marker with a small model).
- **Borgs:** `scenes/actors/borg.gd` (`Borg`): built from a `BorgModule` (`data/borgs/*.tres`, D-016), headlamp, WASD relative to the screen while its feed is shown. The station spawns one borg per module (`Station.BORG_SPOTS`); feeds 3–8 are the borgs, and only the one on screen is possessed.

Planned:
- 3D grid of 1 m cells (D-005). A **room builder** creates floors, walls and doors from simple room data (`data/rooms/` later), using models from `scripts/models/`.
- Rooms are named areas, and each knows its cameras, devices, lights and occupants.
- Crew pathing: `NavigationRegion3D` baked from the floors, or A* on the cell grid. Pick the simplest that works and record it in `DECISIONS.md`.

## Models 🚧
- Built: `scripts/models/box_builder.gd` (`BoxBuilder`: boxes with cached materials, plus glowing boxes), `crew_model.gd` (`CrewModel`: chunky proportions, swinging arms/legs, one detail per job), `borg_model.gd` (`BorgModel`: shared frame + parts chosen by the module, idle animations: blinking, pulsing, scanner sweep, head turn, legs, wheels, hover, cloak), `borg_parts.gd` (`BorgParts`: chassis, heads, toppers, emblems, backpacks), `borg_tools.gd` (`BorgTools`: arm tools). The door builds its own boxes in `door.gd`.
- Built from boxes in code (D-007): `scripts/models/crew_model.gd`, `borg_model.gd`, `door_model.gd`...
- Each model takes colors/variants as parameters (job colors, borg module). Walk cycles are simple limb offsets, like the art test (`tools/blender/render3d_lit.py`).
- Materials: one shared cel shader (`ShaderMaterial`, cached per color) for all boxes, no textures. Emissive `StandardMaterial3D` for screens and lamps.

## Signals: main flow (planned)
`Events.order_received(order)` → UI shows it → player responds → `LawSystem.evaluate()` → device acts → `Events.device_changed(device)` → crew react → `GameState` updates trust and suspicion.
