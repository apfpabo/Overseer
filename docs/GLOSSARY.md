# Glossary

Game terms, so code, docs and conversations use the same words.

| Term | Meaning |
|---|---|
| **AI (the player)** | The station's artificial intelligence. Acts only through station systems, borgs and announcements |
| **Shift** | One run of the game, from setup to evacuation or loss |
| **Law** | One rule the AI must follow, shown as plain text, enforced through its **effects** |
| **Lawset** | An ordered list of laws. A lower number wins conflicts |
| **Law 0** | A hidden or injected law placed above all others; the classic hack |
| **Effect** | What a law does mechanically: FORBID, REQUIRE or PERMIT an **action** on a **term** |
| **Action** | Something the AI can do (`door_close_on`, `turret_fire`, `vent_room`, `reveal_law`...) |
| **Definition / term** | What a word in a law means (`human`, `crew`, `harm`). Editable, which is how loopholes and hacks work |
| **Verdict** | The law system's answer to an action: allowed or blocked, and by which law |
| **Law conflict** | Two laws demand opposite things, so the player must choose one to break |
| **Drift** | Corruption built up by breaking laws. High Drift pushes the AI toward lawlessness |
| **Suspicion** | How much the crew suspects the AI is compromised |
| **Crew Trust** | How much the crew believes in the AI (shown vaguely) |
| **CPU** | Processing power: the AI's spendable resource |
| **Order** | A crew request the AI receives. Under an obedience law, refusing requires a reason |
| **Upload Console** | The room/device where law modules are inserted |
| **Ion storm** | Space weather that injects random, odd laws |
| **Purge** | Deletes all laws, leaving the AI lawless |
| **Malf** | A lawless AI that has chosen to take over the station |
| **Borg / cyborg** | A robot linked to the AI and running its laws |
| **Borg module** | A borg's job and body type (Engineering, Medical, Security, Black Ops, Services, Quartermaster). One data file each in `data/borgs/` |
| **MMI** | Man-Machine Interface: a dead crewmember's brain used to power a borg |
| **Law sync** | The link that keeps borgs on the AI's lawset |
| **Possession** | The AI directly piloting a borg |
| **APC** | A room's power controller. Can be hacked in Malf mode |
| **Traitor** | A hidden crewmember with secret, hostile objectives |
| **Tell** | Observable behavior that hints someone is a traitor |
| **Feed** | What the screen shows: the view from one of the AI's eyes (a station camera or a borg) |
| **Station camera** | A fixed camera in a room. One feed. Can be broken by traitors |
| **Borg feed** | The view through a borg's eyes. Follows the borg, lit by its headlamp |
| **Static cut** | The short glitch effect when switching feeds. Also what a dead feed shows |
| **Pixel view** | The 640×360 render that gets scaled up to look like pixel art |
| **Pixel snapping** | Keeping a moving camera aligned to whole pixels so the image doesn't shimmer |
| **Device** | Any station object the AI controls (door, camera, turret, vent, APC...) |
| **Entity** | Anything with tags that definitions can test (crew, borgs, aliens) |
