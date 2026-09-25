# KINETIC dev tooling

All scripts are run from anywhere; they `cd` to the project root. Godot 4.7 is on PATH; Blender 5.2 is found automatically.

| Tool | Purpose |
| :--- | :--- |
| `tools\capture.ps1` | Render a scene or `.glb` to PNG from chosen angles so the result can be looked at. Needs a GPU window (not headless). |
| `tools\smoke.ps1` | Headless load + N frames of a scene; prints node count, frame times, and script errors. |
| `tools\check.ps1` | `gdparse` on every script, flags files > 150 lines (AGENTS.md 3.1); `-Models` validates generated `.glb`. |
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
| `tools\exec\*.gd` | Hook scripts for `capture.ps1 -Exec` (e.g. `build_small_bunker.gd` builds the procedural bunker before the shot). |
| `tools\blender\textures.py` | Regenerates the procedural PS1 textures into `models/generated/tex/`. |
| `tools\blender\props\outpost73_bunker.py` | Outpost 73 bunker generator (walkable shell, doors, markers). Naming: `*-colonly` = collision-only trimesh on import, `marker_*` = gameplay anchors. |

## Lighting bake (PS1 vertex lighting)
`tools/blender/ps1_ao.py` bakes ambient occlusion + chamfer-edge highlights into per-corner vertex colours (glTF `COLOR_0`; Godot
multiplies them into albedo). `subdivide_by_length` gives big flat faces enough vertices for the gradient; `ground_z=0` makes wall bases
darken like contact shadows. Emissive materials (name prefix `bunker_glow`) are skipped. Gotchas found the hard way:
- Blender's "Specular IOR Level" does not survive glTF export; `OutpostBunker._make_matte()` zeroes `metallic_specular` at load.
- Godot lights an emissive surface's albedo on top of its emission, so glow materials use near-black albedo tints.
- Unshadowed directional lights shine through walls; only the level's `Moonlight` casts shadows (interior darkness comes from the baked AO + shadowed omni lights).

## Screens, decals, textures (v3)
`tools/blender/textures.py` also draws every screen and decal (uses the project's own fonts in `fonts/`):
- **Screens** (`screen_*`): amber terminal, green rad monitor, "NO SIGNAL" static, site map, generator LCD. Emissive quads named `scr_*`,
  materials `bunker_scr_*`. `scripts/bunker/bunker_screens.gd` flips the `_a/_b` frame pairs on a timer (cursor blink, changing
  readings, map beacon) and scrolls/flickers the static, only while the player is within 24 m.
- **Decals** (`decal_*`, alpha-blended quads in the `bunker_decals` node): stencil lettering, radiation signs, dirt streaks, stains,
  hazard stripe, pinned notes. Offset 1-2 cm from the surface; floor decals use different heights to avoid z-fighting.
- To change screen text/graphics, edit `screens()` in `textures.py`, rerun it, then `godot --headless --path . --import`.
- Blender alpha: `material.surface_render_method = "BLENDED"` exports as glTF `alphaMode: BLEND` (see `ps1_lib.decal_material`).
