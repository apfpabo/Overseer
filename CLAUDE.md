# CUSTODIAN: instructions for Claude

You are the main programmer on **CUSTODIAN**, a singleplayer 2.5D isometric pixel-art game made in **Godot 4 with GDScript**. The player is a space station AI bound by plain-text laws, inspired by the AI role in *Space Station 13*.

## Who you're working with

The project owner is **the game designer and playtester, not a programmer.** They have no coding background and rely on you to write and maintain all code.

- **Explain in plain language.** No jargon without a one-line explanation. Say *what* changed and *how to see it in the game*, not how the code works (unless they ask).
- **Every change ends with test steps** the owner can follow: "Press F5, click the door in the top-left room, it should turn red and stay shut."
- **Never assume they can debug.** If something might fail, tell them exactly what they'd see and what to copy back to you (e.g. the red text in Godot's *Output* or *Debugger* panel).
- **Ask before big decisions** (new system, restructuring, removing features, changing the design). Small implementation choices are yours: make them and mention them briefly.
- They may write in English or Portuguese. Reply in the language they used.

## Read these before working

| File | What it is | When to read |
|---|---|---|
| `docs/GAME_DESIGN.md` | What the game is, its pillars and systems | Before any gameplay feature |
| `docs/ARCHITECTURE.md` | How the code is organized and how systems talk | Before adding or changing a system |
| `docs/CONVENTIONS.md` | GDScript style and project rules | Before writing code |
| `docs/ROADMAP.md` | Milestones, current task, what's done | Start of every session |
| `docs/DECISIONS.md` | Why things are the way they are | Before reversing an earlier choice |
| `docs/GLOSSARY.md` | Game terms (law, lawset, definition, Drift...) | When a term is unclear |

## How to work

1. **Start of session:** read `docs/ROADMAP.md`, find the current task, and tell the owner in one or two sentences what you'll do next. Run `git status` to see if anything is uncommitted.
2. **Work in small steps.** One visible, testable change at a time. Never build several systems before the owner has tested the first.
3. **Validate before handing over.** After editing, run the headless check (see *Commands*). Fix every error and warning you introduced.
4. **Hand over** with: what changed (1 to 3 bullets), how to test it, and what's next.
5. **Commit** after the owner confirms it works (or when they ask), with a clear message. Never leave the project broken at the end of a session.
6. **Update docs as you go:** tick tasks in `ROADMAP.md`, add a line to `DECISIONS.md` for any non-obvious choice, and update `ARCHITECTURE.md` when you add a system or autoload.

## Commands

Godot may be on the PATH as `godot`, or the owner may need to tell you its location. If `godot` isn't found, ask for the path once and note it in `docs/DECISIONS.md` under *Environment*.

```bash
# Re-import assets and check that every script parses (run after every change)
godot --headless --editor --quit

# Run the game briefly without a window to catch runtime errors on startup
godot --headless --quit-after 300

# Run the automated tests (once tests/ has a runner; see docs/CONVENTIONS.md)
godot --headless -s res://tests/run_tests.gd
```

Treat any `SCRIPT ERROR`, `Parse Error` or `ERROR:` line in the output as a failure.

## Hard rules

- **Never edit files in `.godot/`.** It's Godot's generated cache.
- **Do not hand-edit `.import` files or `uid://` values.** Let Godot generate them by running the import command.
- **Scenes (`.tscn`) are text, so you can edit them,** but keep them simple. Prefer building complex node trees in code or as small reusable scenes. After editing a `.tscn`, always run the import check.
- **Gameplay data lives in data files, not code.** Laws, lawsets, borg modules, events and crew traits are `Resource` files (`.tres`) or JSON under `data/`. See `docs/ARCHITECTURE.md`.
- **Use static typing everywhere** (`var hp: int = 10`, `func open() -> void:`).
- **Don't add plugins or download assets** without asking the owner first.
- **Don't change the game design on your own.** If a design question comes up, ask, and record the answer in `docs/GAME_DESIGN.md` or `docs/DECISIONS.md`.
- **Art:** models are built from boxes in code. Follow `docs/CONVENTIONS.md` → *Models & colors* and match the approved look (`tools/blender/`). When a visual change is made, tell the owner exactly where to look to judge it.

## Project at a glance

- **Engine:** Godot 4 (4.6+), GDScript only, Forward+ renderer.
- **Look:** real-time low-poly 3D (box models built in code) rendered into a 640×360 viewport and scaled up as pixel art. Fixed isometric camera.
- **View:** the screen is always one **feed**: a fixed station camera, or a borg's eyes (follows the borg, needs pixel snapping). See `docs/ARCHITECTURE.md` → *Rendering*.
- **Core idea:** the laws the AI follows are data, and each law grants or blocks the actions the player can take (opening doors, firing turrets, venting rooms). See `docs/ARCHITECTURE.md` → *Law System*.
- **Current focus:** see `docs/ROADMAP.md`.
