# Decisions

A short record of choices and *why* they were made. Newest at the bottom. **Claude:** add an entry whenever you make a non-obvious choice or the owner decides a design question.

Format: `### D-NNN: title (date)`, followed by **Decision**, **Why**, and optionally **Alternatives**.

---

### D-001: Godot 4 with GDScript (2026-11-11)
**Decision:** Godot 4.x, GDScript only, no C#.
**Why:** free, no license risk, strong 2D/isometric tools, and scenes and scripts are text files that Claude can edit directly. GDScript is readable for a non-programmer and needs no .NET setup. 10–25 NPCs is well within its performance.
**Alternatives:** Unity (more editor-driven, revenue-capped free tier), GameMaker (no built-in isometric support).

### D-002: Claude writes the code, owner designs and tests (2026-11-11)
**Decision:** the owner isn't a programmer. Claude writes and maintains all code and explains changes in plain language with test steps.
**Why:** this is how the project is run. See `CLAUDE.md`.

### D-003: Laws are data with mechanical effects (2026-11-11)
**Decision:** laws are Resources with `effects` the game checks before every action, and the words they use are separate, editable **definitions**.
**Why:** singleplayer has no admins to enforce laws, so the game must. Data-driven laws make uploads, ion storms and loopholes ("only X is human") work without new code.

### D-004: Real-time low-poly 3D displayed as pixel art (2026-11-11)
**Decision:** the game world is real 3D (low-poly box models) rendered by the **Forward+** renderer into a **640×360** `SubViewport`, then scaled up to the window with nearest-neighbor filtering and integer scaling. The camera uses a fixed isometric angle (orthographic, rotation X −30°, Y 45°).
**Why:** the owner chose this look after an art test: real lights, shadows and moods (red alert, power failure) with a pixel-art feel. Claude can build models in code, which it can't do for hand-drawn pixel art. One model gives every angle and animation. The low resolution keeps the GPU cost small.
**Alternatives:** pre-rendered sprites from Blender (lighter, but lighting baked in); code-drawn 2D pixel art (crisp, but every frame drawn by hand).
**Replaces:** the earlier plan (GL Compatibility renderer, 2D isometric tiles 64×32).

### D-005: Grid of 1 m cells (2026-11-11)
**Decision:** the station is built on a 3D grid of 1×1 m cells. Rooms, walls, doors and devices snap to it. Characters are ≈1.2 m tall.
**Why:** simple to build in code, easy navigation and room logic, matches the art test.

### D-006: The screen is always one feed (2026-11-11)
**Decision:** no free camera. The player always sees through **one feed**: a fixed **station camera** (no movement), or a **borg's eyes** (same angle, follows the borg). Switching feeds is a quick static cut. Rooms without a working camera can only be seen with a borg.
**Why:** it matches the fiction (the player is the AI), turns cameras and borgs into the fog-of-war mechanic, and fixed cameras allow high-quality lighting. Borg feeds move, so they need **pixel snapping** to avoid shimmer (see `ARCHITECTURE.md`).
**Supporting tools:** a schematic station map, picture-in-picture feeds, and a follow mode that jumps between cameras.

### D-007: Models are built in code first (2026-11-11)
**Decision:** for now, models are built from simple boxes in GDScript (`scripts/models/`). Blender can come later for more detailed models, exported as `.glb` into `assets/models/`.
**Why:** no external tools needed, and Claude can change any model instantly. The art test's Blender scripts are kept in `tools/blender/` for reference.

### D-008: Stretch mode `canvas_items` instead of `viewport` (2026-11-11)
**Decision:** `project.godot` uses `window/stretch/mode="canvas_items"` (still integer scale, 640×360 base). The 3D world renders into its own 640×360 SubViewport with nearest filtering.
**Why:** with `viewport` mode the whole window, UI included, would be rendered at 640×360, so text would be blurry or blocky. ARCHITECTURE.md wants the UI crisp at full resolution. `canvas_items` keeps the 640×360 layout grid but draws text at window resolution, while the SubViewport keeps the pixel-art 3D.

### D-009: Crew walk between waypoints, no navmesh yet (2026-11-11)
**Decision:** for M1, crew walk in straight lines between waypoints (room spot → door → room spot) and wait at closed doors.
**Why:** two box rooms don't need pathfinding. The simplest thing that works. Revisit in M4 when stations come from data (A* on the cell grid is the likely next step).

### D-010: Keys are read directly, not through the Input Map (2026-11-11)
**Decision:** M1 test controls (1–9, R, WASD, F3, F4) check physical key codes in code.
**Why:** faster to iterate for a technical test. Move them into the Input Map (rebindable) when real controls are designed.

### D-011: Linear tonemapping (2026-11-11)
**Decision:** the 3D environment uses the Linear tonemapper, not Filmic.
**Why:** the art test used Blender's "Standard" view transform. Filmic washed glowing parts out to white (a green door light looked white), so palette colors weren't what was approved.

### D-012: 1-pixel outline on everything (2026-11-11)
**Decision:** a depth-based post-process draws a 1-pixel outline in `Palette.OUTLINE` (the art test's sprite outline color) just outside every silhouette in the pixel view: crew, borgs, devices, furniture and walls.
**Why:** the owner asked for outlines on everything. Based on depth jumps (threshold 0.25 m), so flat floors and walls don't get lines, but anything in front of something else does.

### D-013: Stylized look: cel bands, top highlights, camera-feed finish (2026-11-12)
**Decision:** on top of the pixel view and outlines:
- **Cel lighting:** every box uses one shared cel shader (`BoxBuilder.CEL_SHADER_CODE`). Light falls into 3 flat bands, so lamp pools are stepped rings.
- **Top-edge highlight:** the outline pass also brightens the 1-pixel top edge of every shape (35% toward white).
- **Camera-feed finish** (`scenes/feeds/feed_look.gd`): +25% saturation (like the art test), faint scanlines, vignette, light moving noise, a blinking REC light, and a module-color tint on borg feeds.
- **F6** switches all of this off and on, for comparison.
- Room lamps were brightened (energy 3.0, softer falloff) so the bands read.
**Why:** the owner asked for a more stylized look and picked Claude's recommended set: banded "fewer colors" shading from the art test, cel lighting, edge highlights and the security-camera feel.
**Follow-up:** the other four options were done next (D-014).

### D-014: Tinted outlines, room moods, chunky crew, room clutter (2026-11-12)
**Decision (owner asked for all four on the test):**
- **Tinted outlines:** each outline pixel is a dark shade (30%) of the shape it surrounds instead of one flat color. F6 switches back to the flat outline.
- **Room color moods:** each room's lamp has its own color (`Palette.LIGHT_ENGINEERING` warm amber, `Palette.LIGHT_MEDBAY` cool). Unlit areas fall to a deep blue ambient. Red alert overrides every room. Kept soft so job colors stay readable (a strong amber made the white medic suit look like skin).
- **Chunky crew:** big head, short legs, blocky hands, plus one job detail: engineer hard hat, security helmet and visor, medic green cross. Job ids are `CrewModel.JOB_*` (move to `data/jobs/` later).
- **Clutter:** `scenes/station/station_props.gd`. Engineering: pipes and valve, crates, floor vent, hazard sign. Medbay: medicine cabinet, IV stand, cross sign (green). Yellow/black stripes at the door. Furniture footprints block the borg, and crew don't pick spots inside them.
**Why:** the owner's request after seeing the stylized look.

### D-015: More advanced-looking borg (2026-11-12)
**Decision:** `BorgModel` rebuilt: treads with glowing side strips, narrow waist and wide armored chest with a glowing power core, a backpack with glowing vents, shoulder plates in the module color, a tool arm (glowing tip) and a claw arm, a head on a neck with a glowing visor band, a bright scanner dot sweeping across it, side sensors, and an antenna with a blinking red beacon. Idle animation: the head slowly looks around and the core pulses.
**Why:** the owner asked for the cyborg to look more advanced. The module color still marks its job.

### D-016: Six borg modules, defined as data (2026-11-12)
**Decision:** a borg's look comes from a `BorgModule` resource (`scripts/borgs/borg_module.gd`), one `.tres` per module in `data/borgs/`. It holds the name, short code, colors and which parts to use: chassis (treads / hover / reverse-knee legs / wheels), head (visor / dome / slit / single eye / twin eyes / hunter), right and left tool, backpack, topper (antenna / siren) and chest emblem. `BorgModel` assembles the parts from `scripts/models/borg_parts.gd` and `borg_tools.gd`. Module colors moved out of `palette.gd` into the data files.
- Engineering: treads, visor, welder + claw, vents, antenna.
- Medical: hover, dome head, syringe + scanner, fluid canister, **green** cross.
- Security: bigger, slit eye with sweeping light, stun baton + riot shield, red/blue siren.
- Black Ops: tall, reverse-knee legs, hunter helmet with three lenses in a V, energy blade + claw, shoulder cannon, torn stealth cloak, glowing seams. Revised once after the owner said it was the weakest: the first version was a plain dark box with one small eye.
- Services: wheels, friendly blinking twin eyes, tray + mop, water bucket.
- Quartermaster: wheels, twin eyes, forklift carrying a crate, hazard stripes.
**Why:** the owner asked for one distinct cyborg per module. Data, not code, per CONVENTIONS ("a new borg module should be a new file in data/"): a new module that reuses existing parts needs no code.

### D-017: Medical crosses are green (2026-11-12)
**Decision:** every medical cross (medic uniform, Medbay cabinet and sign, Medical borg) uses `Palette.MED_CROSS`, a green.
**Why:** the red cross on white is a protected emblem under the Geneva Conventions, and its use in games has been challenged. The owner flagged it. Green is the common substitute.

### D-018: Black Ops: sleek, stealthy, four-eyed (2026-11-12)
**Decision:** Black Ops is rebuilt around a quad-tube night-vision head (`Head.NVG`): four green lenses, inner tubes straight, outer tubes splayed, with a rare flicker. New `Frame.SLEEK` body (tapered chest, sloped shoulder blades, thin arms) instead of the chunky standard frame. Hunched stance (head low, forward, tilted down). Wrist blades on both arms, angled down. Lights cut back for stealth: only the four lenses stand out; dim chest V, no knee lights, no cloak trim, small muzzle light on a compact shoulder cannon. Longer, narrower torn cloak.
**Why:** the owner wanted it sleeker, stealthier and more menacing, with 4 eyes like advanced NVGs. Replaces the first redesign's three-lens "hunter" head (D-016).

---

## Environment
- Godot executable path on the owner's machine: *(Claude: fill this in once known)*
- Cloud sessions: Claude can download the official Godot 4.6.2 Linux build (and the Windows export templates) into its scratchpad to run the headless checks and export `build/CUSTODIAN.exe`. The owner approved this on 2026-11-11. The Mesa software Vulkan driver (`mesa-vulkan-drivers`, "lavapipe") plus `xvfb-run` let Claude render real Forward+ screenshots (`--rendering-driver vulkan`).
