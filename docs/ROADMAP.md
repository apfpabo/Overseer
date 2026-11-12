# Roadmap

**Claude:** read this at the start of every session. Work on the first unchecked task of the current milestone. Tick tasks (`[x]`) when the owner has tested them, and add notes under *Session log*.

## Current milestone: M1, "Two rooms, two feeds" (technical test)

**Goal:** prove the look and the performance on the owner's PC before building gameplay: real 3D displayed as pixel art, seen through camera feeds and a borg's eyes.

- [x] M0. Project skeleton, docs and Claude Code setup
- [ ] M1.1 Pixel view: 640×360 `SubViewport` scaled to the window with sharp pixels, orthographic isometric camera, one test cube lit by a light with shadows. (Owner sees: a crisp pixel-art cube.)
- [ ] M1.2 Room builder + models: build a 5×5 room from boxes (floor cells, walls, cut-away front), a console with a glowing screen, a ceiling lamp. Match the art test's look.
- [ ] M1.3 Second room joined by a sliding door (model + open/close animation). Click the door to toggle it.
- [ ] M1.4 Station camera feeds: one camera per room. Switch with keys 1/2 (and a small on-screen list), with a static cut and a "CAMERA NAME + time" overlay.
- [ ] M1.5 Crew: 3 crew models with job colors and a walk cycle, wandering between the rooms through the door (they wait when it's closed).
- [ ] M1.6 Red alert: press R to swap every light to the red-alert preset and back.
- [ ] M1.7 Borg feed: one borg with a headlamp. Its feed follows it with **pixel snapping** (no shimmer), and WASD drives it (possession).
- [ ] M1.8 Performance test: a debug key spawns 50 rooms with crew. An FPS counter is shown. The owner reports FPS on their PC.

> 🧪 **2026-11-11: all of M1.1–M1.8 built in one go as a "test version"** at the owner's request (instead of one step at a time). Nothing is ticked yet: each box gets ticked once the owner has tried it in Godot. It was written in a cloud session; it has since been run headless and screenshotted with a software renderer, but not yet on the owner's PC.

**Done when:** the owner likes how it looks, switching feeds feels good, the borg view doesn't shimmer, and FPS is comfortable (60+) in the stress test.

## Upcoming milestones (rough)

### M2: Law System core
`Law`, `LawEffect`, `Lawset`, `Definition`, `ActionRequest`, `LawVerdict`, `LawSystem.evaluate()` (logic + tests). Asimov as data. Closing the door **on** a crew member is blocked by Law 1 (purple door light, hover shows the law). Law panel UI.

### M3: Orders & Suspicion
Radio feed UI, crew orders, Comply / Refuse (+ law) / Delay, Suspicion, crew opinion of the AI. Pause and game speed.

### M4: The station
Several rooms from data, station map, picture-in-picture feeds, broken cameras (static), follow mode, power and lights, turrets (stun).

### M5: Traitor & upload console
One hidden traitor who tries to upload a Law 0. The "do not reveal" law and "state your laws".

### M6: Cyborgs
Security and Engineering borgs, tasks, law sync, borg feeds with module HUDs.

### M7: Shift loop
Shift timer, evacuation, end-of-shift report, restart with a new random crew.

**Vertical slice = M1–M7.** After that: ion storms, Drift, Malf mode, more lawsets, meta-progression (see `GAME_DESIGN.md`).

## Session log

Add one short entry per session: date, what got done, anything left half-done.

- **2026-11-11:** Project created: skeleton, docs, Claude Code config. Art direction chosen: real-time low-poly 3D as pixel art, seen through camera and borg feeds. Next: M1.1.
- **2026-11-11 (later):** Owner asked for a test version. Built a first pass of all of M1 (pixel view, two rooms + door, camera feeds with static cut, 3 crew, red alert, possessable borg with pixel snapping, F3 FPS / F4 stress test). Scripts pass a GDScript syntax check, but Godot itself couldn't be run in that session, so **nothing has been run yet**. Next: owner presses F5, reports what they see and pastes any red errors. Fix those, then tick M1 tasks one by one.
- **2026-11-11 (later still):** Got Godot 4.6.2 running in the cloud session. Import check clean, tests pass, a scripted run used every control with no errors (door click, feeds, red alert, borg driving through the door, crew crossing rooms, stress test). Screenshots (software OpenGL) showed and fixed: 3D wasn't actually pixelated, washed-out glow colors (now linear tonemap), clipped feed list. Added the 1-pixel outline on everything (owner request). Exported `build/CUSTODIAN.exe` for Windows. Still not seen on the owner's real GPU (Forward+/Vulkan).
- **2026-11-12:** Stylized look (D-013): cel-banded lighting, top-edge highlights, camera-feed finish (saturation, scanlines, vignette, noise, REC, borg tint), F6 to compare. Screenshots now use real Forward+ via software Vulkan. New `.exe` exported. Next: owner plays it and reports what they like, plus FPS from F4.
- **2026-11-12 (later):** Added tinted outlines, room color moods, chunkier crew with job details, and room clutter (D-014). New `.exe`. Next: owner feedback on the look, and FPS from F4.
- **2026-11-12 (later):** More advanced borg model with idle animation (D-015). New `.exe`.
- **2026-11-12 (later still):** Six borg modules as data (D-016), all in the test with their own feeds (keys 3–8, stress test moved to 9). Black Ops redesigned after owner feedback. Medical crosses made green (D-017). Feed list made compact. New `.exe`.
- **2026-11-12 (later still):** Black Ops rebuilt: quad NVG eyes, sleek frame, hunched, twin blades, fewer lights (D-018). New `.exe`.
