"""Outpost 73 prop kit: builds every kit prop, or only the ones named, into models/generated/o73_kit/<name>.glb.
Run:  python tools/blender/kit_textures.py   (once)   then   tools\\blender.ps1 tools/blender/props/o73_kit.py [name ...]
Then: godot --headless --path . --import   (each new .glb gets a .glb.import that embeds its textures and runs
      tools/o73_kit_import.gd: matte materials + scripts/props/kit_prop.gd on the root).
Builders live in tools/blender/kit/ (kit_lib.py has the conventions and node contract).
"""
import importlib
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, ".."))
sys.path.insert(0, os.path.join(HERE, "..", "kit"))
import ps1_lib as L  # noqa: E402

MODULES = ("terminals", "furniture", "storage", "infrastructure", "dosimeter", "relay", "router", "route_key", "walkways",
           "ducts", "servers", "tunnels", "rail_props", "junction", "archive", "drawings", "vault", "station")
BUILDERS = {}
for m in MODULES:
    try:
        BUILDERS.update(importlib.import_module(m).PROPS)
    except ModuleNotFoundError as e:
        if e.name != m:
            raise
names = L.argv_after_dashes() or list(BUILDERS)
unknown = [n for n in names if n not in BUILDERS]
if unknown:
    print(f"Error: unknown kit prop(s) {unknown}; known: {sorted(BUILDERS)}")
for n in names:
    if n in BUILDERS:
        BUILDERS[n]()
