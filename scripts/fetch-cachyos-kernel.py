#!/usr/bin/env python3
from __future__ import annotations

import json
import os
import shutil
import sys
import tempfile
import urllib.error
import urllib.request
from pathlib import Path

repo = os.environ.get("GITHUB_REPOSITORY", "EtliBiftek/FlexOS")
tag = os.environ.get("FLEXOS_KERNEL_RELEASE_TAG", "kernel-latest")
out = Path(sys.argv[1] if len(sys.argv) > 1 else "dist/kernel")
api = f"https://api.github.com/repos/{repo}/releases/tags/{tag}"

headers = {
    "Accept": "application/vnd.github+json",
    "User-Agent": "FlexOS-kernel-fetcher/1",
    "X-GitHub-Api-Version": "2022-11-28",
}
token = os.environ.get("GH_TOKEN") or os.environ.get("GITHUB_TOKEN")
if token:
    headers["Authorization"] = f"Bearer {token}"

try:
    with urllib.request.urlopen(urllib.request.Request(api, headers=headers), timeout=30) as r:
        release = json.load(r)
except urllib.error.HTTPError as exc:
    if exc.code == 404:
        print(f"No {tag} kernel release exists yet for {repo}.", file=sys.stderr)
        raise SystemExit(2)
    raise

assets = release.get("assets", [])
wanted = []
for asset in assets:
    name = asset.get("name", "")
    if ((name.startswith("linux-image-") or name.startswith("linux-headers-")) and name.endswith(".deb")) or name in {"KERNEL_INFO", "SHA256SUMS"}:
        wanted.append((name, asset.get("browser_download_url")))

if not any(name.startswith("linux-image-") and name.endswith(".deb") for name, _ in wanted):
    print(f"Release {tag} does not contain a linux-image package.", file=sys.stderr)
    raise SystemExit(3)

out.parent.mkdir(parents=True, exist_ok=True)
with tempfile.TemporaryDirectory(prefix="flexos-kernel-") as td:
    tmp = Path(td)
    for name, url in wanted:
        if not url:
            continue
        print(f"Downloading {name}")
        req = urllib.request.Request(url, headers={"User-Agent": headers["User-Agent"]})
        if token:
            req.add_header("Authorization", f"Bearer {token}")
        with urllib.request.urlopen(req, timeout=120) as r, (tmp / name).open("wb") as f:
            shutil.copyfileobj(r, f)

    out.mkdir(parents=True, exist_ok=True)
    for old in out.iterdir():
        if old.is_file() and (old.name.startswith("linux-image-") or old.name.startswith("linux-headers-") or old.name in {"KERNEL_INFO", "SHA256SUMS"}):
            old.unlink()
    for src in tmp.iterdir():
        shutil.copy2(src, out / src.name)

print(f"Fetched {sum(1 for p in out.iterdir() if p.is_file())} kernel release asset(s) into {out}.")
