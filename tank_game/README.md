# Tank Arena

A small top-down tank game for **Godot 4.7**. It is a separate project from CUSTODIAN:
open this `tank_game` folder on its own in Godot.

## Controls

| Key | Action |
|---|---|
| W / S (or ↑ / ↓) | Drive forward / back |
| A / D (or ← / →) | Turn the tank |
| Mouse | Aim the turret |
| Left click or Space | Fire |
| R | Restart |
| Esc | Quit |

## How it plays

Enemy tanks (red) come in waves. Each wave has one more tank than the last.
Clearing a wave repairs 2 armor. Grey walls are solid, wooden crates break after 3 hits.
The game is real 3D seen from a camera straight above. The tanks are detailed 3D models
(tracks with moving treads, road wheels, sloped armor, cupola, hatches, machine gun,
antennas, smoke launchers, fuel drums, a recoiling barrel), all built from boxes and
cylinders in code, so there are no model or image files. Badly damaged tanks smoke,
and destroyed tanks leave a scorch mark.
