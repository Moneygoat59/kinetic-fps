# KINETIC dev tooling

All scripts are run from anywhere; they `cd` to the project root. Godot 4.7 is on PATH; Blender 5.2 is found automatically.

| Tool | Purpose |
| :--- | :--- |
| `tools\capture.ps1` | Render a scene or `.glb` to PNG from chosen angles so the result can be looked at. Needs a GPU window (not headless). |
| `tools\smoke.ps1` | Headless load + N frames of a scene; prints node count, frame times, and script errors. |
| `tools\nights_soak.gd` | GPU soak of the real night loop: `godot --path . --script tools/nights_soak.gd -- [--apt 6] [--night 10] [--final 40]`. Apartment -> nights 1, 2, 3, 4 through `LevelFlow`, walking, then builds every night-4 POI; one `SOAK` line a second (GPU ms, VRAM, draw calls, nodes, orphans) and a light / sub-viewport census at the end. Use it to catch leaks or cost that builds up across nights. |
| `tools\test.ps1` | The whole verification pass in one command: `check.ps1`, `smoke.ps1`, then every `tools/exec/check_*.gd` hook (via `capture.ps1 -Exec`, opens a window per hook). Prints PASS / FAIL per step, exits 1 on any failure (~30 s). `-Only routes` runs matching hooks, `-NoSmoke`, `-NoCheck`. A new gameplay test = a `check_<name>.gd` hook printing `CHECK ok\|FAIL` lines; the runner picks it up. |
| `tools\check.ps1` | Syntax-checks every script in one Godot process (`tools/check_scripts.gd`, ~2 s), refreshing the class cache first when a `class_name` was added or changed; file size (AGENTS.md 3.1: note over 150 lines, fail over 250 unless grandfathered); `;`-chaining summary (`-Chains` lists files); `-Models` validates generated `.glb`. |
| `tools\blender.ps1` | Run a headless Blender Python generator (see `tools/blender/`). |
| `tools\hook_gdcheck.py` | Claude Code post-edit hook: syntax-checks an edited `.gd` file (needs registering in `.claude/settings.json`). |
| `gdlint` / `gdformat` / `gdparse` | gdtoolkit CLIs (pip). |
| `gltf-transform` / `gltfpack` | glTF inspect / validate / optimise (npm). |

## Capture examples
```powershell
# Whole level from above, UI hidden, after the wake-up intro
tools\capture.ps1 -Scene res://scenes/levels/dead_forest.tscn -Out shots/forest -Cam 0,60,80 -Look 0,0,0 -Wait 4 -NoUi
# A model from four angles, auto-framed and lit
tools\capture.ps1 -Scene res://models/generated/example_crate.glb -Out shots/crate -Views front,right,top,iso -Fit -Lit
```
Output goes to `shots/` (git-ignored). `-Exec path.gd` runs a script with `func run(scene, tree)` after load, to place the camera-target scene in a particular state (teleport the player, spawn a prop).

## Dev menu (in game, every level)
`DevTools` autoload (`scripts/dev/`). **F1** opens it (Esc closes; the game pauses while it is open):
- **JUMP TO** (keys 1-9 while open): a point in the story, built from a visit history through `LevelFlow.warp` so the level
  sets itself up as it would in play: apartment first day / evening / couch at small hours / after the crash (squalor), forest nights 1-5,
  the silo depths (woke in the wrecked lift).
  Add one = a row in `DevWarps.WARPS` (`dev_warps.gd`).
- **GO TO** (F5-F9 any time for the first five): places in the running level, read from the level itself. Apartment:
  bedside spawn + every live `AptUse` (stands you in front of it, facing it). Forest: the five POIs on nights with
  buildings (built on demand, as the story would) + the wake spot (`dev_places.gd`). Any other level lists its own with a
  `dev_places()` method returning `[label, feet position, point to face]` rows (silo depths: wrecked lift, pit door, bore
  floor, vent mouth).
- **F3 fly** (`DevFlycam`): WASD, Space/E up, Ctrl/C/Q down, Shift x3, wheel = speed (remembered per level; 3 m/s indoors,
  35 outdoors). The walker is carried under the camera with physics off, so the forest streams around the flight and
  night walking is not counted. F3 lands you where the camera is, Shift+F3 puts you back.
- **F2 fog** off/on (`DevFog`): clear 4 km view, 200 m sun shadows. A level change resets fly and fog.
`teleport_to_poi(1..5)` stays for `nights_soak.gd`.

## Model pipeline
1. Write `tools/blender/props/<name>.py` using `ps1_lib` (copy `example_crate.py`).
2. `tools\blender.ps1 tools/blender/props/<name>.py` -> `models/generated/<name>.glb` (prints tri count).
3. `tools\capture.ps1 -Scene res://models/generated/<name>.glb -Views front,iso -Fit -Lit` and look at it.
4. `tools\check.ps1 -Models` to validate. Godot imports the `.glb` automatically on next editor/game start.

## MCP
`.mcp.json` registers the `godot` MCP server (`~/tools/godot-mcp`): run/stop the project, debug output, live scene tree,
`game_screenshot`, `game_eval`, property get/set, scene create/modify. Approve it once when prompted.

## Extra tools
| Tool | Purpose |
| :--- | :--- |
| `tools\tree_dump.gd` | `godot --headless --path . --script tools/tree_dump.gd -- res://x.glb` prints the node tree as Godot imported it (meshes/tris, collision, markers). New `.glb` files need one `godot --headless --path . --import` first. |
| `tools\exec\*.gd` | Hook scripts for `capture.ps1 -Exec` (e.g. `build_small_bunker.gd` builds the procedural bunker before the shot; `spawn_outpost73.gd` spawns Outpost 73 in the forest at (0, 0, -40), door facing +Z). |
| `tools\blender\contact_check.py` | `tools\blender.ps1 tools/blender/contact_check.py tools/blender/props/outpost73_bunker.py` runs a generator up to its join and lists every part that touches nothing (floating). Run it after moving exterior parts. |
| `tools\blender\textures.py` | Regenerates the procedural PS1 textures into `models/generated/tex/`. |
| `tools\blender\props\outpost73_bunker.py` | Outpost 73 bunker generator (walkable shell, doors, markers). Naming: `*-colonly` = collision-only trimesh on import, `marker_*` = gameplay anchors. |
| `tools\audio\fx.py` | Shared post-processing for the `tools/audio/*.py` generators (`pip install scipy pedalboard pyloudnorm`): `room_ir(dims, src, ear, rt60, absorb)` is a box-room impulse response (image-source early reflections off the walls, then a darkening diffuse tail), `room(x, ir, wet)` convolves with it, `master(x, lufs)` is a glue compressor + gain to an EBU R128 loudness target + `limit()` (offline peak limiter, no latency, never more than `max_limit_db` off a transient), `save(path, x)`. Timing stays sample-exact. Level new sounds by LUFS against their neighbours (the blast door is -20 / -21), not by peak. `blast_door.py` uses it; the older scripts still use `silo_cue.reverb` and peak normalising. Don't use `pedalboard.Limiter`: it adds makeup gain. `ffmpeg` (winget `Gyan.FFmpeg`) is installed for conversion, `loudnorm` and `showspectrumpic` spectrograms. |

## Lighting bake (PS1 vertex lighting)
`tools/blender/ps1_ao.py` bakes ambient occlusion + chamfer-edge highlights into per-corner vertex colours (glTF `COLOR_0`; Godot
multiplies them into albedo). `subdivide_by_length` gives big flat faces enough vertices for the gradient; `ground_z=0` makes wall bases
darken like contact shadows. Emissive materials (name prefix `bunker_glow`) are skipped. Gotchas found the hard way:
- Blender's "Specular IOR Level" does not survive glTF export; `bunker_fx.gd make_matte()` zeroes `metallic_specular` at load.
- Godot lights an emissive surface's albedo on top of its emission, so glow materials use near-black albedo tints.
- Unshadowed directional lights shine through walls; only the level's `Moonlight` casts shadows (interior darkness comes from the baked AO + shadowed omni lights).

## Screens, decals, textures (v3)
`tools/blender/textures.py` also draws every screen and decal (uses the project's own fonts in `fonts/`):
- **Screens** (`screen_*`): amber terminal, green rad monitor, "NO SIGNAL" static, site map, generator LCD (since the kit refit only the
  site map is still built into the shell; the interior terminals are prop-kit pieces, see below). Emissive quads named `scr_*`,
  materials `bunker_scr_*`. `scripts/bunker/bunker_screens.gd` flips the `_a/_b` frame pairs on a timer (cursor blink, changing
  readings, map beacon) and scrolls/flickers the static, only while the player is within 24 m.
- **Decals** (`decal_*`, alpha-blended quads in the `bunker_decals` node): stencil lettering, radiation signs, dirt streaks, stains,
  hazard stripe, pinned notes. Offset 1-2 cm from the surface; floor decals use different heights to avoid z-fighting.
- To change screen text/graphics, edit `screens()` in `textures.py`, rerun it, then `godot --headless --path . --import`.
- Blender alpha: `material.surface_render_method = "BLENDED"` exports as glTF `alphaMode: BLEND` (see `ps1_lib.decal_material`).

## Theme (v5): an amber well that has run unattended for 200 years
Outpost 73 pulls amber (this world's energy source) out of the ground and sends it underground to the silo. Nobody has tended
it in 200 years; everything still runs. Art rules that keep it coherent:
- **Matte purple-black obsidian**: concrete textures are near-black with a violet cast (`OBSIDIAN` in `textures.py`); dirt shows up
  slightly *pale* (dust, salt bloom, dust-filled cracks). Everything is dead matte at runtime (`bunker_fx.gd make_matte`: roughness 1,
  specular 0), including metal.
- **Flat colours are linear, textures are sRGB**: a `L.material()` colour of 0.2 renders ~5x brighter than a texel of 0.2. Keep flat
  colours (rust, wood, hazard paint) around 0.01-0.05 or they read pale next to the obsidian.
- **Colour comes only from amber** (glowing liquid, crystals, window slits, screens, beacon) plus dark rust and dried-amber crust.
- **Decay is geometry + decals**: jagged broken cornice (boolean cut, `L.cut`) with rebar, rubble, fallen ladder section, dead branch and
  log from the forest, dust, papers, cracks.
- **The lure is the pump jack**: its top-of-stroke knock and bottom-of-stroke bearing groan carry ~115 m through the forest with a
  distance low-pass (`bunker_pump.gd` CARRY / MUFFLE_*), faint and muffled at the 60-70 m the bunker spawns from. The dosimeter on
  its rack only ticks (random Geiger clicks, 8 m) and is taken with [E].
- **Machinery still runs**: the pump jack behind the bunker nods (`pump_*` nodes, `scripts/bunker/bunker_pump.gd`, hum + clank), amber
  flows in the sight glasses (`bunker_amber_liquid`) and pulses in pools, the roof beacon and cabinet lamp pulse (`bunker_glow_beacon`),
  failing lamps flicker (`Fx.flicker`), the relay CRT has retried the hub for 73,051 days, the map shows the buried main to the silo (valve pit + marker sign).
- **Nothing floats**: every exterior part must touch the building, another part or the ground; check with `contact_check.py`.
- Keep exterior detail low; put new detail in textures/decals first. Amber-lit surfaces look brown fast: keep exterior light energies low (~1-2).

## Outposts 02 / 03 (variants of Outpost 73)
The wells at the ends of hub routes 02 and 03 are the Outpost 73 build with what 200 years did to them
(`tools/blender/props/outpost_variants.py`, extras in `outpost_extras.py`): same shell, door, kit furniture, pump yard, markers.
- **02 NO CARRIER**: a dead tree crushed the rear-left corner and swept the dish off the roof (it lies by the front-right corner);
  interior mirrored in X (`outpost_extras.mirror_x`: bakes, reverses faces, flips decal/screen U so text still reads); ladder intact.
- **03 SEIZED**: pump jack stalled (no `bunker_pump.gd`), the well overflowed: crystal growth in the yard and through the floor,
  wider spill, two weeping storage tanks on the right fed from the valve pit; front-left cornice broken.
- Per-well textures: `python tools/blender/textures.py outposts` (stencil number, `W-0x > HUB` main plate, site map with that
  well's beacon + fault line; flipped by `bunker_screens.gd` `bunker_scr_map0x`).
- Build: `tools\blender.ps1 tools/blender/props/outpost73_bunker.py 02` (no argument = 73, whose output must stay byte-identical),
  contact check: `tools\blender.ps1 tools/blender/contact_check.py tools/blender/props/outpost73_bunker.py 02`.
  New variant = a `VARIANTS` row (+ extras); keep 73's code path unchanged.
- Runtime: `OutpostBuilding` (`scripts/outpost_building.gd`) extends `OutpostBunker` (overrides `_model_path`, `_setup_pickup`,
  `_setup_pump`); roof beacon + pump cabinet lamp take the route colour. The item is the **route key** (kit piece `route_key`: open
  case on the desk, node `key`, lamp `kit_glow_key`) driven by `scripts/bunker/bunker_key.gd` (`TAKE ROUTE KEY 02`, emits
  `key_acquired(id)` once).
- Look at it: `$env:OUTPOST=3; tools\capture.ps1 -Scene res://scenes/levels/dead_forest.tscn -Exec res://tools/exec/spawn_outpost.gd
  -Cam 9,5,-52 -Look 1,1.5,-43 -Wait 4 -NoUi`. Wiring test: `-Exec res://tools/exec/check_outposts.gd` prints `CHECK ok|FAIL` lines.

## Outpost 73 prop kit (small set dressing, same art rules as the bunker)
19 props, one `.glb` each in `models/generated/o73_kit/`, built from the bunker's textures and material rules:
- **Terminals**: `terminal_crt` (tabletop CRT + keyboard + drive, amber relay log), `terminal_console` (standing wedge console, green
  motion sweep, stack light), `terminal_wall` (wall keypad terminal, "ACCESS DENIED" loop), `terminal_mainframe` (tape cabinet, spinning reels).
- **Furniture**: `table_steel`, `chair_steel`, `locker` (door hanging open on a rad suit), `shelf_rack` (binders, boxes, glowing sample jars).
- **Storage**: `crate_large` / `crate_small` (stackable), `drum_amber` (seeping glowing puddle), `amber_cell` (portable glowing cell).
- **Infrastructure**: `pipe_straight` / `pipe_elbow` / `pipe_valve` / `pipe_riser` (2 m grid, centreline 0.5 m, ports at cell-edge
  midpoints), `barrier_concrete` / `barrier_concrete_broken` (2 m, snap end to end), `floodlight` (shadowed spot, failing flicker).
- **Relay network**: `relay_pylon` (6.7 m relay mast: footing, rungs, cabinet with the FIELD ACTIVE 20 M plate, channel-tinted
  band + beacon `kit_glow_pylon`, guy wires, `marker_beacon`). `scripts/nuclear_pylon.gd` drives it (API unchanged: the event's
  pylon chain, the dosimeter's target, the stalkers' 20 m safe zone). The player re-aligns each relay at its cabinet with [E]
  (latch, ~1.4 s sync stutter, then steady); aligned relays stay online and clear by walking past on later trips.
  Reaching a relay: the dosimeter's soft two-pip lock (`DosimeterSounds.lock`, synthesized; no UI chime, no sync noise).
  Look: `scripts/relay_view.gd`. Ground contact: `NuclearPylon.settle(terrain)` seats the footing and the three guy anchors with
  `GroundSeat` (below); `DeadForestEvent._settle_pylons()` re-runs it after a destination's flat zone moves the ground under the
  chain's last masts. Change the mast's footing / anchors in `relay.py` = update `NuclearPylon.FOOTPRINT`.
- **Walkways** (`tools/blender/kit/walkways.py`, sizes in `kit_dims.py`, `O73Kit.STRUCTURE`): steel access pieces on the 2 m grid.
  `stair_flight` (2 m wide, 4 m up over 8 m, 20 x 0.2 risers, rails both sides; **origin = its foot**, climbing along Godot -Z;
  collision ramp + rail walls), `stair_flight_broken` (same frame, snapped 3 m below its top), `stair_landing` (4 x 2 m switchback
  landing, walking surface at y 0, two flights meet its back edge side by side), `catwalk_2m` (2 x 2 m, open ends),
  `gate_barred` (2 m chained gate), `door_blast` (two-leaf sliding door in a 4.4 x 3.1 x 0.5 m pocket housing, 2 x 2.4 m
  opening, centre plane z 0; `door_left` / `door_right` / `marker_door_center` = `BunkerDoor.mount(host, piece, Vector3(2, 2.4, 0.3))`).
  The leaves travel for `BunkerDoor.OPEN_TIME` (2.8 s, smoothstep eased) to `audio/doors/blast_door_{open,close}.wav`
  (`python tools/audio/blast_door.py`, numpy + `fx.py`, in a concrete-passage room at -20 LUFS: bolt clunk, motor drag and rumble, slam; its `TRAVEL_TIME` must match).
  Rails are **optional parts**: `k.OPT("rail_front")` / `k.OPT_COL(...)` in a builder make nodes `opt_rail_front` (+ `_col`);
  a placement drops one with a marker suffix, `marker_kit_stair_landing__3__no_rail_front` (`bunker_kit.gd furnish` /
  `drop_part`). Use it wherever a bridge, deck or wall meets the piece.
- **Vent ducts** (`tools/blender/kit/ducts.py`, sizes `DUCT_*` in `kit_dims.py` = `O73Kit.DUCT_W / DUCT_H`, group
  `O73Kit.DUCTS`): square sheet-steel ducts big enough to crawl through (1.2 x 1.0 m clear), 2 m grid, crawling surface at
  y 0, runs along local Z. `duct_straight` (2 m, centred), `duct_bend` (90 deg corner in one 2 m cell, open on its Blender
  -Y and +X edges: walked from +X to -Y it is a left turn), `duct_mouth` (flanged frame on a wall face, front +Z into the
  room, a 1.2 m stub into the wall, bent screws; `marker_crawl` inside), `duct_grille` (the loose grille: lies flat, origin
  at its bottom edge, lean it by tilting the marker), `duct_cap` (blanking plate with a glowing louvred slot and a pulsing
  `marker_light_amber`: the end of a run, for now). Cut the wall behind a mouth (`L.cut`). **VentDuct**
  (`scripts/world/vent_duct.gd`, reusable): `VentDuct.mount(mouth_piece)` adds an Area3D in the opening that the walker's
  aim finds: CLIMB INTO DUCT (within 2.2 m) eases them up onto `marker_crawl` in the crawl stance, CLIMB OUT eases them down
  onto the floor in front, standing (FSM OUTSIDE / CLIMBING_IN / INSIDE / CLIMBING_OUT, `climbed(inside)`). The stance is
  **PlayerCrawl** (`scripts/player_crawl.gd`, `player.crawl.set_stance(player, PlayerCrawl.Stance.CRAWL)`): 0.8 m capsule,
  eyes at 0.55 m, 1.4 m/s, no jump, sheet-metal knocks for steps; STAND puts the standing values back.
- **Server room** (`tools/blender/kit/servers.py`, sizes `SRV_*` / `TRAY_*` in `kit_dims.py`, group `O73Kit.SERVERS`, indoor
  only): `server_rack` (0.6 x 1.0 x 2.1 m, no front door; the equipment face is one emissive quad `kit_scr_rack` whose three
  frames flicker the activity LEDs; optional part `risers` = cables up into a `cable_tray` over it, drop with `__no_risers`),
  `server_rack_open` (the same cabinet gutted: door swung out into the aisle, blades pulled out or on the floor, cables
  spilling, face `kit_scr_rack_dead`), `terminal_server` (operator console: desk, hutch, big CRT `kit_scr_nodes` = node
  status board, keyboard, lamp row, drive slots; put a `chair_steel` in front), `crac_unit` (1.2 x 0.8 x 2.2 m cooling
  cabinet, LCD `kit_scr_crac`, green glow), `cable_tray` (2 m ladder tray along its local Z with cables, joins end to end;
  origin = tray underside, hanger rods reach `TRAY_HANG` 0.8 m up: mount it at ceiling - 0.8; no collision). Screens and the
  data room stencil: `python tools/blender/server_textures.py` (`tex/kit_screen_{rack,rack_dead,nodes,crac}_*.png`,
  `tex/silo_sign_data.png`), then rebuild the pieces (they embed their first frame).
- **Batching**: `KitBatch.merge(root, markers[, shadow])` (`scripts/props/kit_batch.gd`) redraws the static meshes (`body`,
  `panels`, `decals`, `opt_*`) of many placed kit pieces as one MultiMeshInstance3D per mesh (the silo tower: 32 pieces, 273
  surfaces -> ~67). A batch is culled as one box, so batch far-apart groups separately and pass
  `GeometryInstance3D.SHADOW_CASTING_SETTING_OFF` for groups no shadowed light reaches (shadow passes were most of the cost).
  Decals never cast shadows. `AbyssFog` handles the batches.
- **GroundSeat** (`scripts/world/ground_seat.gd`): `base_y(terrain, pos, yaw, footprint, sink)` puts a footed prop low enough
  that none of its ground contacts float on a slope. Footprint rows = `Vector3(local x, max height of the base above the ground
  there, local z)`.
- **Vignettes**: `scripts/world/kit_vignettes.gd` (data-driven `VIGNETTES`: supply_cache, checkpoint, drum_dump, exposed_main,
  dead_relay). `DeadForestEvent` drops one beside every relay leg longer than 60 m, 8-14 m off the line, on a cleared flat pad.
  They stand in open forest, so only outdoor kit belongs in them: `build()` refuses `O73Kit.TERMINALS` / `O73Kit.FURNITURE`
  (desks, chairs, computers stay inside buildings).
  Kit lights fade out beyond ~55 m (`kit_lights.gd`) so scattered props stay cheap.
- **Equipment**: `route_key` (Outposts 02 / 03: see above), `dosimeter` (the carried field tracker: needle node `needle`, live display surface `kit_scr_dosi`, click LED
  `kit_glow_dosi_led`, channel lamp `kit_glow_dosi_lamp`; no collision) and `dosimeter_rack` (wall shadow board, 3 hooks; slots 01/02
  signed out on day 112). Geometry and the painted outlines share `tools/blender/kit/kit_dims.py`, so change sizes there only.

Rebuild: `python tools/blender/kit_textures.py` (kit screens/labels -> `tex/kit_*.png`), then
`tools\blender.ps1 tools/blender/props/o73_kit.py [name ...]`, then `godot --headless --path . --import`. Builders live in
`tools/blender/kit/` (`kit_lib.py` holds the conventions). Each new `.glb` gets a `.glb.import` that embeds its textures (no per-prop
PNG copies) and runs `tools/o73_kit_import.gd`: matte materials + `scripts/props/kit_prop.gd` on the root, so a prop dragged into any
scene is live (screens cycle, lamps blink, amber flows, reels turn, lights appear; animation only while on screen).
- **Placement**: origin at the base centre, front faces +Z. `terminal_wall` has its back on z = 0 (put it flush on a wall). Tabletop
  props go on `table_steel` at `O73Kit.TABLE_TOP` (0.78). From code: `O73Kit.spawn(&"drum_amber", parent, xform)` (`scripts/props/o73_kit.gd`).
- **Node contract**: `body` (baked AO), `panels`, `screens` (`kit_scr_*`), `decals`, `spin_*`, `collision-colonly`,
  `marker_light_<screen|green|amber>*` / `marker_spot*` (presets in `scripts/props/kit_lights.gd`). New screen frames go in
  `kit_prop.gd` `SCREENS`.
- **Reusable runtime pieces**: `PixelScreen` (`scripts/ui/pixel_screen.gd`: live low-res display rendered onto any `kit_scr_*`
  surface), `InteractPrompt` (`scripts/ui/interact_prompt.gd`: amber key-cap prompt plate), `O73Kit.own_material` (per-instance
  copy of a named surface material). The dosimeter uses all three: `DosimeterView` (held, driven by `RadiationDosimeter`) and
  `bunker_pickup.gd` (hanging on the rack, rattles with each locator chirp).
- **Bunker interior**: Outpost 73 is furnished with the kit. `KIT` in `outpost73_bunker.py` places `marker_kit_<prop>__<n>` empties
  (position + yaw, plus an AO proxy box so the floor/walls darken around each piece); `scripts/bunker/bunker_kit.gd` spawns the
  live props there when the bunker is built. Move a piece = edit its `KIT` row and rebuild the bunker (then `contact_check.py`).
- **Router console** `terminal_router` (`tools/blender/kit/router.py`): wide floor console, four route keys
  (`kit_glow_route_1..4`, tinted per channel), leaning screen `kit_scr_route` (placeholder frame; `HubConsoleView` draws the live
  routing table on it with `PixelScreen`). Indoor only (in `O73Kit.TERMINALS`). Collision: the body up to the deck's front edge
  plus a block behind the screen, so the deck stays open for the aim ray to reach the route keys.
- **Look at it**: `scenes/dev/o73_kit_showcase.tscn` (dressed room in bunker light), the model gallery ("Outpost 73 Bunker & Prop Kit"
  aisle), or in the forest: `tools\capture.ps1 -Scene res://scenes/levels/dead_forest.tscn -Exec res://tools/exec/spawn_o73_kit.gd -Cam 30,2.2,-19 -Look 30,0.8,-30 -Wait 4 -NoUi`.

## Rail tunnel kit (the line under the silo)
The section past the silo vent: the company's underground rail line, amber powered, no trains running. Same art rules as
Outpost 73 (obsidian, 200 years unattended, colour only from amber) plus one colour of its own: the **emergency system is
violet** (glow `kit_glow_emergency`, paint `kit_violet`, `EmergencyPylon.COLOR`); nothing else in the world uses it.
- **Pieces** (`O73Kit.TUNNELS`, `O73Kit.RAIL`; builders `tools/blender/kit/tunnels.py` + `rail_props.py`, shared geometry
  `tunnel_lib.py`, sizes `TUN_*` / `TRACK_X` / `WALK_*` / `REFUGE_*` / `VENT_*` in `kit_dims.py`): single-track bore 6 m wide,
  walls to 2.6 m then a semicircular arch (5.6 m at the crown), 0.35 m lining with a segment ring every 2 m. Slab track (rails
  at `TRACK_X` -0.6, standard gauge), the **amber conductor rail** on the left (a faint amber line in a glass channel: the one
  light the line still carries, material `kit_glow_rail`), the drain, the amber main with a sight glass on the left wall,
  cable racks + handrail over the raised walkway (cess, x 1.75..3.0, top 0.7 m) on the right, the radio feeder along the
  crown, a dead caged lamp every 8 m.
  `tunnel_straight` (8 m, LINE 00 stencil), `tunnel_curve_l` / `tunnel_curve_r` (15 deg over 8 m, radius ~30.6 m),
  `tunnel_refuge` (niche in the right wall at walkway level, violet-painted frame, REFUGE sign, steel steps up from the track:
  collision is a ramp, the walker has no step-up; `marker_refuge` = where the emergency pylon stands, facing the track),
  `tunnel_vent` (a duct-sized opening high in the right wall, duct floor 1.4 m over the walkway; `marker_vent` = where a
  `duct_mouth` goes, front into the tunnel: VentDuct's CLIMB OUT lowers the walker onto the walkway), `tunnel_bulkhead` (2 m
  portal between sections: narrowed opening, walkway still passes, hazard jambs, LINE 00 // SECTION 04 on both faces),
  `tunnel_collapse` (dead end: the crown down 3 m in, rubble slope to the roof, rock through the hole, rails torn up, the main
  snapped and bleeding amber, lit by its pool; no `marker_next`), `emergency_pylon` (2.25 m post: violet call cabinet with
  handset and EMERGENCY plate, glowing collar, caged beacon, feeder tap; fits the niche), `rail_buffer` (buffer stop, origin on
  the track centre at invert level, buffers toward +Z: unrotated in a piece it faces the way the line came in).
- **Chaining**: every tunnel piece's origin is its entry face (tunnel centre, invert level) and it runs along its local -Z
  (Blender +Y); `marker_next` sits on its exit face with the exit heading. `TunnelLine` (`scripts/world/tunnel/tunnel_line.gd`)
  lays a list of names end to end: `TunnelLine.lay(parent, start, [&"tunnel_straight", &"tunnel_curve_r", ...])`, then
  `exit(pieces)` (where it ends), `batch(root, pieces)` (KitBatch: one draw per mesh; batch **before** adding pylons),
  `pylons(pieces)` (an EmergencyPylon in every refuge). A new piece: build it along a `TunnelPath` in `tunnel_lib` (every
  feature is a 2D cross-section swept along the path, so it works on straights and curves alike) and end it with
  `next_marker`.
- **EmergencyPylon** (`scripts/world/tunnel/emergency_pylon.gd`): spawns the post, owns its glow material and a violet
  shadowed omni (hung 0.32 m in front of the lens: inside the glass it shut itself in), FSM `DARK` / `STANDBY` (a slow breath,
  each post out of step) / `ALERT` (strobing, 18 m); `set_state()` from gameplay. No rules of its own yet.
- **Textures**: `python tools/blender/tunnel_textures.py` -> `tex/tun_stencil_line.png`, `tun_refuge.png`,
  `tun_plate_emergency.png`, `tun_section.png` (functional signage only); then rebuild the pieces:
  `tools\blender.ps1 tools/blender/props/o73_kit.py tunnel_straight tunnel_curve_l tunnel_curve_r tunnel_refuge tunnel_vent
  tunnel_bulkhead tunnel_collapse emergency_pylon rail_buffer` (~20 s), `godot --headless --path . --import`.
- **Look**: `scenes/dev/tunnel_showcase.tscn` lays every piece in one run (pylons in the refuges, a duct mouth and its grille
  in the vent piece, a buffer before the cave-in): `tools\capture.ps1 -Scene res://scenes/dev/tunnel_showcase.tscn -Cam
  -0.6,1.7,-4 -Look 0.4,1.4,-20 -NoUi`; `$env:TUNNEL_LIT=1` swaps the dark for a flat work light to judge geometry.
  The whole 14-piece run costs ~1.9 ms GPU at 1080p, 146 draw calls. Test: `check_tunnel_kit.gd` (chaining, curve headings,
  floor under track and walkway, walls and crown, refuge steps and niche, the cave-in blocks, pylons and their states, the
  duct's climb-out lands on the walkway).
- **Records vault** (`tunnel_vault`, `tools/blender/kit/vault.py` + `vault_door.py`, layout `vault_layout.py`, sizes
  `VAULT_*` / `DOOR_*` in `kit_dims.py`): where the company kept its records. Ends a line like `tunnel_collapse` (no
  `marker_next`). 10 m of approach (track to a `rail_buffer`, a loading dock at walkway height across the bore with steel
  steps up from the track, the amber main diving into the floor, an emergency pylon at the walkway's end:
  `marker_pylon_0`), then a 1.2 m wall with a round doorway (the floor runs through its foot on a steel sill) and the door
  swung out onto the dock (stepped disc, 14 locking bolts and their bolt-work, wheel, dial; node `door` on the pintle,
  static for now), then the hall: 18 x 22 m, 5.6 m high, five bays of deep beams, columns either side of a 4 m aisle.
  **Left, paper files**: 13 `archive_stack` carriages packed on floor rails (one aisle open, one ajar; row numbers on
  the floor), `card_catalog` and `file_cabinet`s by the door. **Right, drawings**: `plan_chest`s under the pinned
  drawings, two `drafting_table`s, layout tables with drawings spread on them, `tube_rack`s, more cabinets, a crack in
  the wall bleeding amber into a pool. **Far end, digital**: the tape cage (wire-mesh wall on steel posts, lower
  ceiling, the gate left open): tape cabinets, server racks, cooling, and the operator console, a usable terminal
  (`__drive_vault_records`, `content/terminals/vault_records.tres`, placeholder: README + DRAWINGS / FILES / TAPES).
  Stencils LINE 00 // RECORDS (both faces of the wall), FILES, DRAWINGS, TAPES. Lamps still burn: `marker_light_vault*`
  (`kit_lights.gd` kinds `vault`, `vaultshadow` (2, shadowed), `vaultfail` (flickers)); one hangs dead.
  Move furniture = edit a `KIT` row in `vault_layout.py` and rebuild the piece.
- **Archive furniture** (`O73Kit.ARCHIVE`, indoor only; `archive.py`, `drawings.py`, sizes `STACK_*` / `FILE_*` /
  `PLAN_*` / `TUBE_*` / `CAT_*`): `archive_stack` (mobile shelving carriage 1 x 5.6 x 2.4 m: five bays a side of box rows
  (textured strips) and loose boxes, end panel with crank wheel and index card at the front; origin mid-carriage, long
  axis along its local Z), `file_cabinet` / `file_cabinet_open`, `card_catalog`, `plan_chest` / `plan_chest_open`,
  `drafting_table`, `tube_rack`. `ArchiveKit` (in `archive.py`) adds paper, drawer-face and blueprint materials.
  **Textures**: `python tools/blender/archive_textures.py` (box rows, drawer faces, index cards, the stencils, floor row
  numbers, wire mesh, the dial, and four blueprints drawn from `kit_dims`: the tunnel's section, an interchange hall, Missile
  Silo 00's section, the vault door; functional labels only), then rebuild: `toolslender.ps1 tools/blender/props/o73_kit.py
  tunnel_vault archive_stack file_cabinet file_cabinet_open card_catalog plan_chest plan_chest_open drafting_table
  tube_rack`, `godot --headless --path . --import`.
- **Furnishing along a line**: `TunnelLine.lay` runs `BunkerKit.furnish` on every piece it lays (any piece with
  `marker_kit_*` markers gets its furniture), `TunnelLine.batch` then batches the furniture with the run, and
  `TunnelLine.pylons` puts an EmergencyPylon on every `marker_pylon*` as well as in refuges. `TunnelRuns.vault()` = a PLAIN
  block, the station, then the vault; `TunnelNetwork.vault_mouth` (default hall (4, 4) north: the far corner, off the grid, never
  linked) is where it goes (`network.vault`; its hall is added to the network's bounds). Dev menu GO TO "Tunnels: records
  vault". Look: `tunnel_showcase.tscn` lays it off the hall's east mouth and prints its places (`VAULT dock ...`), e.g.
  `-Cam 32,2.3,12 -Look 50,1.6,12` (in the door, down the aisle). ~1.4 ms GPU, ~590 draws from inside. Test:
  `check_tunnel_vault.gd` (laid and furnished, the console's drive, floor and a clear way from the walkway through the door
  to the console and into the stacks' open aisle, walls and ceiling, lamps, the dock pylon, network bounds).
- **Station** (`tunnel_station`, `tools/blender/kit/station.py`, sizes `STA_*` in `kit_dims.py`, textures
  `python tools/blender/station_textures.py` -> `tex/tun_station_*.png`, `tun_indicator_a/b.png`): a platform on the line,
  laid just before the records vault so the train had somewhere to stop (its platform runs on into the vault's approach:
  the buffer stop, the dock, the door). Chains like `tunnel_straight` (24 m, `marker_next`): 1.5 m of bore, a headwall
  with the bore's portal through it, the cavern, a headwall, bore. The cavern keeps the bore's left wall (track, amber
  conductor, drain and main run straight through) and widens right to `STA_XR` under an elliptic vault (crown 6.2 m, a rib
  every 3 m); the side platform at `WALK_Z` fills it from the edge (`STA_EDGE`: a steel nosing over a 0.3 m recess, a
  hazard line) to the back wall, so the walkway runs straight onto it. Fittings built in: RECORDS name boards on the back
  wall and across the track (between the ribs, `BAYS`), a hanging indicator (live screen `kit_scr_indicator`, `kit_prop.gd`
  flips LINE 00 / NO SERVICE; `marker_light_indicator`, kind `indicator` in `kit_lights.gd`: the platform's only lamp), a
  stopped clock, the way sign (straight on: RECORDS), the driver's STOP board, a dead three-lens signal where the line
  leaves, two rows of dead lamp fittings, an amber seep in the back wall. Kit markers: `platform_bench` (`rail_props.py`:
  steel bench, front -Y) under each board, a `terminal_wall`; `marker_pylon_0` = an emergency pylon on the platform.
  Rebuild: `toolslender.ps1 tools/blender/props/o73_kit.py tunnel_station platform_bench`. `TunnelNetwork.station` holds
  it; dev menu GO TO "Tunnels: records station". Look: `tunnel_showcase.tscn` lays it on the vault line and prints its
  places (`STATION platform ...`), e.g. `-Cam 22.5,2.2,17.5 -Look 43,1.8,13` (down the platform). No measurable frame cost
  (silo depths smoke 14.0 ms either way). Test: `check_tunnel_station.gd` (laid on the vault run and the vault joins it,
  floor and a clear way from the walkway down the platform to the vault's dock, the edge drops to the track over a recess,
  the vault closes it in, benches / terminal / pylon / indicator, network bounds).
- **Music** (`python tools/audio/tunnel_theme.py`, numpy + soundfile, ~80 s -> `audio/tunnel/tunnel_theme.ogg`, `_deep`,
  `_strain`, 208 s each, same layering and `MusicZone` conventions as the silo's; voices in `tools/audio/tunnel_voices.py`).
  Slow and cold, no drums, no resolution. A four-note motif on bowed glass (B E D, back to B) over the amber rail's E1 hum
  and a thin open pad turning E, C, A, B, E; far-off rail ticks pitched into the key. Four 24 s statements per loop: the
  second falls to G, the third lifts (D G F# E), the fourth stops short on D and never comes home. Layers: **base**
  (always), **deep** (a low bowed voice answers the motif two octaves down, in the silence after it: further down the line),
  **strain** (a wrong copy of the motif a semitone up and a beat late, plus a low draught: near the cave-in or a pylon ALERT).
  Intro 16 s (the hum rises, one lone B), loop 96 s written twice; `.import` loops from `loop_offset=112`.
  **Wired**: `TunnelMusic` (`scripts/world/tunnel/tunnel_music.gd`, owned by `TunnelNetwork`) plays it through a `MusicZone`
  while the walker is inside the network's bounds; deep comes in 60-220 m from the entry vent, strain 220-420 m. A
  placeholder rule until the route is planned. Test: `check_tunnel_music.gd`.

## HUD (barebones; art bible: diegetic first, amber on soot)
`FieldHud` (`scripts/ui/hud/field_hud.gd`, mounted by `SurvivalUiSystem`) is the whole HUD: a dust crosshair dot, the one
interaction prompt, the bottom-centre `DialogBox`, a quiet held-item tab, and `shaders/hud_stress.gdshader` (edges darken and
colour drains when hurt; no red flashes, no numbers). The legacy player HUD layer is hidden in walk mode; the old item dock and
Tab inventory are gone. UI is laid out in 640 x 360 units (`display/window/size`, canvas_items stretch), so size things for that.
- **Talk to the player**: `FieldHud.speak("The pump. I can hear the pump.")` (a thought, handwritten) or
  `FieldHud.speak(text, "R. Kovac  //  radio, day 112")` (a voice: speaker tag + typewriter). Lines queue, type in, hold, fade.
- **Prompts, one language**: every interactable calls `InteractPrompt.offer(self, TITLE, SUB, strength)` each frame it is in reach
  (raycast ones return `get_interaction_prompt()` / `get_interaction_detail()` and the player offers for them). TITLE = VERB +
  OBJECT (`TAKE FIELD DOSIMETER`, `RE-ALIGN RELAY 03`, `READ NOTE`); SUB = IDENTITY // STATE (`LOOSE PAGE  //  HANDWRITTEN`),
  optional. Amber pools are the exception: just `DRINK`, no sub line.
  The key only appears in the key cap. Build per-frame strings once (no allocation per frame).

## Relay Hub 00 (the central routing station)
The hub every amber well feeds; the player arrives on relay route 73 and programs the other routes here. Same art rules as
Outpost 73 (obsidian, amber, 200 years unattended), bigger: 14 x 10.8 m shell, 11.2 x 8 m hall, clerestory lantern with the hub's
own relay mast (the tallest landmark, beacon = `marker_light_roof`).
- **Build**: `python tools/blender/hub_textures.py` (stencil, route plates, network map, notes, floor chevrons -> `tex/hub_*.png`),
  then `tools\blender.ps1 tools/blender/props/relay_hub.py` -> `models/generated/relay_hub.glb` (textures embedded). Shell +
  door in `relay_hub.py`, hall in `hub_interior.py` (`KIT` rows place the furniture), outside in `hub_exterior.py` (`OUTDOOR`).
- **Routes** (`HubRoutes`, key -> corner): `73` front-left (arrival), `02` rear-left, `03` rear-right, `00` silo front-right.
  Per route the model carries `valve_<key>` (handwheel node, turns about its local Z), `hub_flow_<key>` (sight glasses inside and
  at the corner main), `hub_glow_lamp_<key>`, `marker_route_light_<key>` and `marker_route_<key>` (where its corner relay mast, a
  `NuclearPylon`, stands). Dry routes are dark; `open()` spins the valve, amber comes through, the mast comes online in the
  route colour (`NuclearPylon.force_online`).
- **Router console** = the hub's route terminal (`HubConsole`, FSM IDLE / WRITING / ROUTING). Its four route keys
  (`HubRouterKeys`: a hit area on each key cap; look at a key, [E]) each resolve to one Mode: ROUTE (the route exists:
  `PROGRAM ROUTE TO OUTPOST 02`, ~1.2 s, `route_selected(route)` -> the dosimeter follows it out), WRITE (the next route at stage
  0 / 2 / 4: `PROGRAM RELAY ROUTE 02`, types for ~3.6 s, then `hub_interacted(stage)` and `DeadForestEvent` lays the chain out of
  its corner mast (`route_mast` / `route_out`), raises the building and puts the dosimeter on it), LOCKED (`NO CARRIER // KEY 02
  MISSING`, `SILO PATH LOCKED // KEYS MISSING`: a clunk, the reason on the log).
  Under the routing table the screen shows the silo gate: `ALL SECURITY KEYS REQUIRED FOR SILO PATH ACCESS` with a chip per
  key (blue = key 02, green = key 03) blinking `MISSING` until held (`HubConsoleView.set_security_key`, driven from the stage
  in `RelayHub.set_stage`: key 02 at stage >= 2, key 03 at stage >= 4).
- **Runtime**: `scripts/hub/relay_hub.gd` (wiring + progress API), `hub_routes.gd`, `hub_console.gd`, `hub_console_view.gd`,
  `hub_router_keys.gd`, `hub_ambience.gd` (lights, beacon, map flip). Shared with Outpost 73: `BunkerDoor.mount`, `Fx.add_lights(model, table)`,
  `bunker_kit.gd furnish`.
- **Look at it**: `tools\capture.ps1 -Scene res://scenes/levels/dead_forest.tscn -Exec res://tools/exec/spawn_relay_hub.gd
  -Cam 0,1.7,-37.8 -Look 0,1.5,-43.5 -Wait 4 -NoUi` (set `$env:HUB_STAGE=5` for every route online). In game: F6 teleports there.
  Key hit test: `-Exec res://tools/exec/check_router_keys.gd` (aim rays at each key from ahead and both sides: `CHECK` lines).

## Relay network (standard paths between buildings)
Every path is a relay route between Relay Hub 00 and one outer building (`HubRoutes.Route`: 73 = Outpost 73, 02, 03, 00 = the
silo), and every building has one place to program it. The paths work like a working network: once laid they stay standing and
can be walked either way at any time; progress only decides which routes exist.
- **Route terminal** (`RouteTerminal`, `scripts/relay/route_terminal.gd` + `route_terminal_view.gd`): the `terminal_wall` kit
  piece of each outer building (Outpost 73 / 02 / 03: front wall right of the door; silo: launch control at level 09) becomes
  `PROGRAM ROUTE TO CENTRAL HUB` ([E] within 1.9 m on the same floor, ~1.4 s write, keypad clicks). Its screen (PixelScreen over
  `kit_scr_seal`) shows site, route, destination and NO RECEIVER / STANDBY / WRITING / ROUTE SET. Mount on any building:
  `RouteTerminal.mount(host, model, route, locked)` after `BunkerKit.furnish`; connect `programmed(route)`. Outpost 73's is locked
  until its dosimeter is taken; the first write there lays route 73 and raises the hub.
- **At the hub** the router keys program any laid route outward (see Relay Hub 00).
- **Network** (`RelayNet`, `scripts/relay/relay_net.gd`): one chain per route, stored outer -> hub; `track(route, to_hub,
  hub_mast)` gives the dosimeter its masts (toward the hub ending at the route's corner mast). `RelayChain`
  (`relay_chain.gd`) lays a chain. `DeadForestEvent._follow(route, to_hub)` sets the dosimeter and marks ROUTE SET on every
  terminal. Taking an outpost key only advances the hub; the way back is programmed at that outpost's terminal.
- **Dosimeter**: rests silent until a route is programmed; switching routes releases the old target mast.
- **Test**: `-Exec res://tools/exec/check_routes.gd` plays the whole network (lock, first route, hub keys, writes, refusals,
  every terminal home, chains persisting) and prints `CHECK` lines. Screens: `-Exec res://tools/exec/spawn_outpost73.gd -Cam
  1.5,1.8,-39.1 -Look 1.74,1.85,-38.15 -Wait 4 -NoUi` (`$env:ROUTE_TERMINAL=ready|set`).

## Terminals (usable computers with folders and files)
Any kit piece with a screen surface (`kit_scr_*`) can be a computer the walker uses to read files. Scripts in
`scripts/terminal/`; content in `content/terminals/`.
- **Use**: aim at the screen within 2 m, [E] USE TERMINAL. The view eases in until the screen fills it (`PlayerFocus`,
  `scripts/world/player_focus.gd`, reusable for any close-up: freezes the walker, hides the crosshair and the held item,
  eases the camera under Head and back). The OS cursor hides; the mouse is read as a ray onto the 3D screen and drawn as a
  pixel pointer on it. Click (or arrows + Enter) opens a folder or file, Backspace / `< BACK` / `[<] ..` go back, the wheel
  or arrows scroll a file, E / Esc log off and the view eases back out. F-keys still reach the dev tools.
- **Put one on a piece** (three ways): a kit marker flag `__drive_<id>` (`marker_kit_terminal_server__srv2__drive_silo_data09`;
  `BunkerKit.furnish` mounts it, so any building generator's `KIT` rows can place terminals); from code
  `TerminalStation.mount(piece, TerminalStation.load_drive("<id>")[, "kit_scr_<name>"])`; or in the editor, a
  `TerminalStation` node as a child of the piece with `drive` set. The screen is the piece's first `kit_scr_*` surface
  unless `screen_material` names one. Tested on `terminal_server`; `terminal_crt`, `terminal_console`, `terminal_router`
  have screens too (not `terminal_wall`: `RouteTerminal` owns those).
- **Content** = a `TerminalDrive` resource per terminal, `content/terminals/<id>.tres`: `title` (header), `user`, `name`
  (the drive label in the path line) and `entries`, a list of `TerminalFolder` (`name`, `meta`, its own `entries`) and
  `TerminalFile` (`name`, `meta`, `body`: BBCode, scrolls). `meta` is the right-hand column (a date, a size); a folder with
  no meta shows its item count. Edit it in the Godot inspector (open the .tres, expand Entries, add New TerminalFile /
  New TerminalFolder) or as text (Godot writes it readably: one `[sub_resource]` per entry, bodies as multi-line strings).
  `silo_data09.tres` (the data room console) is a placeholder: README, an example folder with a nested one and a long page,
  an empty folder.
- **Story hooks**: the drive emits `file_opened(path, first_time)` (path `LABEL:/FOLDER/FILE.TXT`); resources are cached,
  so `TerminalStation.load_drive("silo_data09").file_opened.connect(...)` from anywhere hears every read. The station emits
  `used(player)` / `left(player)`. Read marks (the `*` on unread files) last for the session; nothing is saved yet.
- **Pieces**: `TerminalStation` (Area3D on the piece: FSM IDLE / ZOOM_IN / USING / ZOOM_OUT, aim target, sounds),
  `TerminalInput` (the input while logged on: mouse ray -> screen pixel -> `SubViewport.push_input`), `ScreenSurface`
  (a screen quad's world frame and texture UV under any point, read from the mesh; reusable for any touchable screen),
  `TerminalDesktop` (the screen UI in a `PixelScreen`, 288 px high, width from the screen's aspect: LISTING / READING
  views), `TerminalListing`, `TerminalReader`, `TerminalTheme` (amber VT323, inverse-video rows). The screen renders live
  only while it is on camera. Not built yet: passwords / locked folders, images, audio logs, saving read marks.
- **Test**: `-Exec res://tools/exec/check_terminal.gd` (in `tools\test.ps1`): aims at the data room console, logs on,
  clicks a folder and a file with real mouse events on the 3D screen, Backspace, E, and checks control comes back.
  `$env:TERMINAL_SHOT=1` (a file) or `list` (a folder) leaves it open for the capture (shot through the walker's eyes:
  a hook can set `tree.set_meta("capture_camera", camera)`).

## Missile Silo 00 (the end of relay route 00)
Something impossibly large launched from it. A 112 m bore (R = 56) whose floor nobody sees, six cap petals (46 m slabs)
blown open round the rim (one tore off and hangs head-down in the bore), soot up the walls, the forest flattened outward.
Same art rules as Outpost 73 (obsidian, amber only, 200 years unattended). Concept: desktop `Reference Art` silo sheet.
- **Build**: `python tools/blender/silo_textures.py` (petal stencil, level 09 marker, gate warning, soot -> `tex/silo_*.png`)
  and `python tools/blender/server_textures.py` (the data room stencil), then `tools\blender.ps1 tools/blender/props/missile_silo.py` (~15 s) -> `models/generated/missile_silo.glb`.
  Parts: `silo_rim.py` (apron, lip, hinge plinths, petals, rams), `silo_bore.py` (lining, rails, girders, amber mains,
  service arms, fallen petal), `silo_tower.py` (stair tower frame + walkway kit markers, level 09 deck, work floods, stair-head
  kit), `silo_room.py` (launch control cut into the lining, desk, kit furniture, kit blast door), `silo_hall.py` (tunnel,
  generator hall shell), `silo_lift.py` (freight lift: shaft, frame, cage, gates), `silo_generator.py` (the generators,
  the amber conduit, the floor channel). Front (stair head) = Blender -Y = Godot +Z.
- **Stair tower = walkway kit** on the 2 m grid: lanes A (y -53, by the wall) and B (y -51), landings at x 0 / -10, flights
  8 m between them, one `catwalk_2m` bridging the 2 m from the apron edge (r 56) to the top landing (the lip gap, `GAP`, is
  cut to its width). Level 09's landing drops its end rail (`__no_rail_front`) onto a filler plate to the curved deck;
  `gate_barred` closes broken flight 10. Silo-only parts stay in the model: frame, ties, hoist, lamps (on the void-side end
  columns), deck, filler, invisible cage. `MissileSilo` batches the pieces (`KitBatch`: rim band + level 09 band cast
  shadows, the shaft between does not), fogs them (`AbyssFog.apply_many`) and runs the launch control `door_blast`
  (`BunkerDoor`, opens within `DOOR_REACH`).
- **Walk**: apron -> bridge -> 9 switchback flights (4 m each) -> level 09 (-36 m) -> deck -> blast door -> launch control.
  Flight 10 is broken and gated. Collision: the kit pieces' own (ramps, rails, decks) + deck, filler and invisible cage
  walls (`silo-colonly`).
- **Data room** (`silo_servers.py`, built right after `silo_room`, same room frame and `RB` / `W` / `FACE` helpers): a
  doorway in launch control's left wall (`silo_room.SERVER_DOOR`, v 6.6..8.6, 2.6 m; `side_wall()` / `door_frame()` build
  both side-wall doorways, the frame lines the whole opening) opens on a 10.4 x 5.2 m room, 3.2 m high, dug on along -u.
  Two rows of server kit (`ROW_A` / `ROW_C`, backs to the side walls; one rack missing, its cables hanging out of the
  tray) face an aisle on the doorway's centre line; `cable_tray` runs over both rows; at the far end the operator console
  `terminal_server` + chair under the `DATA 09` stencil, a `crac_unit` and a tape `terminal_mainframe` in the corners.
  Floor cables run from launch control's mainframes through the door. Layout = the `KIT` rows (markers
  `marker_kit_<prop>__srv<n>`). Lamps `marker_light_srv_0` (shadowed) / `_1` (flickers) in `SiloAmbience.LIGHTS`.
  Runtime `SiloServers.dress` (`scripts/silo/silo_servers.gd`, from `MissileSilo._ready`): batches the racks and trays
  (`KitBatch`) and puts the room's kit under the bore's AbyssFog (`AbyssFog.apply_many(..., keep_live = true)` skips
  surfaces with a per-instance override, i.e. KitProp's screens and blinking lamps, which get `disable_fog` instead): the
  room is 20 m deep and the forest's pale depth fog starts at 8 m. The console is a usable terminal (marker flag
  `__drive_silo_data09`, see "Terminals" below; the `KIT` row's optional 5th field carries marker flags).
  Test: `check_silo_servers.gd` (floor and a clear walk from launch control to the console, walls, 33 pieces, batches,
  lamps).
- **Generator hall** (what the amber comes down for), 84 m under level 09 (`silo_hall.LIFT_DROP`, floor `FL` -120 m):
  a doorway in launch control's right wall (`silo_room.HALL_DOOR`) -> a short tunnel -> the **freight lift**
  (`silo_lift.py`, end-wall frame `silo_hall.shaft_xy`: x along the ray at `A0`, y toward the room). The cage drops ~24 s
  through a closed rock shaft (a lamp every 12 m), out through the hall ceiling and down an open steel frame, so the
  last 34 m show the hall; it opens on the hall side. Runtime `SiloLift` (`scripts/silo/silo_lift.gd`, FSM TOP / DOWN /
  BOTTOM / UP): the cage is an AnimatableBody3D the player rides; four `LiftGate`s (`scripts/world/lift_gate.gd`,
  reusable: a barred gate that rises to open, collision until it is up) close before every trip, and the landing gate
  of the far end stays shut so the empty shaft is never open. `SiloLiftControls`: [E] in the cage (LOWER / RAISE
  LIFT), at the call panels (tunnel wall, frame column) it comes to you. `PIT_DEPTH` 130 keeps the fall reset below.
- **The cage interior and gates** (`silo_lift_cab.py` and `silo_lift_gate.py`, split out of `silo_lift.py`; nodes `silo_lift_cab`
  + `silo_lift_cab_art`, both reparented under the cage body by `SiloLift`; the gates are the `silo_lift_gate_*` nodes): built
  like the hall it rides into, from chamfered box-section steel (`box(..., chamfer=)`), not thin bars. Cage: pilasters on the
  wall joints, a cornice, a lip over the hazard band, a bump rail on brackets, two beams across the roof, the caged lamp
  (glowing lens + wire guard), conduit from the lamp junction down to the control panel (housing with a hood, two glowing
  buttons, a stop button), hatch hinges and handle, tie-down plates, and the channels each cage gate rises in. Gates
  (`silo_lift_gate.gate`, all four): box-section stiles, a bolted header, a hazard-striped kick plate between a sill and a cap,
  mid and upper rails, square bars, one diagonal brace per face, a lock box with a status lamp on each face, a pull handle on
  the cage side of the cage gates. The hall landing gate's jambs and head are chamfered too.
  The art is opaque quads (`lay_art`) with their own 0..1 UVs, laid 6-14 mm proud of the surfaces (`missile_silo.py` skips
  `world_uv` for `silo_lift_cab_art`): obsidian steel with worn amber paint left mid-panel, hazard kick bands, bolt rows,
  diamond tread floor, ceiling with a scorched lamp ring and hatch, a capacity plate, the panel face. Drawn dark and soft
  (anti-aliased, no single bright pixels) so it sits in the silo: `python tools/blender/lift_textures.py` (walls, floor,
  ceiling 128 px per metre; `lift_hazard.png`, a tileable 1 m stripe used as the world-projected material `silo_lift_hazard`,
  `M_HAZ_T`, in `TILES`) and `python tools/blender/lift_fixtures.py` (panel face, plate, 256 px per metre; layout
  constants shared with `silo_lift_cab.py`: keep `BUTTONS` / `STOP` equal), then rebuild the silo and
  `godot --headless --path . --import`. Image directions are in `lay_art`'s docstring. Look (cage parked at level 09, `-Fov 80`):
  the panel wall from inside `-Cam -27.673,-34.35,-343.377 -Look -28.275,-34.7,-340.85`, the `09` wall and hall gate `-Cam
  -27.956,-34.35,-341.309 -Look -27.9,-34.95,-344.085`; the hall landing gate from the floor (`$env:SILO_HALL=1;
  $env:SILO_LIFT=1`, `-Fov 75`) `-Cam -34.318,-118.25,-343.988 -Look -31.591,-118.95,-344.064`.
- **The lift crash** (night 4's ending): `SiloLift.doom()` (called by `ForestNightDirector` for every lift that enters the
  tree on a CRASH night) makes the next trip down fail `STALL_AT` (4 s, ~6 m) in; the lift goes to state CRASH (no
  prompts, no [E] after) and hands the cage to `SiloLiftCrash` (`scripts/silo/silo_lift_crash.gd`), which drives its
  height on a fixed 7.1 s timeline: SEIZE (clank, 0.35 m drop and bounce, the motor winds down, the lamp stutters), JOLT
  (1.3 s), FALL (2.4 s, the cable snaps: free fall), BRAKE (3.6 s, the safety brakes bite, shrieking stop), HOLD (4.05 s),
  SLIP (4.9 s, the brakes let go: the rest of the shaft in 2.2 s), WRECK (7.1 s, the hall floor: `phase_changed(WRECK)`,
  the director's hard cut to black). Sparks (`Sparks`, below) spray off the brake shoes on SEIZE / FALL / BRAKE / SLIP;
  the lamp strobes while falling. The sound is one 2D file on the same timeline, `audio/silo/lift_crash.wav`
  (`python tools/audio/lift_crash.py`, numpy: its JOLT..WRECK constants must equal `SiloLiftCrash.AT`), played through
  `SoundManager` so the impact rings on into the black. `LiftCrashView` (`scripts/world/lift_crash_view.gd`) is the
  walker's side: frozen from the seize (mouse look stays) and carried by the crash's `height` (reading the
  AnimatableBody back lags a physics tick), trauma shake on the camera's h/v offset + roll, a dip on each jolt, FOV
  widening through the falls. Test: `-Exec res://tools/exec/check_lift_crash.gd` (phases in order, carried to the hall
  floor inside the cage, camera shook, director dooms lifts built before and after it, wakes on WRECK).
- **Sparks** (`scripts/world/sparks.gd`, reusable): `Sparks.make(parent, at)` -> a world-space CPUParticles3D of additive
  orange streaks under gravity (one shared mesh + material); toggle `emitting`. A moving emitter leaves them behind.
  The hall is a curved brutalist nave round the bore, r 60..77 (inside the terrain hole, so `PIT_DEPTH` 70 covers it),
  -114.5 to -170 deg, 34 m high, portal frames (pilasters + ceiling beam + haunches) between the machines. Three
  generators (`silo_generator.py`, 23 m): a stepped octagonal plinth, a lower body with glowing glyph slits, a waist of
  amber behind glass (hollow, so the shadowed core light shines out between the fins and throws their shadows round the
  walls), a crown flaring to an open amber pool, eight buttress fins rising past it as blades, power ducts clamped to both
  walls. A conduit hung from the beams pours a stream into every crown; spent amber runs down a floor channel to a drain.
  Reusable bits: `lathe()` (octagonal / n-sided solid of revolution from a (height, radius) profile, rings too), `fin()`
  (radial buttress lofted through stations), `silo_tower.flood()` (a work flood + its `<prefix><name>` / `_target`
  markers; `SiloAmbience.add_spots(model, prefix, colour, energy, angle)` lights any prefix).
  Nodes: `silo_hall` (+ `silo_hall_decals`) and `silo_gen` (not AO-baked: the fins stand on the body's corners and the bake
  blacked it out; four amber uplights on each plinth step shape it instead), `silo_gen_liquid` (world UVs, material
  `silo_gen_amber`). Runtime: `SiloGenerators` (`scripts/silo/silo_generators.gd`): lights, sound, amber flow, glyph throb,
  and `fog()`: the hall and its share of the walkway kit get their own AbyssFog look (`HALL_LOOK`: fully deep, black fog,
  no sky ambient; with the bore's look the far hall read pale grey). **SkyZone** (`scripts/world/sky_zone.gd`, reusable
  for any underground place): hides the level's DirectionalLight3Ds while `update(inside)` is true (the forest moon only
  shadows 45 m out and leaked into the hall); `SiloGenerators.in_hall(local)` is the silo's test.
  Look: `$env:SILO_HALL=1` with `spawn_silo.gd` stands the player in the hall (zone on), `$env:SILO_LIFT=0.7` parks the
  cage 70 % down (e.g. `-Cam -29.45,-93.05,-343.09 -Look -53.84,-113.95,-354.2 -Fov 80`: the view from the cage as it
  comes through the ceiling; `-Cam -24.9,-34.25,-341.02 -Look -29.27,-34.75,-343.01`: the cage from the tunnel).
  `check_silo.gd` walks to the cage, rides it down with the real player (`Engine.time_scale` 6; the hook holds the shot
  with `tree.set_meta("capture_hold", true)`, see `tools/capture.gd`), walks the hall, calls it back and checks both
  landing gates block the empty shaft.
- **Generator sound** (`SiloGeneratorSound`, `scripts/silo/silo_generator_sound.gd`; `python tools/audio/silo_generator.py`,
  numpy, ~3 s -> `audio/silo/gen_*.wav`, mono): per machine a drone loop (sub beating against its twin, the rotor's chug,
  a growl of harmonics that carries on small speakers, the windings' buzz, a turbine whine) that breathes with the
  machine's throb (level and pitch follow `THROB_RATE` / `CORE_SPREAD`), the amber pouring into its crown (loop, at the pool
  marker), and at the bottom of every breath a **pulse**: a sucked-in pre-swell, a falling sub thump with a driven punch, the
  housing ringing, an arc snapping off, the hall's tail, limited so its body is as loud as its sub. The three machines are
  out of step, so the hall beats every ~1.6 s, and each glow swells after its thump. Arcs crack off a random machine every
  5-14 s. **The machines are the hall's music**: each also holds one bowed note (`gen_bow_e2` / `_b2` / `_g3`: three
  detuned players, vibrato, bow hiss, a woody body), silent at the bottom of its breath and swelling with its glow
  (`breath ^ BOW_CURVE`), heard within `BOW_REACH` (32 m). E, B, G is an E minor chord over the drones' E (41 Hz), in the
  silo theme's key (A minor); as the breaths roll round, so does the chord, loudest at whichever machine you stand by. Levels / reach are constants at the top of the script (the pulse carries 130 m, up into the tunnel and the pit).
  The loops are plain WAVs made to loop at load (`_looped`); the pulse player allows 2 voices so a tail outlasts the next beat.
  **Walls**: AudioStreamPlayer3D only fades with distance, so every machine player goes through one **MuffleBus**
  (`scripts/audio/muffle_bus.gd`, reusable: `MuffleBus.make(name)`, add it, `player.bus = name`, `set_open(0..1)`; eases at
  `RATE`, volume `CLOSED_DB` -> 0 and a low-pass `CLOSED_HZ` -> 20 kHz) that `SiloHallEar.openness(local, pit_door, sealed)`
  (`scripts/silo/silo_hall_ear.gd`) drives from where the walker stands: hall and lift shaft 1; the vent duct `VENT` (0.5);
  the pit behind its blast door `PIT_SHUT` (0.08, -37 dB, 260 Hz) up to `PIT_OPEN` (0.55) as the door slides open
  (`BunkerDoor.factor`); rock outside the hall's walls 0; the tunnels 0 (`TunnelNetwork.inside_changed` ->
  `SiloGenerators.set_sealed`, joined by `SiloTunnels`). Anywhere else (up the shaft, the forest) plain distance fall-off.
  Test: `check_silo_muffle.gd` reads the bus in the hall, the pit and the tunnels.
- **Below the hall** (`silo_pit.py`, `silo_vent.py`, runtime `SiloPit`, `scripts/silo/silo_pit.gd`):
  - **The bore floor** (`FLOOR` -136 m, `silo_pit.DEPTH` 16 m under the hall; from the rim AbyssFog keeps it black, so the
    reveal still reads bottomless). A kit `door_blast` in the hall's inner wall at `PIT_A` (-128 deg, between the lift and
    generator 0) -> a tunnel through wall, rock and lining -> a `catwalk_2m` bridge -> a switchback of walkway kit down
    the lining (four flights, landings at u 0 / 10 in the stair frame `pit_xy`: u along the lining, v = radius; laid out
    like the stair tower, with its own frame, ties and lamps) -> the floor: the launch table (a stepped flame deflector
    `DEFLECTOR`, walkable, amber seeping down six cracks into puddles; twelve hold-down clamps with their jaws sprung open,
    two torn off), the three mains ending `silo_bore.MAIN_LIFT` (6 m) over the floor and pouring into a glowing pool at the
    wall, the stair tower's lost flights and landings lying where they fell (`FALLEN`: kit pieces on fully rotated
    markers), rubble, soot. A tripod flood lights the deflector (`marker_spot_pit_floor`, SiloAmbience). The girder at -116 m
    skips the stair head (`silo_bore.PIT_ZONE`). Collision: the floor, a ring round the lining's foot, the deflector, the
    clamps. `MissileSilo` runs every kit blast door (launch control's and the pit's: `_doors`). Past ~45 m the level fog
    swallows it, so the floor shows itself as you walk out.
  - **The open vent**: `duct_mouth` in the hall's far end wall (`silo_hall.A1`, radius 73, 0.5 m up), the grille leaning
    beside it, a caged lamp over it; the run goes 4 m into the rock, turns outward (`duct_bend`, a faint amber spill there)
    and runs 4 m to a `duct_cap` (`marker_vent_end`): **the end, for now; the next place goes there** (replace the cap).
    Far-wall frame `far_xy`: x = radius, y = into the rock. `SiloPit.mount` puts a `VentDuct` on every `duct_mouth`; duct kit
    is batched and fogged with the hall's look (`SiloGenerators.in_vent`); the moon is hidden in the hall, the duct and the
    pit (`SiloPit.in_pit`).
  - **The wreck** (`silo_lift.py wreck()`, nodes `silo_lift_wreck` + `_decals`, hidden until `SiloLift.wreck()`): the snapped
    cable in coils on the cage roof and trailing down the shaft, a sheared brake shoe, knocked-out fence rails, ceiling
    chips, scorch.
- **Terrain seam / falls**: `DeadForestTerrain.add_hole(x, z, radius, sink, depth)`: terrain vertices inside the hole snap onto
  its circle and drop `sink` (the dirt tucks under the apron skirt: `HOLE_RADIUS` 78.4, `HOLE_SINK` 0.12), and `depth` lets
  the fall reset (`DeadForestManager.FALL_Y`, via `get_kill_y`) wait until 10 m below the hole's floor (`PIT_DEPTH` 146:
  the bore floor is at -136). The bore floor is walkable, so a jump in from the rim would land on it: **FallGuard**
  (`scripts/world/fall_guard.gd`, reusable) emits `hard_landing(speed)` for a landing faster than `LETHAL` (36 m/s, a ~21 m
  drop) and the forest resets that like a fall out of the world, inside a terrain hole only.
- **Runtime**: `MissileSilo` (`scripts/silo/missile_silo.gd`, API unchanged: `build_silo`, `check_interaction`,
  `silo_activated`; footprint constants `APPROACH`, `CLEAR_RADIUS`, `FLAT_*`, `HOLE_*`, `PIT_DEPTH` feed `DeadForestEvent`),
  `SiloAmbience` (marker lights, work floods = SpotLight3D per `marker_spot_<n>` aimed at `marker_spot_<n>_target`,
  beacons, alarms, liquid flow), `SiloConsole` + `SiloConsoleView` (READY / ENGAGING / DONE at `marker_launch`, live
  PixelScreen on `silo_scr_launch`), `SiloBlast` (rayed scorch decal, felled trees and stumps 84-132 m out).
- **Music** (`SiloMusic`, `scripts/silo/silo_music.gd`): inside `ENTER` (124 m, just inside the clearing) the silo's
  theme replaces the forest music; past `EXIT` (150 m) it fades out and hands back. Four synchronised stems, layered as
  the walker goes in: **base** (always), **deep** (with depth below the rim, full at level 09), **core** (from 22 m down
  to level 09 / launch control), **alarm** (once the override engages, and stays). `python tools/audio/silo_theme.py`
  (numpy + soundfile, a few minutes) -> `audio/silo/silo_theme.ogg`, `_deep`, `_core`, `_alarm` (277 s each): a 21 s
  intro (the discovery: Am F Dm E, quick overlapping swells) then a 128 s loop of 16 slots of 8 s (`SLOTS`), section A
  (Am F Dm E, Am high, Bb F E; pedal A; the layers beat every 4 s) and section B (Dm Bb Gm A, Dm high, Bb Fm E; pedal D;
  every 2 s), written twice. Every `.import` loops from `loop_offset=149` (the second loop), so the first visit hears the
  intro and the loop is seamless (the script prints each stem's seam error). All stems share one gain (full mix -1 dBFS;
  `LAYER_DB` sets each layer against the base). Voices: `swell_signal` in `tools/audio/silo_cue.py` (which also renders
  the unused one-shot candidates `audio/silo/discover_*.wav`), thump / rumble / strings / bell / rise in
  `tools/audio/silo_voices.py`. **MusicZone** (`scripts/world/music_zone.gd`, reusable for any place with its own
  music): `MusicZone.make(stream, db, enter, exit, [layer streams])`, add it as a child, call `update(distance)` each
  frame and `set_layer(i, 0..1)`; OUTSIDE / INSIDE with hysteresis; fades every AudioStreamPlayer in group `music` (the
  forest's MusicPlayer) out and back; layers ease at `LAYER_RATE`; later visits start at the loop point.
- **AbyssFog** (`scripts/world/abyss_fog.gd`, `shaders/abyss_fog*.gdshader`): rebuilds a node's materials so fog matches
  the level's depth fog at the rim and turns black with depth (ambient fades too; lamps still light; glow reaches
  further). Reusable for any pit or shaft: `AbyssFog.apply(node, rim_world_y, environment[, look])`; animate through
  `AbyssFog.find(node, material_name)`. The silo applies it to `silo_bore`, `silo_bore_decals`, `silo_liquid` and its
  walkway kit. `look` overrides shader params per pit: the silo (`MissileSilo.ABYSS_LOOK`) darkens by 45 m down but fogs
  only out to 450 m, so looking down the bore (its reveal) shows rings, rails, the tower and its lamps far into the dark.
- **ViewZone** (`scripts/world/view_zone.gd`, reusable for any place bigger than the fog-clipped view): the forest clips
  its camera at fog end x 1.5 (67.5 m), which cut the 220 m bore and showed the sky through it as a pale oval.
  `ViewZone.make(far, enter, exit)`, add as a child, call `update(distance)` each frame: inside, the current camera's far
  plane goes out to `far` (silo: 400 m inside 160 m); leaving restores it. Cheap: the streamed forest is only ~100 m wide.
- **Look / test**: `tools\capture.ps1 -Scene res://scenes/levels/dead_forest.tscn -Exec res://tools/exec/spawn_silo.gd
  -Cam 8,1.7,-306 -Look 0,16,-380 -Wait 4 -NoUi` (silo at (0, 0, -400); Blender (x, y, z) -> Godot (x, z, -400 - y);
  `SILO_NOFOG=1`, `SILO_ENGAGE=1`). `-Exec res://tools/exec/check_silo.gd` prints `CHECK` lines (floor under the whole
  walk, cages, gate, fall-reset depth, blast door open / close, console).
  Contact: `tools\blender.ps1 tools/blender/contact_check.py tools/blender/props/missile_silo.py`.
  In game: F9 teleports to the stair head.
- **Fast primitives**: `ps1_lib.fast_box` / `fast_cylinder` / `fast_tube` build with bmesh instead of `bpy.ops` (which
  slows down as a scene fills: the silo took 10 min with ops, 15 s without). Use them in any generator with thousands
  of parts; geometry is baked in world space, so pose through the arguments.
- **Perf**: `-Exec res://tools/exec/perf_probe.gd` prints a PERF line for the capture view (`PROBE_SPAWN=<hook>` spawns
  something first). Silo views add ~70 draw calls over the plain forest.

## Apartment 4C (the first level) and the apartment kit
The walker has severe OCD and cannot leave their one-bedroom flat; the game alternates between it and the dead forest. Unlike
the forest it is warm and pretty: golden-hour sun through venetian blinds, lamps on, clean. The OCD is in the set dressing, not
in hand-washing: everything squared and in even numbers, blue tape on the floor where furniture goes back, a tape line in
front of the door, label-maker labels on every drawer and jar, every stove knob taped at OFF, safety caps in every socket,
appliances unplugged with the cords coiled, identical shirts 10 cm apart, books sorted by colour, pencil tallies by the door and
by the bed, a front door with two deadbolts, a chain and two barrel bolts and tape over the peephole, amber pharmacy bottles in
rows with every label forward (seven in the medicine cabinet, two by the bed: SERTRALINE, FLUVOXAMINE, CLOMIPRAMINE), a
7-day organizer, one crooked frame.
- **Build**: `python tools/blender/apt_textures.py` (-> `tex/apt_*.png`), `tools\blender.ps1 tools/blender/props/apt_kit.py [name ...]`
  (65 pieces, ~30 s -> `models/generated/apt_kit/`), `tools\blender.ps1 tools/blender/props/apartment.py` (shell, ~6 s ->
  `models/generated/apartment.glb`), then `godot --headless --path . --import` (run it twice after a texture change: the first
  pass can stop at the textures). The .glb files embed their textures: rerun the kit build after changing a texture.
- **Kit** (`tools/blender/apt/`): `apt_lib.AptKit` subclasses the Outpost 73 `Kit` (same primitives, node contract, AO bake; cleaner AO,
  own output dir and import hook) and adds atlas quads (`QUAD_UV`, `LABEL`, `WRAP_UV`), `glass` / `noshadow` nodes, `USE` markers.
  **Shading**: apartment pieces are Gouraud-shaded where they curve and hard-edged where faces meet at more than
  `SMOOTH_ANGLE` (38 deg; `AptKit.shade`, called through the `Kit.shade` hook; the Outpost 73 kit stays flat). Round parts get
  at least 12 sides (cones 16). Turned and formed things use `apt_forms.py`: `lathe` (a profile round Z: kettle, plates,
  mugs, canisters, bowls, apples; per-band materials), `mesh` / `sheet` (raw faces with a material each; a thin slab), `holed_slab` (a worktop with an oval cut-out: the vanity
  basin), `book`.
  Soft goods use `apt_shapes.py`: `SOFT` (rounded box with an optional puff: cushions, pillows,
  mattress, a duvet that drapes over the sides, porcelain), `DISC` (round image face: the clock dial), `PLEATS` (curtains).
  Indoor practicals use a tight shadow bias (0.03) so thin shelves do not leak light.
  Modules: `fixtures` (doors, windows + blinds, radiator, switch, outlet, ceiling pieces), `living`, `library` (bookshelf,
  book_stack), `kitchen` (0.6 m module), `counter` (kettle, toaster, dish_rack, canisters, fruit_bowl), `entry` (shoes_pair,
  shoes_pair_b, shoe_tray), `bath`, `bedroom`, `smalls` (pill bottles, organizer, clock...), `mess_trash` / `mess_home` /
  `mess_heap` (the squalor, below). Shared sizes and atlas layouts: `apt_dims.py`. Godot catalog:
  `AptKit` (`scripts/apartment/apt_kit.gd`, groups + `spawn`). Showroom: `scenes/dev/apt_kit_showcase.tscn`.
- **Books** (`apt/apt_books.py`): 80 invented titles, mostly self-help (title, author, imprint, spine style, colours, size in m).
  `python tools/blender/apt_book_art.py` (also run by `apt_textures.py`) paints `tex/apt_books.png`: spines packed in rows,
  each with a swatch strip under it (cover colour, page edges), front covers for `COVERS` along the bottom
  (`apt_book_covers.py`). Needs the OFL Google Fonts in `tools/asset_src/fonts/` (not in git): Bebas Neue, Anton, Archivo
  Black, Abril Fatface, DM Serif Display (+ Italic), Alfa Slab One, Montserrat, Work Sans, Playfair Display, Lora (+ Italic),
  from `github.com/google/fonts/raw/main/ofl/<family>/`. `apt_forms.book(name, i, k.BOOKS, loc, rot)` maps one book (spine -Y,
  front cover +X; `rot=(0, 0, -90)` face-out, `(0, -90, 0)` lying cover up) into `k.panels`; `library.spine_row` /
  `flat_stack` place rows and piles. The atlas material is `apt_hi_books`: `apt_hi_*` materials get trilinear + anisotropic
  filtering (`apt_look.gd`) instead of the kit's nearest pixels, so text stays legible. Add a title = add a row to `B`, rerun
  the art and the kit.
- **Shoes** (`apt/entry.py`): a height field over a last outline (ball, waist, heel; toe spring; the toe rounds over in height
  too) built as rings out from the collar, so the opening has a clean edge; sole slab with a stripe band, tongue slab, bar
  laces. A new style is a parameter dict like `SNEAKER` / `DERBY`.
- **Placement**: origin at the base centre, front +Z (Blender -Y). Floor pieces standing at a wall have their back on z = 0.
  Hanging pieces (frames, clock, switch, outlet, medicine cabinet, towel rack, vanity light) have their origin at the centre of
  the back face: the marker's height is the hang height. Ceiling pieces hang down from their origin. Openings (doors, windows):
  z = 0 is the room-side wall face, the wall runs back to -Z. Tabletop heights: `AptKit.COUNTER_H`, `NIGHT_H`, ...
  Windows have an optional sill (`opt_sill`): place one over a worktop with `__no_sill` and keep its casing above any
  appliance backguard (the kitchen window sits at sill + 0.23 m for the stove).
- **Runtime node contract** (`AptProp` extends `KitProp`, attached by `tools/apt_kit_import.gd`; material look by name prefix in
  `apt_look.gd`: `apt_gloss_*`, `apt_mirror`, `apt_glass*`, else matte): `pivot_leaf` -> `AptDoor` (swinging leaf, [E] open/close,
  a `__open` marker suffix starts it open), `hand_h/m/s` -> `AptClock` (local time, 1 Hz tick), `marker_use_<id>` -> `AptUse`
  (prompt text/sound in `apt_uses.gd`; checks count and say so: `LOCKED  (CHECKED 3)`), `glass` / `noshadow` / `view*` never cast
  shadows, `marker_light_lamp|bulb|vanity|strip|fridge` = warm practicals in `kit_lights.gd` (lamp, bulb and vanity cast shadows,
  soft-edged: `light_size` = `BULB_SIZE`).
- **Shell** (`apt_shell.Shell`): a plan is data. `room()` rectangles get their own 7 cm skins (two rooms 14 cm apart share a partition),
  floor, ceiling, baseboard, crown; `opening()` boxes cut every skin and the envelope they cross (thresholds, arch linings);
  `split()` wainscot tile, `band()` splashback, `decal()`, `piece()` (kit marker + AO proxy; yaw and roll), `view()` window
  backdrops, `marker()`. Exports `marker_room_<name>` (scale = half extents; `AptMood` puts a box-projected ReflectionProbe in each).
  Another flat = another data file like `props/apartment.py`.
- **Level**: `scenes/levels/apartment.tscn` (main scene) -> `ApartmentLevel` (`scripts/apartment/apartment_level.gd`): shell,
  `BunkerKit.furnish(model, AptKit.DIR)`, `AptMood.apply` (moods = data: `golden_hour` first, `night` on later visits; SDFGI + SSIL +
  SSAO + volumetric fog + AgX; the sun has a 0.6 deg disc (PCSS: blind stripes soften away from the slats) and 4 shadow
  splits over 14 m, and `AptShadows` raises soft-shadow filtering to medium while the flat is loaded and restores the project
  value on exit: this is what removed the stair-stepped, pixelated sun and lamp shadows), wood footsteps (`Player.step_l/step_r`), fade in at `marker_spawn`. SLEEP on the bed ->
  `LevelFlow.go(&"forest")`. LEAVE on the front door leaf (`door_front`'s `marker_use_leave`, beside the CHECK LOCKS box on the
  lock stile; `FRONT DOOR // LOCKED  (TRIED n)`) never opens it: `ApartmentLevel` has the walker think "I shouldn't leave,
  something bad might happen" (`FieldHud.speak`), on every visit. **LevelFlow** (autoload, `scripts/level_flow.gd`): fade through black between `LEVELS`, counts
  `visits(level)` so a level can change between returns.
- **Waking** (`ForestNights` `wake` of the night just ended, read by `ApartmentLevel`; `@export wake` overrides it for tests):
  `bed` = `marker_spawn` as always; `couch` (after night 3) = mood `small_hours` (moonlight 0.08, exposure 1.0, window views
  tinted dark blue by the mood's `view_tint`, `practicals: false`) + `AptTvStatic` on the tv_console + `AptWake.couch` on the sofa.
  - **AptPracticals** (`scripts/apartment/apt_practicals.gd`): `off(root)` hides every `marker_light_*` omni under `root`
    (not the fridge) and swaps `kit_glow_shade` surfaces for an unlit copy. Load-time only. Any "power's off" moment can reuse it.
  - **AptTvStatic** (`scripts/apartment/apt_tv_static.gd`): `mount(piece)` puts `shaders/tv_static.gdshader` (unshaded snow,
    scanlines, a rolling band) on the piece's `panels` mesh as a per-instance override (the kit's `apt_gloss_tv` is shared with
    the oven window), a flickering cold omni 0.35 m in front (soft shadows, attenuation 1.8, **specular 0**: an omni highlight
    on the near-mirror window glass bloomed into a white blob) and a generated, looped white-noise hiss.
  - **AptWake** (`scripts/apartment/apt_wake.gd`): the body stands on a clear floor spot (sofa-local `STAND`, beside the coffee
    table) with physics and input off; the camera is offset under Head onto the end seat (`SEAT`, slumped: pitch -30, roll 7),
    lifts its head over 2.6 s, then eases home over 1.4 s (a cloth rustle), turns to look down at the journal (`look_at`,
    0.8 s; `PlayerInput.head_pitch` is synced so mouse look does not snap) and hands back control, ~6.4 s after load.
  - **The journal** (`journal_open`, `tools/blender/apt/writing.py`): spawned by the couch wake on the coffee table
    (`ApartmentLevel.JOURNAL_ON_TABLE`: between the remotes and the coasters, squared, facing the stand-up spot). Its
    `marker_use_journal` is an ordinary AptUse (REASSURE YOURSELF, `JOURNAL // OPEN  (WRITTEN n)`); **AptJournal**
    (`scripts/apartment/apt_journal.gd`) listens to it: freeze the player, lift the book to the face (held so the new line
    sits at `HELD`, FOV eased to 55), write "I am not a bad person" letter by letter with the pen following the ink
    (scratches), hold 0.6 s, put it back. Repeats forever, one new line each time; `AptUse.enabled` blocks re-use mid-write.
    **JournalPage** (`journal_page.gd`) draws the spread in a SubViewport (`in_viewport`, `refresh()` renders once per
    change): ruled cream paper, gutter shade, Caveat 50 px, 10 lines a page, per-line wobble, a full spread turns (bookFlip).
    Its texture is the `panels` material (albedo + a little emission so the ink reads by the TV). **JournalPen**
    (`journal_pen.gd`) maps a character to the nib's pose on the curved page (mirrors `writing.py` PW, PH, `page_z`).
    The piece contract: one `panels` strip UV-mapped to the whole spread (u 0..0.5 left page), pen = PIVOT node `pen` with
    its origin at the nib.
- **Squalor** (the flat after the lift crash: `ForestNights` `flat` = `squalor` on nights 4 and 5, read by `ApartmentLevel`;
  `@export flat` overrides it, `scenes/dev/apartment_squalor.tscn` is the flat with it set). Weeks of not leaving:
  - **Layout**: `tools/blender/props/apartment_mess.py` (imported by `apartment.py`): `ROWS` of pieces and `SPREADS` of
    litter carpets, in plan coordinates, exported as `marker_mess_<piece>__<n>` empties (`Shell.mess`, no AO proxy). On a
    kept morning they stay empty; **AptSqualor** (`scripts/apartment/apt_squalor.gd`) `prepare(model)` renames them to
    `marker_kit_` before `BunkerKit.furnish` and swaps the tidy pieces in `SWAPS` (bed_double -> bed_unmade, fruit_bowl ->
    fruit_bowl_rotten, trash_bin -> trash_bin_full, window_blinds -> window_blinds_shut, window_blinds_raised ->
    window_blinds_shut_check, which keeps the CHECK WINDOW use). Colliding mess (bags, heaps, cartons, the pizza tower) stays
    off the routes (door to door, bed to window); floor litter has no collision, the walker wades through it.
  - **Pieces** (`AptKit.MESS`, Blender modules `mess_trash.py`, `mess_home.py`, `mess_heap.py` on `mess_kit.MessKit`: bin-bag
    plastic, foam, food, mould, dirty paper, the `apt_mess.png` print atlas): trash_bag / _slump / _white, trash_bin_full,
    trash_heap / _small, pizza_box / _open / _stack / pizza_tower, takeout, paper_cup, cans_litter, bottles_litter,
    paper_litter, litter_spread_a / b / c (1.6 x 1.1 m carpets, three seeds), chip_bag, mail_pile (a PAST DUE notice in it),
    parcel_boxes, clothes_pile / _small, dish_pile, mug_mould, fruit_bowl_rotten, pot_crusted, counter_clutter, bed_unmade
    (shares `bedroom.bed_frame`), towel_floor, window_blinds_shut / _check (slats at 48 deg). Organic shapes are
    `apt_shapes.blob` (`AptKit.BLOB`): a noise-displaced sphere rescaled to an exact size, with `settle` (slumps onto the
    floor), `pinch` (a tied neck), `pleats` (plastic gathered into the knot), `crease` (sharp creases for plastic and paper,
    soft rolling folds for cloth with `crease=False`). `MessKit.PLACE(mark, loc, rot, pivot)` moves a group built since
    `mark()` rigidly; `PRINT_QUAD` / `PRINT_GRID` (a print that follows a puffed surface) / `SHEET` / `CAN_AT` / `CRUMPLE`.
    New materials `apt_sheen_*` (`apt_look.gd`: roughness 0.2, bright highlights: bags, foil, cans).
  - **Textures**: `python tools/blender/apt_mess_textures.py` -> `apt_mess.png` (4 x 4 cells, `apt_dims.MESS`, `mess_uv`) and
    the grime decals `apt_grime_{spill,rings,smudge,mould,water,dust,crumbs,streaks}.png` (streaks: runs down a wall). Generic prints only, no brands.
  - **Dressing** (`AptSqualor.dress`): `GRIME` rows -> **AptGrime** (`scripts/apartment/apt_grime.gd`, reusable:
    `make(parent, kind, at, size, surface_normal, yaw, opacity, depth)` -> a Decal with a matte ORM so dirt kills the floor's
    shine; `depth` reaches into a bath or onto a fixture):
    dust films over every floor, spills, cup rings on every top, crumbs, hand grime round the switches and the front door,
    black mould in the bathroom and window corners, ceiling leak stains, runs under the sills, behind the hob and down the
    bath and toilet walls, grime on the toilet, basin, vanity and tub panel, scuffs where things lean. `FLIES` rows -> **FlySwarm**
    (`scripts/world/fly_swarm.gd`, reusable: GPUParticles specks on turbulence + a **FlyBuzz**, `fly_buzz.gd`) over the bin,
    the fruit, the dishes, the pizza, the bag heaps. FlyBuzz is not a loop: after a random 3-16 s silence it plays one of
    eight single-fly takes (`audio/apartment/fly_buzz_0..7.wav` from `python tools/audio/flies.py`: passes, circles, short
    hops, bumping) at random pitch (0.82-1.22), level (-34..-24 dB) and spot round the swarm, never the same take twice
    running; each swarm starts at a random point in that cycle, so they never fall in step.
  - **Light**: mood `squalor` (`AptMood`): the blinds shut, daylight only in soft blades through the slats, stale dusty air
    (fog 0.04), drained (saturation 0.6), and the lamps weak (`practical_energy` 0.4: `AptPracticals.dim`, shades too).
  - Cost: ~+1.1 ms GPU at 1080p over the kept flat (living-room view: 7.5 ms, 2,070 draw calls). Test:
    `-Exec res://tools/exec/check_squalor.gd` (kept flat spawns none; every marker spawned, swaps done, grime and flies laid,
    no colliding mess on the routes).
- **Checks are acted out** (`AptCheck`, `scripts/apartment/apt_check.gd`, added by `AptUse.mount` for every id with a row in
  `apt_check_moves.gd`): freeze the player, lean in slowly (0.9 s: the camera eases along the aim line toward the row's `look`
  point, a head's lean: at most 0.35 m and never nearer than `near` (0.6 m); FOV 85 -> 75), look 0.35 s, work the piece's
  pivot nodes deliberately (each move: out to rest * (rotation, offset) and back `times` times, the use's sound each time,
  moves in sequence), look 0.5 s more, straighten up (0.9 s); ~5-7 s a check, then `AptUse.report()` emits `used` (so
  LEAVE's thought comes after the knob will not turn). LOCKS: each deadbolt thumb-turn opened and shut, knob rattled;
  LEAVE: knob turned and stopped; STOVE: each taped knob pressed against OFF; TAP: lever pushed down twice; PLUGS: toaster
  plug lifted and turned to the eye; PILLS: today's lid shut and opened twice; WINDOW: sash lock tugged. Pivots:
  `door_front` turn_knob / turn_bolt0 / turn_bolt1, `stove` turn_knob0..3, `counter_sink` turn_lever, `toaster` lift_plug,
  `pill_organizer` flip_lid, `window_blinds(_raised)` turn_latch. A new check = a PIVOT in the piece + one row.
- **Thoughts** (`AptThoughts`, `scripts/apartment/apt_thoughts.gd`, data): the walker's own voice through `FieldHud.speak`.
  `WAKE` by flat state, 3.2 s after arrival (squalor: "I'm not sure if I have any food left...or money"); `FIRST_CHECK`, one
  per check, the first time it is ever made (remembered across visits by `LevelFlow.first_time(key)`, which a dev warp
  resets; without LevelFlow, the first time this visit); `ALWAYS` (LEAVE: every time). Lines queue in the DialogBox, never
  over each other. Test: `-Exec res://tools/exec/check_thoughts.gd`. A new thought = one row.
- **AptUse extras**: a spec's optional 5th entry is its repeat line (`"%s  (WRITTEN %d)"`, default `(CHECKED n)`); `enabled`
  / `can_interact()` hide and block a use (`Player._check_interaction` skips any collider whose `can_interact()` is false).
- **Look**: `tools\capture.ps1 -Scene res://scenes/levels/apartment.tscn -Cam 4.2,1.7,1.0 -Look -3.7,0.8,2.0 -Wait 4 -NoUi -Fov 75`
  (living room from the dining table; Blender (x, y, z) = Godot (x, z, -y)). ~6.5 ms GPU at 1080p on an RX 7700 XT (`perf_probe.gd` prints gpu ms;
  ~5.2 ms with the old 2-split hard shadows).

## Apartment remnants (apartment kit pieces out in the forest levels)
Things from Apartment 4C turn up in the dead forest (`scripts/world/remnants/`). Every remnant is inert scenery: its
`marker_use_*` (and so any AptUse CHECK / SLEEP / LEAVE) is taken off.
- **Remnant** (`remnant.gd`): shared helpers. `Remnant.spawn(piece, parent, xform)` (AptKit piece, inert, scene kept loaded),
  `bounds(piece)` (visible mesh AABB in piece space), `grime(piece, ground_y)` = weathered material copies (`weathered()`:
  matte, faded toward grey, darker, one copy per source material shared by every remnant; the apartment's gloss otherwise
  mirrors the bright fog through any dirt) under the shared overlay `remnant_grime.tres` (`shaders/remnant_grime.gdshader`:
  world-space noise, mud up to `mud_band` above the per-instance `ground_y`, ash on upward faces, a film over the rest).
- **Small things in the buildings** (`RemnantSmalls.dress(model)`, called after `BunkerKit.furnish` in Outpost 73 / 02 / 03,
  Relay Hub 00 and the silo): up to `PER_BUILDING` sets (a pill bottle, a pair, four in a row, bottle + water glass, the
  organizer, the alarm clock, a book stack) squared to the edge of kit furniture (`HOSTS`: spots on `table_steel`,
  `shelf_rack`'s top shelf, `crate_large`; each spot has its own room along x). A set only goes where it fits: the room left
  by whatever else stands on that surface (its real bounds: the CRT and keyboard, amber cells, a route key case, a stacked
  crate). Seeded by the model file, so a building always holds the same things. They stay clean. New surface = a `HOSTS`
  row; new set = a `SETS` row `[half width, rows]`.
- **Buried in the forest** (`BuriedRemnants`): `DeadForestProps` calls `scatter()` for every streamed chunk; `CHANCE` (8 %) of
  chunks hold one large piece, seeded by the chunk, never within `CLEAR_ORIGIN` of the start, never on pools or cleared
  building sites; trees and rocks keep off its footprint. `PIECES` lists which poses each piece can take (UPRIGHT sunk
  25-40 % of its height, LEANING 14-26 deg, TOPPLED on its back); `place(kind, parent, terrain, at, yaw, pose, rng)` puts one
  anywhere. Every night, including 1-3.
- **Look / test**: `tools/exec/spawn_remnants.gd` (default: every piece in every pose in a line at z = -24 from x = -24, 4 m
  apart, e.g. `-Cam -18,1.7,-18.5 -Look -18,0.5,-24 -Wait 4 -NoUi`; `$env:REMNANTS="bunker"`: Outpost 73 at (0, 0, -40), prints
  where its remnants stand). `tools/exec/check_remnants.gd` (in `test.ps1`).

## Nights (the forest phases)
Each time the walker sleeps in the apartment, the dead forest is the next night (`ForestNights`, `scripts/world/forest_nights.gd`,
night = `LevelFlow.visits(&"forest")`; later nights repeat the last). Opening the forest scene directly (editor, capture,
smoke) is the full forest, so tools are unaffected.
| Night | Ambience | Buildings (`DeadForestEvent`) | Ends |
| :--- | :--- | :--- | :--- |
| 1 | silence (no wind, no music) | off | after 50 m of walking the walker trips and hits the ground (`DreamTrip`): hard cut to black, wake in the apartment. The amber pools cannot be drunk (no prompt) |
| 2 | wind, no music | off | a longer walk: the amber can be drunk now; after 150 m the walker trips again (`DreamTrip`) and wakes |
| 3 | wind, no music | off | the wraith (below): nothing, then "I don't think I am alone..." at 22 m, glimpses from 42 m that come nearer and nearer, then it takes the walker; they come to on the couch in the middle of the night, the TV showing static (below) |
| 4 | wind + music | on | the forest as it is, until the walker rides Missile Silo 00's freight lift down from launch control: it seizes, the cable snaps, the brakes catch and let go, and the cage hits the hall floor (`SiloLiftCrash`, below under the silo); hard cut to black, wake in bed to the flat gone to squalor (`flat`, above). The next sleep goes to the silo depths (`sleep`, below), not the forest |
| 5+ | wind + music | on | the forest as it is, no ending (the flat stays in squalor) |
A night's `sleep` key sends the next sleep somewhere other than the forest (`ApartmentLevel` reads it into `next_level`), so
night 5 is now reached only from the dev menu.

### The silo depths (after the crash)
`scenes/levels/silo_depths.tscn`, `SiloDepthsLevel` (`scripts/silo/silo_depths_level.gd`), `LevelFlow` level `&"silo"`: sleeping
in the flat gone to squalor comes here. A lone `MissileSilo` (no forest), driven as `DeadForestEvent` drives it; the
environment is the forest's, so the fog and the pale sky disc 136 m up match. The walker comes to flat on their back on the
wrecked cage's floor at the foot of the lift shaft, staring up at its stuttering lamp (`AptWake.come_to`: the couch wake,
generalised to any eye point and head pose), lifts their head and gets up facing the hall-side gate. `SiloLift.wreck()` puts
the cage down, shuts every gate, shows the crash's debris and hands over to **SiloLiftWreck** (`scripts/silo/silo_lift_wreck.gd`,
FSM JAMMED / FORCING / OPEN): FORCE GATE in the cage, three heaves, then both hall-side gates grind up; meanwhile the lamp
flickers on a dying circuit, sparks spit off the brake shoes, the wreck creaks. Then the generator hall, the blast door and
stair down to the bore floor, and the open vent to crawl into (above, under the silo). Nothing leads up. The duct's far end
is the next section. Test: `check_silo_depths.gd` (story data, wreck, wake, gate, floor under the whole walk, pit door, the
vent in and out, FallGuard, the wake's muffle and the duct's breathing).
- **Coming to: HearingReturn** (`scripts/world/hearing_return.gd`, reusable for any blow): the ears ring (`ears_ring.wav`: a
  5.2 kHz tone beating against a second, the blood pounding under it, slowing, all dying over 22 s) and the world is
  muffled and far off, then hearing comes back over `DURATION` (20 s): a low-pass opening exponentially from 180 Hz (lows
  first: the machines' roar is back before the detail) while a -16 dB duck lifts. Godot's Master bus cannot be renamed or
  bypassed, so it makes a `Dazed` bus (low-pass + duck, sending to Master) and moves every sound player on Master onto it,
  including ones added while it runs (`node_added`), and every `MuffleBus` (its bus sends into the daze instead: `Dazed` is
  inserted at bus index 1 because a bus can only send to one before it); the ringing stays on Master. Everything is moved
  back and the bus removed when it ends or is freed early. `SiloDepthsLevel` adds one on arrival.
- **The duct: DuctSound** (`scripts/world/duct_sound.gd`, reusable for any duct): stands at the far end; `VentDuct.climbed(inside,
  player)` starts and stops it. While crawling: the walker's breathing, `breath_calm` at the mouth crossfading to
  `breath_fast` (short, ragged, a voiced catch on the out-breaths) as the end gets closer; the sheet steel popping under
  them every 1.6-4.5 s while they move (`duct_flex_*`); every 9-20 s something from past the end, far off and muffled
  (`beyond_*`: a heavy thud, a long scrape, slow knocking). The draft through the cap's slot whistles all the time
  (`duct_draft`, placed at the end). Breathing fades in / out over 1.5 s. Rendered by `python tools/audio/silo_depths.py`.

`ForestNightDirector` (`scripts/world/forest_night_director.gd`, added by `DeadForestManager._apply_night`) counts metres walked
(on the ground, teleports excluded), runs the ending (DreamTrip / WraithStalk / the lift crash: it dooms every `SiloLift` that enters the tree), and wakes the walker with
`LevelFlow.go(&"apartment", 0.0, 1.8)` (fade 0 = hard cut, 1.8 s of black). A night = one `NIGHTS` row. Its `drink` flag
is read by each `AmberPool` in `_ready` and exposed as `can_interact()`; `Player._check_interaction` skips any collider
whose `can_interact()` returns false (no prompt, no use), so other interactables can be gated per night the same way. The apartment's own
mood still follows its visit count (golden hour first, night after).

### Forest render budget
The forest fog is opaque from `fog_depth_end` (45 m) on, so `DeadForestManager` clips the player camera at `fog_depth_end *
VIEW_PAST_FOG` (~68 m): buildings, relay chains and lights behind the fog wall cost nothing (a fully built night 4 went from
~4,600 draw calls to ~300). DevTools F2 (fog off) restores a 4 km far plane. Rules for anything added to the open world:
- every runtime light calls `KitLights.fade(light)` (`scripts/props/kit_lights.gd`; `BunkerFx.add_lights` already does);
- scattered props share resources through `PropCache` (`scripts/props/prop_cache.gd`: tinted tree materials, rock hulls);
- new flat zones / holes mark chunks dirty and `DeadForestTerrain` rebuilds each once at the end of the frame.

## The wraith (night 3)
A very tall starved thing, skin drawn tight over its skeleton, hunched, its long neck thrust out and its skull of a face
cocked up to stare; lips gone to the roots of the teeth, the nose rotted in, small wet black eyes deep in the sockets;
arms to the knees ending in long curled bloody-tipped fingers; legs dangling, feet pointed at the ground (it hovers, it
never walks); long wet black hair hanging round the face. Lit and opaque in the fog; no collision, no shadow.
- **Model** (`tools\blender.ps1 tools/blender/wraith/build.py`, add `-- preview` for Blender renders in `shots/`): built
  from Blender Studio's CC0 **Human Base Meshes** (not committed: download `human-base-meshes-bundle-v1.4.1.zip` from
  blender.org's demo files and unzip it into `tools/asset_src/`, which has a `.gdignore` and is git-ignored). Steps:
  `source` (the realistic male body + the realistic skeleton, fitted; the skull split into cranium / mandible / teeth),
  `starve` (every skin vertex sinks toward the bone under it: along its normal on the body, radially toward the skull's
  centre on the head so the face cannot fold; the depth field is smoothed first), `pose` + `rig_groups` (skin weights by
  nearest bone part, linear-blend posing about the skeleton's own joints: hunch, long neck, stretched arms and fingers,
  dangling legs; `relax` smooths torn armpits), `face` (lids and lips cut away, eyes, throat), `hair` (cards following
  gravity curves kept off the body and parted round the face, a generated wet-clump strand texture), `texture` (procedural
  skin: mottling, bruising, patchy veins, AO creases, pale over bone, masks for scalp / blood / grime / sockets) and
  `bake` (decimate, re-unwrap with the head enlarged, bake albedo + normal map at 2048), `rig_export` (a 20-bone game
  rig: `head`, `jaw`, `arm_l|r`, `hand_l|r`, ... ; `glow_l|r` eye markers). -> `models/generated/wraith.glb` (~90k faces)
  and `models/generated/tex/wraith_skin(_n).png`, `wraith_hair.png`.
- **Look**: `shaders/wraith.gdshader` (skin, teeth, eyes, throat) and `wraith_hair.gdshader` (cards, alpha to coverage
  under MSAA), both `#include wraith.gdshaderinc`: lit, opaque, `presence` dissolves it in/out through drifting noise with a
  cold burning edge, the feet thin into mist below `hem_top`, `flicker` stutters holes through it with dread, a faint cold
  rim. `WraithView` swaps every surface's material by name (`MATS`), adds dark wisps (`WraithWisps`) and a faint cold light,
  and moves it through `WraithRig` (bone rotations about their rest axes): hover bob, a cocked head snapping to new angles,
  swaying arms, `reach` / `reach_arm` / `grip` (arm up, wrist down), `rage` (head thrash), `gape` (jaw). `WraithEyes` hang on
  a BoneAttachment3D of `head` at the `glow_l|r` markers.
- **Sound** (played by `WraithAudio` from one `dread` 0..1; beds and stings synthesized at load, `WraithSynth` ->
  `WraithSfx` cache): a beating sub drone that swells in, a heartbeat past 0.35 dread that quickens, a dissonant sting when
  it is seen, a sucked-in rush when it vanishes, the old stalker breathing an octave down while it is near. Its **voice** is
  recorded: `python tools/audio/wraith_voice.py` -> `audio/wraith/*.wav` (numpy + the built-in Windows TTS voices, no
  downloads): whispers are TTS nonsense syllables re-voiced as real whispers (each frame's LPC envelope laid over noise,
  formants warped down, some takes reversed), `whisper_1..5` (random, never twice running, beside the listener's head on
  the side it is), `whisper_many`, `inhale`, and `scream` (three torn jittering voices through moving formants).
  `WraithScream` layers that over `stalker/scream.mp3` at two pitches and `roar.mp3`, through its own `WraithScream` bus
  (overdrive + hard limiter, +10 dB pre-gain, -0.3 dB ceiling): the loudest thing in the game without clipping.
  `WraithAudio.mix`: STALK / HUSH (drone cut, heart and breath only) / SILENT (every bed cut).
- **Stalking** (`WraithStalk`, FSM DORMANT -> UNEASE -> HIDDEN/SHOWN ... -> FINALE -> DONE): the distance of each glimpse
  shrinks with metres walked and with time (36 m -> 5 m, `CLOSE_PER_M`, `TIME_PROGRESS`), so standing still does not save
  you. A glimpse ends when looked at for `LOOK_TIME` (`WraithSight`: within 13 deg and a clear ray), when approached, or
  after `SHOW_MAX`; unwatched it drifts closer. Under 16 m half the glimpses are behind you. At 5 m it takes you.
- **Finale** (`WraithGrab`, FSM HUSH -> GRIP -> LOOK -> TURN -> GLARE -> SCREAM -> DONE, ~6 s, `LENGTH`): the walker freezes;
  the drone drops out, only the heart, its breath behind them and many voices at one ear; a long hand closes on that
  shoulder (`WraithView.reach_arm` / `reach` / `grip`, over a stand-in coat shoulder, `WalkerShoulder`: the walker has no
  body), everything cuts out and the camera jerks round and down to the hand (`WraithRig.hand_point`); they are
  wrenched round into its face as it stoops to their level (its eyes held `FACE` in front of theirs, `_hold_eyes`
  cancels the hover bob and head twitch); its red eyes (`WraithEyes`, dark until `set_glow`) flicker alight and it drags
  in a breath; it screams: head thrashing (`WraithView.rage`), jaw dropped far too far (`WraithView.gape`), view shaking and
  zooming in. Then every sound cuts dead, `caught`, and ForestNightDirector's hard cut to black wakes the walker.
  **NightmareFx** (`scripts/world/wraith/nightmare_fx.gd` + `shaders/nightmare_fx.gdshader`, a full-screen CanvasLayer at
  layer 90, under LevelFlow's black) tears the picture up beat by beat, reading `WraithGrab.state` / `progress()`: HUSH
  drains the colour, closes the edges in, grain, a heartbeat swell, first glitches; GRIP a white hit with tearing and a
  red / blue split; TURN a zoom blur; GLARE blood creeping in from the edges, the frame drawing in with its breath, red
  flickers; SCREAM vibration, heavy tearing and scanlines, red pulses, negative frames and hitches (the world frozen for a
  few frames via `Engine.time_scale`, always restored on DONE and on exit). Reds survive the desaturation, so the eyes and
  blood burn. The walker's HUD is hidden meanwhile. Uniforms are documented at the top of the shader.
  Step through it frame by frame: godot MCP `game_eval`
  `return load("res://tools/exec/wraith_grab_test.gd").new().step(get_tree(), 4.1)` then `game_screenshot`.
- **Look at it**: `tools\capture.ps1 -Scene res://scenes/levels/dead_forest.tscn -Exec res://tools/exec/spawn_wraith.gd
  -Cam 0.3,1.8,-2.6 -Look 0,2.1,-6 -Wait 4 -NoUi` (`WRAITH_POS=x,z`, `WRAITH_REACH`, `WRAITH_PRESENCE`). The capture tool's
  camera renders it paler than the game does; judge it in game (godot MCP) when it matters.
  The old `StalkerEnemy` (scripts/stalker_enemy.gd) is no longer spawned by anything.
