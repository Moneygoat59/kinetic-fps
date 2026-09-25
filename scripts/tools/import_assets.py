#!/usr/bin/env python3
"""
import_assets.py
Populates curated model assets from asset_sources into kinetic-fps/models/.
Ensures file names, textures, and directory structures are Godot 4.3 ready.
"""

import os
import shutil
import glob
import subprocess
import sys

BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
MODELS_DIR = os.path.join(BASE_DIR, "models")
SOURCES_DIR = os.path.abspath(os.path.join(BASE_DIR, "..", "asset_sources"))

def copy_file(src, dst):
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    shutil.copy2(src, dst)

def setup_kaykit_space_base():
    src_base = os.path.join(SOURCES_DIR, "KayKit-Space-Base-Bits", "addons", "kaykit_space_base_bits", "Assets")
    dst_base = os.path.join(MODELS_DIR, "kaykit_space_base")
    os.makedirs(dst_base, exist_ok=True)
    os.makedirs(os.path.join(dst_base, "Textures"), exist_ok=True)

    # Texture
    tex_src = os.path.join(src_base, "textures", "spacebits_texture.png")
    if os.path.exists(tex_src):
        copy_file(tex_src, os.path.join(dst_base, "spacebits_texture.png"))
        copy_file(tex_src, os.path.join(dst_base, "Textures", "spacebits_texture.png"))

    # Models & bins
    gltf_files = glob.glob(os.path.join(src_base, "gltf", "*.gltf"))
    count = 0
    for g in gltf_files:
        fname = os.path.basename(g)
        bin_name = os.path.splitext(fname)[0] + ".bin"
        bin_path = os.path.join(src_base, "gltf", bin_name)
        
        copy_file(g, os.path.join(dst_base, fname))
        if os.path.exists(bin_path):
            copy_file(bin_path, os.path.join(dst_base, bin_name))
        count += 1
    print(f"[KayKit Space Base] Copied {count} glTF models + buffers + textures.")

def setup_kaykit_dungeon():
    src_base = os.path.join(SOURCES_DIR, "KayKit-Dungeon-Remastered", "addons", "kaykit_dungeon_remastered", "Assets")
    dst_base = os.path.join(MODELS_DIR, "kaykit_dungeon")
    os.makedirs(dst_base, exist_ok=True)
    os.makedirs(os.path.join(dst_base, "Textures"), exist_ok=True)

    # Texture
    tex_src = os.path.join(src_base, "texture", "dungeon_texture.png")
    if os.path.exists(tex_src):
        copy_file(tex_src, os.path.join(dst_base, "dungeon_texture.png"))
        copy_file(tex_src, os.path.join(dst_base, "Textures", "dungeon_texture.png"))

    # Copy glb models (which are named .gltf.glb in the repo)
    glb_files = glob.glob(os.path.join(src_base, "gltf", "*.glb"))
    count = 0
    for g in glb_files:
        base_name = os.path.basename(g)
        # Normalize name: if named 'name.gltf.glb', rename to 'name.glb'
        clean_name = base_name.replace(".gltf.glb", ".glb")
        copy_file(g, os.path.join(dst_base, clean_name))
        count += 1
    print(f"[KayKit Dungeon] Copied {count} self-contained .glb models.")

def setup_kaykit_hexagons():
    src_base = os.path.join(SOURCES_DIR, "KayKit-Medieval-Hexagon-Pack", "addons", "kaykit_medieval_hexagon_pack")
    dst_base = os.path.join(MODELS_DIR, "kaykit_hexagons")
    os.makedirs(dst_base, exist_ok=True)
    os.makedirs(os.path.join(dst_base, "Textures"), exist_ok=True)

    # Texture
    tex_src = os.path.join(src_base, "Textures", "hexagons_medieval.png")
    if os.path.exists(tex_src):
        copy_file(tex_src, os.path.join(dst_base, "hexagons_medieval.png"))
        copy_file(tex_src, os.path.join(dst_base, "Textures", "hexagons_medieval.png"))

    # Copy tiles, nature, mountains, rocks
    gltf_paths = glob.glob(os.path.join(src_base, "Assets", "gltf", "**", "*.gltf"), recursive=True)
    count = 0
    for g in gltf_paths:
        fname = os.path.basename(g)
        bin_name = os.path.splitext(fname)[0] + ".bin"
        bin_src = os.path.join(os.path.dirname(g), bin_name)

        copy_file(g, os.path.join(dst_base, fname))
        if os.path.exists(bin_src):
            copy_file(bin_src, os.path.join(dst_base, bin_name))
        count += 1
    print(f"[KayKit Hexagons] Copied {count} hexagonal tiles, mountains, and rock models.")

def setup_kenney_fps():
    src_base = os.path.join(SOURCES_DIR, "Kenney-Starter-Kit-FPS", "models")
    dst_base = os.path.join(MODELS_DIR, "kenney_fps")
    os.makedirs(dst_base, exist_ok=True)
    os.makedirs(os.path.join(dst_base, "Textures"), exist_ok=True)

    # Textures
    tex_dir = os.path.join(src_base, "Textures")
    if os.path.exists(tex_dir):
        for img in glob.glob(os.path.join(tex_dir, "*.png")):
            copy_file(img, os.path.join(dst_base, "Textures", os.path.basename(img)))
            copy_file(img, os.path.join(dst_base, os.path.basename(img)))

    count = 0
    for glb in glob.glob(os.path.join(src_base, "*.glb")):
        copy_file(glb, os.path.join(dst_base, os.path.basename(glb)))
        count += 1
    print(f"[Kenney FPS] Copied {count} .glb models.")

def setup_kenney_platformer():
    src_base = os.path.join(SOURCES_DIR, "Kenney-Starter-Kit-3D-Platformer", "models")
    dst_base = os.path.join(MODELS_DIR, "kenney_platformer")
    os.makedirs(dst_base, exist_ok=True)
    os.makedirs(os.path.join(dst_base, "Textures"), exist_ok=True)

    # Textures
    tex_dir = os.path.join(src_base, "Textures")
    if os.path.exists(tex_dir):
        for img in glob.glob(os.path.join(tex_dir, "*.png")):
            copy_file(img, os.path.join(dst_base, "Textures", os.path.basename(img)))
            copy_file(img, os.path.join(dst_base, os.path.basename(img)))

    count = 0
    for glb in glob.glob(os.path.join(src_base, "*.glb")):
        copy_file(glb, os.path.join(dst_base, os.path.basename(glb)))
        count += 1
    print(f"[Kenney Platformer] Copied {count} .glb models.")

def setup_cc0_tree():
    src_base = os.path.join(SOURCES_DIR, "CC0Tree", "All Models")
    dst_base = os.path.join(MODELS_DIR, "cc0_tree")
    os.makedirs(dst_base, exist_ok=True)

    fbx_files = glob.glob(os.path.join(src_base, "**", "*.fbx"), recursive=True)
    count = 0
    for f in fbx_files:
        copy_file(f, os.path.join(dst_base, os.path.basename(f)))
        count += 1
    print(f"[CC0Tree] Copied {count} low-poly .fbx models.")

def setup_curated_cc0_registry():
    # Download top representative models from ToxSam CC0 registry
    curated_ids = [
        "crystal-crossroads-001", # Arc
        "crystal-crossroads-002", # Column_Regular
        "crystal-crossroads-003", # Column_SmallBroken_01
        "crystal-crossroads-004", # Crystal_Base
        "crystal-crossroads-005", # Crystal_Big_01
        "crystal-crossroads-006", # Crystal_Big_02
        "crystal-crossroads-011", # Floor_Base
        "tomb-chaser-1-002",      # Column_Art
        "tomb-chaser-1-003",      # Door_Art
        "tomb-chaser-1-006",      # Wall_Art
        "towers-001",             # BlockChain_Bridge_Art
        "towers-002",             # BlockChain_Bridge_Fragment_Art
        "towers-009",             # BlockChain_Ramp_Art
        "towers-010",             # BlockChain_Tower01_Art
        "towers-011",             # BlockChain_Tower02_Art
        "abm-001",                # Altar01_Art
        "abm-004",                # Dome01_Art
        "ca-world-010",           # Column_01
        "transit-003",            # Iron_Structure_01_Art
        "transit-004",            # Pipe_01_Art
    ]
    fetch_tool = os.path.join(BASE_DIR, "scripts", "tools", "fetch_cc0_model.py")
    dst_dir = os.path.join(MODELS_DIR, "curated_cc0")
    os.makedirs(dst_dir, exist_ok=True)

    print(f"[Curated CC0] Downloading {len(curated_ids)} curated models from ToxSam CC0 registry...")
    for cid in curated_ids:
        cmd = [sys.executable, fetch_tool, "download", cid, "--dest", dst_dir]
        subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    dl_count = len(glob.glob(os.path.join(dst_dir, "*.glb")))
    print(f"[Curated CC0] Completed! Downloaded {dl_count} CC0 .glb models to {dst_dir}.")

def main():
    print("=== Populating 3D Model Assets for Kinetic FPS ===")
    setup_kaykit_space_base()
    setup_kaykit_dungeon()
    setup_kaykit_hexagons()
    setup_kenney_fps()
    setup_kenney_platformer()
    setup_cc0_tree()
    setup_curated_cc0_registry()
    print("=== All asset collections populated successfully! ===")

if __name__ == "__main__":
    main()
