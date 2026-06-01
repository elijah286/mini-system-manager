#!/usr/bin/env python3
"""Build VI Browser gallery data: parse lvproj, create per-commit manifest, update commits.json."""

import json
import os
import shutil
import sys
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET
from datetime import datetime


def parse_lvproj(proj_path, workspace_root, exported_map):
    """Parse .lvproj XML and build a project tree with snapshot links."""
    tree_root = ET.parse(proj_path).getroot()
    my_computer = tree_root.find("Item")  # "My Computer" node
    if my_computer is None:
        return [], set()

    project_files = set()
    children = []
    for item in my_computer.findall("Item"):
        node = _process_item(item, workspace_root, exported_map, project_files)
        if node:
            children.append(node)

    tree = [{"name": my_computer.get("Name", "My Computer"), "type": "target", "children": children}]
    return tree, project_files


def _process_item(item, workspace_root, exported_map, project_files):
    item_type = item.get("Type", "")
    name = item.get("Name", "")

    if item_type in ("Dependencies", "Build"):
        return None

    if item_type == "VI":
        node = {"name": name, "type": "file"}
        # Match by filename at workspace root (forward-slash normalised)
        if name in exported_map:
            node["path"] = name
            node["html"] = exported_map[name]
            project_files.add(name)
        return node

    if item_type == "Folder":
        is_disk = any(
            p.get("Name") == "NI.DISK" and p.text == "true"
            for p in item.findall("Property")
        )
        if is_disk:
            folder_path = os.path.join(workspace_root, name)
            return _build_disk_folder(folder_path, name, workspace_root, exported_map, project_files)
        else:
            children = []
            for child in item.findall("Item"):
                c = _process_item(child, workspace_root, exported_map, project_files)
                if c:
                    children.append(c)
            return {"name": name, "type": "folder", "children": children}

    return None


def _build_disk_folder(folder_path, folder_name, workspace_root, exported_map, project_files):
    node = {"name": folder_name, "type": "folder", "children": []}
    if not os.path.isdir(folder_path):
        return node

    # Subdirectories first
    for entry in sorted(os.listdir(folder_path)):
        full = os.path.join(folder_path, entry)
        if os.path.isdir(full):
            child = _build_disk_folder(full, entry, workspace_root, exported_map, project_files)
            if child["children"]:
                node["children"].append(child)

    # Then files
    for entry in sorted(os.listdir(folder_path)):
        full = os.path.join(folder_path, entry)
        if os.path.isfile(full) and entry.lower().endswith((".vi", ".ctl")):
            rel = os.path.relpath(full, workspace_root).replace("\\", "/")
            file_node = {"name": entry, "type": "file", "path": rel}
            if rel in exported_map:
                file_node["html"] = exported_map[rel]
            project_files.add(rel)
            node["children"].append(file_node)

    return node


def fetch_existing_commits(pages_url):
    """Fetch existing commits.json from GitHub Pages."""
    try:
        url = pages_url.rstrip("/") + "/vi-snapshots/commits.json"
        req = urllib.request.Request(url, headers={"User-Agent": "GitHub-Actions"})
        with urllib.request.urlopen(req, timeout=10) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except Exception as e:
        print(f"  Could not fetch existing commits.json: {e}")
        return []


def main():
    workspace = sys.argv[1]          # e.g. D:\a\mini-system-manager\mini-system-manager
    snapshot_dir = sys.argv[2]        # e.g. D:\a\...\vi-snapshots
    deploy_dir = sys.argv[3]          # e.g. D:\a\...\vi-snapshots-deploy
    commit_sha = sys.argv[4]          # full SHA
    pages_url = sys.argv[5]           # e.g. https://elijah286.github.io/mini-system-manager
    gallery_html = sys.argv[6]        # path to vi-browser.html template

    # Read from env to avoid shell escaping issues
    commit_msg = os.environ.get("COMMIT_MSG", "unknown")
    commit_date = os.environ.get("COMMIT_DATE", "")

    short_sha = commit_sha[:7]
    commit_dir = os.path.join(deploy_dir, "commits", commit_sha)
    os.makedirs(commit_dir, exist_ok=True)

    print(f"Building gallery for commit {short_sha}")

    # --- Read flat manifest from export step ---
    manifest_path = os.path.join(snapshot_dir, "manifest.json")
    exported = []
    if os.path.isfile(manifest_path):
        with open(manifest_path, encoding="utf-8-sig") as f:
            data = json.load(f)
        exported = data if isinstance(data, list) else [data]

    # Build path -> html map (normalise to OS path separators for matching)
    exported_map = {}
    for item in exported:
        # Paths from PowerShell use backslash; normalise for local OS
        p = item["path"].replace("\\", "/")
        h = item["html"].replace("\\", "/")
        exported_map[p] = h

    print(f"  {len(exported_map)} exported snapshots")

    # --- Move snapshot HTML files to commit directory ---
    if os.path.isdir(snapshot_dir):
        for root, dirs, files in os.walk(snapshot_dir):
            for fname in files:
                if fname == "manifest.json":
                    continue
                src = os.path.join(root, fname)
                rel = os.path.relpath(src, snapshot_dir)
                dst = os.path.join(commit_dir, rel)
                os.makedirs(os.path.dirname(dst), exist_ok=True)
                shutil.move(src, dst)

    # --- Parse .lvproj ---
    proj_files = [f for f in os.listdir(workspace) if f.endswith(".lvproj")]
    tree = []
    project_files = set()

    if proj_files:
        proj_path = os.path.join(workspace, proj_files[0])
        print(f"  Parsing project: {proj_files[0]}")
        tree, project_files = parse_lvproj(proj_path, workspace, exported_map)
    else:
        print("  No .lvproj found — using flat file list")

    # --- Identify non-project files ---
    non_project = []
    for item in exported:
        p = item["path"].replace("\\", "/")
        if p not in project_files:
            non_project.append({
                "name": os.path.basename(p),
                "type": "file",
                "path": p,
                "html": item["html"].replace("\\", "/"),
            })

    print(f"  Project files: {len(project_files)}, non-project: {len(non_project)}")

    # --- Write per-commit manifest ---
    commit_manifest = {
        "tree": tree,
        "nonProjectFiles": non_project,
    }
    manifest_out = os.path.join(commit_dir, "manifest.json")
    with open(manifest_out, "w", encoding="utf-8") as f:
        json.dump(commit_manifest, f, indent=2, ensure_ascii=False)

    # --- Update commits.json ---
    print("  Fetching existing commits.json...")
    existing = fetch_existing_commits(pages_url)

    new_entry = {
        "sha": commit_sha,
        "short_sha": short_sha,
        "message": commit_msg[:120],
        "date": commit_date,
        "stats": {
            "total": len(exported_map),
            "succeeded": len(exported_map),
        },
    }

    # Remove duplicate if re-running same commit
    existing = [c for c in existing if c.get("sha") != commit_sha]
    existing.insert(0, new_entry)

    # Keep last 50 commits
    existing = existing[:50]

    commits_out = os.path.join(deploy_dir, "commits.json")
    with open(commits_out, "w", encoding="utf-8") as f:
        json.dump(existing, f, indent=2, ensure_ascii=False)

    print(f"  commits.json: {len(existing)} entries")

    # --- Copy gallery index.html ---
    shutil.copy2(gallery_html, os.path.join(deploy_dir, "index.html"))

    # --- Copy other HTML assets from the same pages directory ---
    pages_dir = os.path.dirname(os.path.abspath(gallery_html))
    gallery_basename = os.path.basename(gallery_html)
    for fname in os.listdir(pages_dir):
        if fname.endswith(".html") and fname != gallery_basename:
            shutil.copy2(
                os.path.join(pages_dir, fname),
                os.path.join(deploy_dir, fname),
            )
            print(f"  Copied pages asset: {fname}")

    print("Gallery build complete.")


if __name__ == "__main__":
    main()
