#!/usr/bin/env python3
from __future__ import annotations

import hashlib
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
    "User-Agent": "FlexOS-kernel-fetcher/2",
    "X-GitHub-Api-Version": "2022-11-28",
}
token = os.environ.get("GH_TOKEN") or os.environ.get("GITHUB_TOKEN")
if token:
    headers["Authorization"] = f"Bearer {token}"

def runtime_image(name: str) -> bool:
    return name.startswith("linux-image-") and name.endswith(".deb") and "-dbg_" not in name

def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for block in iter(lambda: f.read(1024 * 1024), b""):
            h.update(block)
    return h.hexdigest()

def download(url: str, path: Path, digest: str = "") -> str:
    req = urllib.request.Request(url, headers={"User-Agent": headers["User-Agent"]})
    if token:
        req.add_header("Authorization", f"Bearer {token}")
    h = hashlib.sha256()
    with urllib.request.urlopen(req, timeout=180) as r, path.open("wb") as f:
        for block in iter(lambda: r.read(1024 * 1024), b""):
            h.update(block)
            f.write(block)
    actual = h.hexdigest()
    if digest.startswith("sha256:") and actual != digest.split(":", 1)[1]:
        raise SystemExit(f"GitHub asset digest mismatch for {path.name}")
    return actual

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
checksum_asset = None
for asset in assets:
    name = asset.get("name", "")
    if name == "SHA256SUMS":
        checksum_asset = asset
        continue
    if runtime_image(name) or (name.startswith("linux-headers-") and name.endswith(".deb")) or name == "KERNEL_INFO":
        wanted.append(asset)

if not any(runtime_image(a.get("name", "")) for a in wanted):
    print(f"Release {tag} does not contain a runtime linux-image package.", file=sys.stderr)
    raise SystemExit(3)

out.parent.mkdir(parents=True, exist_ok=True)
with tempfile.TemporaryDirectory(prefix="flexos-kernel-") as td:
    tmp = Path(td)
    expected = {}
    if checksum_asset and checksum_asset.get("browser_download_url"):
        checksum_path = tmp / "UPSTREAM_SHA256SUMS"
        download(checksum_asset["browser_download_url"], checksum_path, checksum_asset.get("digest", ""))
        for line in checksum_path.read_text(errors="ignore").splitlines():
            parts = line.split()
            if len(parts) >= 2:
                expected[parts[-1].lstrip("*")] = parts[0]

    actual = {}
    for asset in wanted:
        name = asset.get("name", "")
        url = asset.get("browser_download_url")
        if not url:
            continue
        print(f"Downloading {name}")
        digest = download(url, tmp / name, asset.get("digest", ""))
        if name in expected and expected[name] != digest:
            raise SystemExit(f"Release SHA256SUMS mismatch for {name}")
        actual[name] = digest

    out.mkdir(parents=True, exist_ok=True)
    for old in out.iterdir():
        if old.is_file() and (old.name.startswith("linux-image-") or old.name.startswith("linux-headers-") or old.name in {"KERNEL_INFO", "SHA256SUMS"}):
            old.unlink()
    for name in sorted(actual):
        shutil.copy2(tmp / name, out / name)
    (out / "SHA256SUMS").write_text("".join(f"{actual[name]}  {name}\n" for name in sorted(actual)), encoding="utf-8")

print(f"Fetched {sum(1 for p in out.iterdir() if p.is_file())} runtime kernel release asset(s) into {out}; debug packages were excluded.")
