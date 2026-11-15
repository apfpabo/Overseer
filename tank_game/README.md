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

Enemy tanks come in waves on a desert battlefield full of bombed-out buildings.
Each wave has one more tank than the last. Clearing a wave repairs 2 armor.
Red arrows at the screen edge point to enemies you can't see.

- Ruined walls, barriers, wrecked cars and burnt-out tanks block tanks and shells.
- Structures can be destroyed: walls crumble into rubble you can drive over, cars
  crumple, fuel drums explode (and hurt nearby tanks), palms and poles topple,
  sandbags burst. Shell blasts also chip nearby structures. Driving into crates,
  sandbags, palms, poles or drums flattens them.
- Sandbags and rubble are low: they stop tanks, but shells fly over them.
- Wooden crates break after 3 hits.
- Destroyed tanks stay on the map as burning wrecks you can use as cover.
- Enemies find their way around obstacles (pathfinding on a half-meter grid).

## Look

"3D pixel art": real 3D models (built from boxes and cylinders in code, no model or
image files) rendered at 640x360 and scaled up with sharp pixels, with dark outlines,
a limited dithered color palette, grimy textures, a warm low sun with bluish
shadows, light sand haze and blowing sand. Particle effects for muzzle blasts,
tracers, impacts (sparks, chips, dust), explosions (fireball, debris, shockwave,
smoke column) and burning wrecks. The camera looks straight down and
follows your tank.
