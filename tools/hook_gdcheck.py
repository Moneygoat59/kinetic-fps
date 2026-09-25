"""Claude Code PostToolUse hook: syntax-check any .gd file just edited/written using Godot itself.
(gdtoolkit's gdparse rejects valid `stmt; if x: y` one-liners this codebase uses, so Godot is the authority.)
Reads the hook JSON from stdin. On a parse error, prints it to stderr and exits 2 so the model sees and fixes it.
Also notes (non-blocking) when a script exceeds the 150-line rule from AGENTS.md.
"""
import json
import os
import subprocess
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))

try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)

path = os.path.abspath((data.get("tool_input") or {}).get("file_path", ""))
if not path.endswith(".gd") or not path.startswith(ROOT):
    sys.exit(0)
rel = os.path.relpath(path, ROOT).replace("\\", "/")

r = subprocess.run(["godot", "--headless", "--path", ROOT, "--check-only", "--script", rel],
                   capture_output=True, text=True, timeout=60)
if r.returncode != 0:
    errs = [l for l in (r.stdout + r.stderr).splitlines() if "SCRIPT ERROR" in l or "Parse Error" in l or "res://" in l]
    sys.stderr.write(f"GDScript error in {rel}:\n" + "\n".join(errs[:8]) + "\n")
    sys.exit(2)

if rel.startswith("scripts/"):
    n = sum(1 for _ in open(path, encoding="utf-8"))
    if n > 150:
        print(f"note: {rel} is {n} lines (AGENTS.md rule 3.1 targets < 150)")
