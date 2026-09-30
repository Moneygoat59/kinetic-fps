"""Example generator: weathered supply crate. Copy this file to start a new prop.
Run:  tools\\blender.ps1 tools/blender/props/example_crate.py
Output: models/generated/example_crate.glb
"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
import ps1_lib as L  # noqa: E402

OUT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "..", "models", "generated", "example_crate.glb"))

L.reset()
wood = L.material("crate_wood", (0.32, 0.24, 0.15))
metal = L.material("crate_strap", (0.16, 0.16, 0.17))

body = L.box("body", (0.9, 0.9, 0.7), (0, 0, 0.35), wood)
L.jitter(body, 0.012, seed=3)
straps = [L.box(f"strap{i}", (0.93, 0.08, 0.72), (0, y, 0.35), metal) for i, y in enumerate((-0.3, 0.3))]
crate = L.join([body] + straps, "example_crate")
L.ground_origin(crate)
L.export_glb(OUT, [crate])
