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

---

## Environment
- Godot executable path on the owner's machine: *(Claude: fill this in once known)*
- Cloud sessions: Claude can download the official Godot 4.6.2 Linux build (and the Windows export templates) into its scratchpad to run the headless checks and export `build/CUSTODIAN.exe`. The owner approved this on 2026-11-11.
