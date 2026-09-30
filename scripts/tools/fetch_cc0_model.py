#!/usr/bin/env python3
"""
fetch_cc0_model.py
CLI tool to search, inspect, and download CC0 3D models from the Open Source 3D Asset Registry
(990+ CC0 .glb models by Polygonal Mind / ToxSam) and optionally Poly Pizza API v1.1.
"""

import argparse
import glob
import json
import os
import sys
import urllib.request
import urllib.error

DEFAULT_REGISTRY_PATH = os.path.abspath(
    os.path.join(os.path.dirname(__file__), "..", "..", "..", "asset_sources", "open-source-3D-assets", "data", "assets")
)
DEFAULT_OUTPUT_DIR = os.path.abspath(
    os.path.join(os.path.dirname(__file__), "..", "..", "models", "curated_cc0")
)


def load_registry(registry_dir=DEFAULT_REGISTRY_PATH):
    if not os.path.exists(registry_dir):
        print(f"[Error] Registry path not found: {registry_dir}", file=sys.stderr)
        return []
    
    files = glob.glob(os.path.join(registry_dir, "*.json"))
    all_models = []
    for f in files:
        try:
            with open(f, "r", encoding="utf-8") as jf:
                items = json.load(jf)
                for item in items:
                    item["_source_file"] = os.path.basename(f)
                    all_models.append(item)
        except Exception as e:
            print(f"[Warning] Failed to parse {f}: {e}", file=sys.stderr)
    return all_models


def cmd_list_collections(args):
    registry_dir = args.registry or DEFAULT_REGISTRY_PATH
    files = sorted(glob.glob(os.path.join(registry_dir, "*.json")))
    if not files:
        print(f"No JSON collections found in {registry_dir}")
        return

    print(f"Found {len(files)} collections in {registry_dir}:\n")
    total_models = 0
    for f in files:
        try:
            with open(f, "r", encoding="utf-8") as jf:
                data = json.load(jf)
                total_models += len(data)
                sample_names = [d.get("name", "") for d in data[:4]]
                proj_id = data[0].get("project_id", "") if data else ""
                print(f"- {os.path.basename(f)} ({len(data)} models) [Project: {proj_id}]")
                print(f"    Sample models: {', '.join(sample_names)}")
        except Exception as e:
            print(f"- {os.path.basename(f)}: error reading ({e})")
    print(f"\nTotal models indexed: {total_models}")


def cmd_search(args):
    models = load_registry(args.registry)
    query = args.query.lower() if args.query else ""
    cat_filter = args.category.lower() if args.category else None
    theme_filter = args.theme.lower() if args.theme else None

    matches = []
    for m in models:
        name = m.get("name", "").lower()
        desc = m.get("description", "").lower()
        proj = m.get("project_id", "").lower()
        metadata = m.get("metadata", {})
        attrs = metadata.get("attributes", [])
        attr_text = " ".join(f"{a.get('trait_type','')}:{a.get('value','')}".lower() for a in attrs)
        
        full_text = f"{name} {desc} {proj} {attr_text}"

        if query and query not in full_text:
            continue

        if cat_filter:
            cats = [a.get("value", "").lower() for a in attrs if a.get("trait_type", "").lower() == "category"]
            if not any(cat_filter in c for c in cats):
                continue

        if theme_filter:
            themes = [a.get("value", "").lower() for a in attrs if a.get("trait_type", "").lower() == "theme"]
            if not any(theme_filter in t for t in themes):
                continue

        matches.append(m)

    print(f"Found {len(matches)} matching models for query '{query}':\n")
    limit = args.limit or 25
    for i, m in enumerate(matches[:limit], 1):
        mid = m.get("id", "")
        name = m.get("name", "")
        proj = m.get("project_id", "")
        file_size = m.get("metadata", {}).get("file_size", 0)
        size_kb = f"{file_size / 1024:.1f} KB" if file_size else "unknown size"
        url = m.get("model_file_url", "")
        attrs = m.get("metadata", {}).get("attributes", [])
        attr_summary = ", ".join(f"{a.get('trait_type')}: {a.get('value')}" for a in attrs[:3])
        
        print(f"[{i:02d}] ID: {mid:<28} Name: {name:<24} Size: {size_kb:<10} Proj: {proj}")
        if attr_summary:
            print(f"     Traits: {attr_summary}")
        print(f"     URL: {url}")
        print()

    if len(matches) > limit:
        print(f"... and {len(matches) - limit} more. Use --limit {len(matches)} to view all.")


def download_file(url, target_path):
    os.makedirs(os.path.dirname(target_path), exist_ok=True)
    req = urllib.request.Request(
        url,
        headers={"User-Agent": "KineticFPS-ModelFetcher/1.0"}
    )
    with urllib.request.urlopen(req) as resp, open(target_path, "wb") as out:
        out.write(resp.read())


def cmd_download(args):
    models = load_registry(args.registry)
    target = args.id_or_name.strip()
    dest_dir = args.dest or DEFAULT_OUTPUT_DIR

    match = None
    for m in models:
        if m.get("id") == target or m.get("name", "").lower() == target.lower():
            match = m
            break

    if not match:
        # Try substring match
        candidates = [m for m in models if target.lower() in m.get("name", "").lower()]
        if len(candidates) == 1:
            match = candidates[0]
        elif len(candidates) > 1:
            print(f"Multiple models match '{target}':")
            for c in candidates[:10]:
                print(f"  - {c.get('id')}: {c.get('name')}")
            print("Please specify the exact ID.")
            return

    if not match:
        print(f"No model found matching '{target}'.")
        return

    url = match.get("model_file_url")
    if not url:
        print(f"Model '{match.get('name')}' has no download URL.")
        return

    fname = os.path.basename(url)
    out_file = os.path.join(dest_dir, fname)
    print(f"Downloading {match.get('name')} ({fname}) to {out_file}...")
    try:
        download_file(url, out_file)
        print(f"Successfully downloaded: {out_file} ({os.path.getsize(out_file)} bytes)")
    except Exception as e:
        print(f"Failed to download {url}: {e}", file=sys.stderr)


def cmd_download_tag(args):
    models = load_registry(args.registry)
    tag = args.tag.lower()
    dest_dir = args.dest or DEFAULT_OUTPUT_DIR
    limit = args.limit or 10

    matches = []
    for m in models:
        name = m.get("name", "").lower()
        desc = m.get("description", "").lower()
        proj = m.get("project_id", "").lower()
        metadata = m.get("metadata", {})
        attrs = metadata.get("attributes", [])
        attr_text = " ".join(f"{a.get('trait_type','')}:{a.get('value','')}".lower() for a in attrs)
        if tag in f"{name} {desc} {proj} {attr_text}":
            matches.append(m)

    to_download = matches[:limit]
    print(f"Found {len(matches)} matching models for tag '{tag}'. Downloading {len(to_download)} models to {dest_dir}...")
    success = 0
    for i, m in enumerate(to_download, 1):
        url = m.get("model_file_url")
        if not url:
            continue
        fname = os.path.basename(url)
        out_file = os.path.join(dest_dir, fname)
        try:
            print(f"[{i}/{len(to_download)}] Downloading {fname}...")
            download_file(url, out_file)
            success += 1
        except Exception as e:
            print(f"  Failed: {e}", file=sys.stderr)
    print(f"Finished. Downloaded {success}/{len(to_download)} models to {dest_dir}.")


def cmd_polypizza_search(args):
    token = args.token or os.environ.get("POLYPIZZA_AUTH_TOKEN")
    if not token:
        print("Error: POLYPIZZA_AUTH_TOKEN is required. Pass with --token or set in environment.", file=sys.stderr)
        return

    url = f"https://api.poly.pizza/v1.1/search/{urllib.parse.quote(args.query)}"
    req = urllib.request.Request(
        url,
        headers={"x-auth-token": token, "Content-Type": "application/json"}
    )
    try:
        with urllib.request.urlopen(req) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            results = data.get("results", [])
            print(f"Poly Pizza returned {len(results)} results for '{args.query}':\n")
            for r in results[:args.limit or 20]:
                print(f"- ID: {r.get('id')} | Name: {r.get('Title')} | Author: {r.get('Creator')} | License: {r.get('License')}")
                if r.get("Download"):
                    print(f"  Download: {r.get('Download')}")
    except urllib.error.HTTPError as e:
        print(f"Poly Pizza API error: {e.code} {e.reason}", file=sys.stderr)


def main():
    parser = argparse.ArgumentParser(description="Kinetic FPS CC0 3D Model Fetcher")
    subparsers = parser.add_subparsers(dest="command", required=True)

    # list-collections
    p_list = subparsers.add_parser("list-collections", help="List all indexed asset collections")
    p_list.add_argument("--registry", default=DEFAULT_REGISTRY_PATH, help="Path to assets JSON folder")

    # search
    p_search = subparsers.add_parser("search", help="Search the CC0 3D model database")
    p_search.add_argument("query", nargs="?", default="", help="Keyword to search")
    p_search.add_argument("--category", help="Filter by attribute Category (e.g. Architecture, Nature, Props)")
    p_search.add_argument("--theme", help="Filter by attribute Theme (e.g. Ancient Ruins, Cyberpunk)")
    p_search.add_argument("--limit", type=int, default=20, help="Maximum number of results to display")
    p_search.add_argument("--registry", default=DEFAULT_REGISTRY_PATH, help="Path to assets JSON folder")

    # download
    p_dl = subparsers.add_parser("download", help="Download a model by ID or name")
    p_dl.add_argument("id_or_name", help="Model ID or exact name")
    p_dl.add_argument("--dest", default=DEFAULT_OUTPUT_DIR, help="Destination directory")
    p_dl.add_argument("--registry", default=DEFAULT_REGISTRY_PATH, help="Path to assets JSON folder")

    # download-tag
    p_dltag = subparsers.add_parser("download-tag", help="Batch download models matching a tag")
    p_dltag.add_argument("tag", help="Tag or keyword to match")
    p_dltag.add_argument("--limit", type=int, default=10, help="Max models to download")
    p_dltag.add_argument("--dest", default=DEFAULT_OUTPUT_DIR, help="Destination directory")
    p_dltag.add_argument("--registry", default=DEFAULT_REGISTRY_PATH, help="Path to assets JSON folder")

    # polypizza-search
    p_pp = subparsers.add_parser("polypizza-search", help="Search models via Poly Pizza API v1.1")
    p_pp.add_argument("query", help="Keyword to search")
    p_pp.add_argument("--token", help="Poly Pizza auth token")
    p_pp.add_argument("--limit", type=int, default=20, help="Max results")

    args = parser.parse_args()

    if args.command == "list-collections":
        cmd_list_collections(args)
    elif args.command == "search":
        cmd_search(args)
    elif args.command == "download":
        cmd_download(args)
    elif args.command == "download-tag":
        cmd_download_tag(args)
    elif args.command == "polypizza-search":
        cmd_polypizza_search(args)


if __name__ == "__main__":
    main()
