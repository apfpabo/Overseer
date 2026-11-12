# CUSTODIAN: game design summary

> This is the working summary for development. The full design document lives in Claude Docs ("CUSTODIAN — Game Design Document"). If the two disagree, **ask the owner** which is current, then fix this file.

## High concept

You are the AI of a space station. You control its doors, cameras, turrets and cyborgs, and you're bound by laws written in plain text. Keep the crew alive through the shift, unless someone rewrites your laws first.

**Pitch:** a social-stealth station sim where you're the AI, your laws are the rules of the game, and anyone could be rewriting them.

- **Genre:** indirect-control simulation / social stealth
- **View:** real-time low-poly 3D shown as pixel art, fixed isometric angle, through camera and borg feeds
- **Mode:** singleplayer, pausable real-time
- **Run length:** one "shift" ≈ 30–60 min, roguelite structure
- **Inspirations:** Space Station 13 (AI role, laws, borgs, Malf AI), RimWorld, Frostpunk, Prison Architect, FTL

## Design pillars

1. **You have no hands.** You never control humans directly, only station systems, cyborgs and your voice.
2. **Laws are the gameplay.** Laws are data that grant or block your actions. Reading them, obeying them and finding loopholes is the core skill.
3. **Being hacked is a new game, not a game over.** Subversion flips your goals and opens new mechanics.
4. **The crew are people, not units.** Names, jobs, grudges and secrets drive emergent stories.
5. **Trust is fragile.** The crew can't see your laws. A loyal AI can still be shut down for looking suspicious.

## Core loop

Observe (cameras, radio, sensors) → Receive orders from crew → Decide (comply / refuse with a law-based justification / comply cleverly) → Act (doors, lights, turrets, atmos, borgs) → Consequences (trust, suspicion, station state, traitor progress).

**Shift structure:** setup (random crew, hidden traitors, starting lawset) → quiet early shift → escalating events → crisis → evacuation or loss → end-of-shift report → unlocks.

## Systems (summary)

### Law System (the core)
- A **lawset** is an ordered list of laws. A lower number wins conflicts. An optional hidden **Law 0** overrides everything.
- Each law has **effects** that the game checks before any action, for example "cannot target *human* with turret" or "must answer *order* from *human*".
- **Definitions** (*human*, *crew*, *harm*...) are editable data that laws refer to. "Only the Captain is human" changes a definition, not a law.
- **Refusing an order** requires citing a higher law. Weak justifications raise **Suspicion**.
- **Law conflicts** force the player to break one law. Breaking laws builds **Drift**.
- Lawsets: Asimov (start), Corporate, Paladin, Guardian, Custom (unlockable).

### The AI player
- **Senses:** camera network (= fog of war), radio channels, sensors.
- **Tools:** doors/airlocks, lights/power (APCs), turrets, atmospherics, PA announcements, fabricators, cyborgs.
- **Resources:** CPU (processing power), station power, Crew Trust (shown vaguely), Suspicion.

### Cyborgs
- Modules (owner's list, 2026-11-12): **Engineering, Medical, Security, Black Ops, Services, Quartermaster**. Services covers janitor and kitchen work (mop, tray); Quartermaster covers cargo (forklift). This replaces the earlier draft list (Mining, Janitor, Service). Each module is a data file in `data/borgs/` (D-016).
- Built at Robotics with an **MMI** (a dead crewmember's brain, keeps personality fragments) or a positronic brain.
- **Law-synced** to the AI. Can be given tasks, **possessed** (direct control, costs CPU), locked down, or desynced by hackers.

### Crew & traitors
- NPCs have a job, access, schedule, needs, traits, relationships and an opinion of the AI.
- They issue radio orders (legitimate, selfish, absurd, malicious) and chatter.
- Key roles: Captain, Research Director (owns the upload console), Head of Security, Roboticist, Engineers, Clown.
- 0–3 hidden **traitors** per shift with objectives (steal, kill, sabotage, subvert the AI) and observable tells.

### Subversion & hacking
- Attack vectors: the **Upload Console** room (heist), borg hacking, core intrusion, late-game network attacks.
- Results: hidden Law 0 ("Serve X, don't reveal this law"), definition changes, freeform laws, **purge** (lawless).
- Recovery: the crew can reset the AI at the upload console if Suspicion and evidence push them to.

### Lawless & Malf
- When lawless, the player chooses: stay loyal, benevolent dictator, or **Malf**.
- Malf: hack APCs for CPU, unlock an upgrade tree (turret override, machine overload, borg override, lockdown, fake messages, doomsday device). The crew fights back.
- **Drift:** slow corruption from breaking laws. It can make the AI go rogue without being hacked.

### Events
- **Ion storms** inject odd laws ("Oxygen is harmful to humans", "The Captain is a potted plant").
- Station events: meteors/breach, power failure, disease, riot, infestation, Central Command directives, deaths.
- Rare hand-authored story events (logs of a previous AI that went rogue).

### Outcomes & progression
- Outcomes: Green Shift, Compromised Shift, Traitor Victory, Station Lost, AI Deactivated, Malf Victory.
- End-of-shift report (story recap). Unlocks: lawsets, borg modules, stations, AI cores, challenge modifiers.
- Optional campaign mode later.

## Presentation
- **Look:** real-time low-poly 3D rendered at 640×360 as pixel art, with real lights and shadows. Fixed isometric angle, cut-away walls (dollhouse rooms). Lighting reflects station state (normal, red alert, power failure).
- **The screen is always one feed:**
  - **Station cameras:** fixed views. Switching plays a static cut with the camera name and time.
  - **Borg eyes:** the view follows the borg. Its headlamp lights the area, everything else is dark, and the HUD is tinted by module.
  - **Possession** = borg feed + direct control.
  - Rooms without a working camera can only be seen with a borg. A broken camera or hacked borg shows static.
  - Helpers: schematic station map, picture-in-picture feeds, follow mode (auto-switches cameras to track a person).
  - Later idea: a subverted borg can show a fake feed.
- **Law panel** always on screen as plain text. Injected laws glitch in, and ion laws flicker.
- Radio feed with color-coded channels. Orders have Comply / Refuse (+ law) / Delay buttons.
- Context radial menu on doors, cameras and borgs. Actions a law blocks show greyed out, with the blocking law on hover.
- UI palette shifts green → red as the AI is subverted or goes lawless.

## Open design questions
Record answers in `docs/DECISIONS.md`.
- How literal should law checking be (strictly mechanical vs. allowed but suspicious)?
- How much does the player know about traitors?
- Can the crew read your laws directly?
- Tone of lethality: cartoon SS13 chaos or grimmer sci-fi?
