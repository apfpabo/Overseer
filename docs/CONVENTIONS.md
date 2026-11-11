# Conventions

Rules for code in this project. Based on the official GDScript style guide, with a few project rules on top.

## Naming

| Thing | Style | Example |
|---|---|---|
| Files & folders | `snake_case` | `law_system.gd`, `upload_console.tscn` |
| Classes (`class_name`) | `PascalCase` | `LawVerdict`, `CrewMember` |
| Functions & variables | `snake_case` | `func evaluate_request()`, `var crew_count` |
| Constants & enum values | `CONSTANT_CASE` | `const MAX_CREW := 25`, `enum Kind { FORBID, REQUIRE }` |
| Signals | past tense, `snake_case` | `signal door_opened`, `signal laws_changed` |
| Private members | leading underscore | `var _cooldown: float` |
| Node names in scenes | `PascalCase` | `DoorSprite`, `CameraCone` |
| IDs in data | `StringName`, snake_case | `&"asimov_1"`, `&"turret_fire"` |

## Script layout (order inside a `.gd` file)

1. `class_name`, then `extends`
2. `## Doc comment` explaining what the script is for (1–3 lines)
3. Signals
4. Enums, then constants
5. `@export` variables, then public variables, then private variables, then `@onready` variables
6. Built-in callbacks (`_ready`, `_process`...)
7. Public functions, then private functions

## Rules

- **Static typing always:** `var speed: float = 2.0`, `func open() -> void:`. Use `:=` only when the type is obvious from the right-hand side.
- **Signals up, calls down:** a child never reaches into its parent. It emits a signal. Unrelated systems talk through the `Events` autoload.
- **No magic strings for actions/terms:** define them once (constants or data files) and reuse them.
- **Data over code:** a new law, lawset, job, event or borg module should be a new file in `data/`, not new code. If adding one needs new code, the system is missing an abstraction, so flag it.
- **Small scripts:** if a script passes ~300 lines, propose splitting it.
- **Comments explain *why*,** not what. Use `## ` doc comments on classes and public functions.
- **No `get_node("../../..")` chains.** Use `@export var` references, `%UniqueName` nodes, or signals.
- **Pause-aware:** gameplay runs in `_process`/`_physics_process` with the default process mode, so pausing the tree pauses the simulation. UI that must work while paused uses `PROCESS_MODE_ALWAYS`.
- **Randomness:** use one seeded `RandomNumberGenerator` from `GameState` so runs can be replayed.

## Models & colors

The look is **low-poly 3D made of boxes**, rendered as pixel art (`DECISIONS.md` D-004, D-007). Match the approved art test (`tools/blender/render3d_lit.py`):

| Thing | Model |
|---|---|
| Floor | 1 m cells, alternating two greys, dark trim gap between them |
| Wall | 1.6 m tall, 0.2 m thick, lighter cap on top |
| Door | Two sliding orange panels with a yellow stripe, and a status light above: red = closed, green = open, orange = bolted, purple = blocked by a law |
| Crew | ≈1.2 m tall: boots, legs, torso, arms, head, hair, eyes. Suit color = job (orange Engineering, blue Security, white Medical...) |
| Borg | Boxy body + head with a glowing eye, module color |
| Station camera | Small box on a wall with a lens light |
| Screens & lamps | Emissive materials |

- Keep **every color** in `scripts/util/palette.gd` (job colors, module colors, device states, light presets).
- Keep models **chunky**. Details smaller than ~0.05 m vanish at 640×360.
- Check how a model reads **at actual game size**, not zoomed in.

## Tests

- Put pure-logic tests (especially the **Law System**) in `tests/`. The law system must stay testable without loading any scene.
- `tests/run_tests.gd` is a tiny runner (`extends SceneTree`) that loads every `test_*.gd` in `tests/`, calls each `test_*` function, and prints PASS/FAIL. It exits with code 1 on failure.
- Add tests for every law-system rule and every bug fixed in it.
- Adding a test framework plugin (GUT, gdUnit4) is fine later, but **ask the owner first**.

## Git

- Commit small and often, after something works.
- Message format: `area: what changed` (e.g. `laws: block turret fire on humans`, `ui: law panel shows hidden laws in red`).
- Never commit the `.godot/` folder (already in `.gitignore`).
