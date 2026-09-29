"""Apartment kit: builds every piece, or only the ones named, into models/generated/apt_kit/<name>.glb.
Run:  python tools/blender/apt_textures.py   (once)   then   tools\blender.ps1 tools/blender/props/apt_kit.py [name ...]
Then: godot --headless --path . --import   (each new .glb gets a .glb.import that embeds its textures and runs
      tools/apt_kit_import.gd: material look + scripts/apartment/apt_prop.gd on the root).
Builders live in tools/blender/apt/ (apt_lib.py has the conventions and node contract, apt_dims.py the shared sizes).
"""
import importlib
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, ".."))
sys.path.insert(0, os.path.join(HERE, "..", "apt"))
import ps1_lib as L  # noqa: E402

MODULES = ("smalls", "fixtures", "living", "library", "entry", "kitchen", "counter", "bath", "bedroom", "writing", "mess_trash",
           "mess_home", "mess_heap")
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
    print(f"Error: unknown apartment piece(s) {unknown}; known: {sorted(BUILDERS)}")
for n in names:
    if n in BUILDERS:
        BUILDERS[n]()
