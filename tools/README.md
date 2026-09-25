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
