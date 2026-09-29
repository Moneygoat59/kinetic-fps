# KINETIC (dead-forest survival game, Godot 4.7, GDScript)

Read `AGENTS.md` first: it holds the engineering rules (frame budget, enum states not booleans, files < 150 lines, signals, minimal-delta fixes). Follow them.

## Current direction
A psychological survival game that alternates between two levels (`LevelFlow` autoload): **Apartment 4C**
(`scenes/levels/apartment.tscn`, the main scene and first level: the walker has severe OCD and cannot leave their one-bedroom
flat; warm golden-hour light, OCD shown through the set dressing and CHECK interactions; see `tools/README.md`) and the
**dead forest** (`scenes/levels/dead_forest.tscn`: an infinitely streaming dead forest with a bunker, nuclear progression,
radiation, amber pools and stalkers). Sleeping in the apartment goes to the forest as the next night (`ForestNights`:
night 1 silent, amber undrinkable, trip at 50 m and wake; night 2 wind, amber drinkable, trip at 150 m; night 3 no buildings, the wraith stalks you closer and closer until it takes you, and you wake on the couch in the middle of the night with static on the TV and an open journal on the table (REASSURE YOURSELF: write "I am not a bad person", again and again); night 4 the full forest, which ends when the walker rides Missile Silo 00's
freight lift down from the control room (a doorway in its other wall opens on a data room of server racks, `SiloServers`): it crashes down the shaft and they wake in bed to the flat gone to squalor (`AptSqualor`:
weeks of rubbish, bin bags heaped by the door, blinds shut, grime, flies); the next sleep leads to the **silo depths**
(`scenes/levels/silo_depths.tscn`, `SiloDepthsLevel`): they come to in the wrecked lift cage at the foot of the silo, force its
gate, and have the generator hall, a stair down to the bore floor and an open vent duct they can crawl into (`VentDuct`,
`PlayerCrawl`) whose far end is the next section: the company's underground rail line (amber powered, no trains running,
violet emergency pylons; the tunnel kit is built, see "Rail tunnel kit" in `tools/README.md`; the route is still to plan;
the **records vault** (`tunnel_vault`: round vault door, paper stacks, drawings, a tape cage with a usable console) ends a
run off the maze's far corner, reached through a station (`tunnel_station`: a side platform, RECORDS name boards, a live
indicator) whose platform runs on to the vault's door); night 5+ the full forest with no ending, now reached
only from the dev menu). Movement is walk-only (`Player.walk_only`);
the older vine/bhop "Sector 00" mega-level in the README is legacy.

## Build for reuse (modular by default)
When and where possible, make things modular so they can be reused. Before building something new, check whether an existing
piece, script, texture or helper already does it, and extend that instead of making a one-off copy.
- **Assets**: build props as standalone kit pieces (`tools/blender/kit/`, one `.glb` each in `models/generated/o73_kit/`, shared
  textures and materials, origin at base centre, front +Z, 2 m grid). Buildings place kit pieces through `marker_kit_*` empties
  instead of modelling their own copies into a single mesh.
- **Code**: shared behaviour lives in small reusable scripts (`KitProp`, `O73Kit.spawn`, `bunker_fx.gd`, UI components,
  `TerminalStation` for usable computers with folders and files, `PlayerFocus` for close-ups, `TunnelLine` to lay rail
  tunnel pieces end to end) and is
  configured by parameters, not copy-pasted per building or hard-coded to one use.
- **Conventions**: document new reusable pieces and their placement rules in `tools/README.md`.

## Verify your work, do not guess
The world is procedural GDScript, so look at it. Tools live in `tools/` (see `tools/README.md`):
- `tools\capture.ps1` renders a scene/model to `shots/*.png` (read the PNG). Use `-Wait 4 -NoUi` for the forest (skips the wake-up overlay).
- `tools\smoke.ps1` loads a scene headless and reports errors and frame times.
- `tools\check.ps1` syntax-checks all scripts (~2 s). `tools\blender.ps1` runs headless Blender generators for props.
- `tools\test.ps1` runs everything: check, smoke, and every `tools/exec/check_*.gd` gameplay test (~30 s).
- The `godot` MCP server (`.mcp.json`) can run the game and take in-game screenshots.

## Known issues
- 9 scripts exceed 150 lines (largest: `small_bunker.gd`).
