# CUSTODIAN

A singleplayer 2.5D isometric pixel-art game where you are a space station AI bound by plain-text laws. Built in **Godot 4** and developed mostly by **Claude Code**.

This README is for **you, the designer**. Claude reads `CLAUDE.md` and the `docs/` folder.

---

## 1. One-time setup

### Install these
1. **Godot 4** (standard version, *not* ".NET"): <https://godotengine.org/download>. On Windows it's a single `.exe` you can put anywhere, e.g. `C:\Godot\`.
2. **Git** (keeps a history so any mistake can be undone): <https://git-scm.com/downloads>. Default options are fine.
   The game uses Godot's 3D renderer (Forward+), which needs a graphics card with Vulkan support. Almost any PC from the last several years has one. If Godot shows a Vulkan error when opening the project, tell Claude.
3. **Claude Code:** use the **Code** tab in the Claude desktop app, or see <https://docs.claude.com/en/docs/claude-code/overview>.

### Put the project in place
1. Unzip this folder somewhere simple, e.g. `Documents/custodian`.
2. Open **Godot**, click **Import**, choose `project.godot` in this folder, then **Import & Edit**. Godot takes a moment the first time.
3. Press **F5** (or the ▶ button top-right). You should see a dark window with "CUSTODIAN — systems online" and a short boot log. Close it.

### First session with Claude
1. Open this folder in Claude Code.
2. Type **`/start`**. Claude reads the docs, sets up Git and tells you the first task.
3. Tell Claude where Godot is installed if it asks (e.g. `C:\Godot\Godot_v4.6.2-stable_win64.exe`). It'll remember by writing it in `docs/DECISIONS.md`.

---

## 2. Daily workflow

1. **Start:** `/start`. Claude picks up where you left off.
2. **Build:** Claude makes one small change, checks it, and tells you how to test it.
3. **Test:** in Godot, press **F5** and try exactly what Claude described.
4. **Report:**
   - It works → "Works!" Claude saves it (a Git commit) and moves on.
   - It doesn't → `/bug` and describe what you saw.
5. **End:** `/wrap-up`. Claude updates the roadmap and saves everything.

> 💡 If Godot shows red errors at the bottom (the **Output** or **Debugger** panel), copy and paste them to Claude. That's the most useful thing you can give it.

---

## 3. Commands you can type

| Command | What it does |
|---|---|
| `/start` | Begin a session: Claude reads the roadmap and proposes the next step |
| `/next` | Do the next task on the roadmap |
| `/bug` | Report something broken. Claude asks what you saw and fixes it |
| `/feature` | Suggest a new idea. Claude checks it against the design and plans it before building |
| `/explain` | Ask Claude to explain how part of the game works, in plain language |
| `/wrap-up` | End the session: update docs, save progress, summarize |

You can also just talk normally: "make the doors open slower", "the crew are walking through walls", "what should we do next?"

---

## 4. Tips for working with Claude

- **Describe what you see, not what you think the code does.** "The crew guy in the corner keeps walking into the wall and getting stuck" is perfect.
- **One thing at a time.** Small requests produce fewer bugs.
- **You own the design.** If Claude asks a design question, it really needs your answer. Don't let it guess.
- **Nothing is permanent.** Git keeps history. "Undo the last change" or "go back to how it was yesterday" both work.
- **New conversation = fresh memory.** Claude doesn't remember past chats, but it re-reads the docs, which is why `/wrap-up` matters.

---

## 5. What's in this folder

| Path | What |
|---|---|
| `CLAUDE.md` | Instructions Claude reads automatically every session |
| `docs/` | Design summary, architecture, conventions, roadmap, decisions, glossary |
| `.claude/` | Claude Code settings and the `/commands` above |
| `project.godot` | The Godot project file (open this in Godot) |
| `scenes/`, `scripts/` | The game itself (Claude's domain) |
| `data/` | Laws, lawsets and other game data |
| `assets/` | Sound, fonts, UI icons, and later 3D models from Blender |
| `tools/` | Helper scripts that aren't part of the game (the Blender art test) |
| `tests/` | Automatic checks Claude runs on the law system |
