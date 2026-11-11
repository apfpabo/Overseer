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
