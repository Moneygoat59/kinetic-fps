# KINETIC (dead-forest survival game, Godot 4.7, GDScript)

Read `AGENTS.md` first: it holds the engineering rules (frame budget, enum states not booleans, files < 150 lines, signals, minimal-delta fixes). Follow them.

## Current direction
The main scene is `scenes/levels/dead_forest.tscn`: an infinitely streaming dead forest with a bunker, nuclear progression, radiation, amber pools and stalkers. Movement is walk-only there (`Player.walk_only`); the older vine/bhop "Sector 00" mega-level in the README is legacy.

## Verify your work, do not guess
The world is procedural GDScript, so look at it. Tools live in `tools/` (see `tools/README.md`):
- `tools\capture.ps1` renders a scene/model to `shots/*.png` (read the PNG). Use `-Wait 4 -NoUi` for the forest (skips the wake-up overlay).
- `tools\smoke.ps1` loads a scene headless and reports errors and frame times.
- `tools\check.ps1` syntax-checks all scripts. `tools\blender.ps1` runs headless Blender generators for props.
- The `godot` MCP server (`.mcp.json`) can run the game and take in-game screenshots.

## Known issues
- `amber_pool.gd:23` loads PNGs via `Image.load_from_file` (breaks in exported builds); use `load()` on the imported texture.
- 10 scripts exceed 150 lines (largest: `small_bunker.gd`).
