#!/usr/bin/env python3
from __future__ import annotations
import argparse, hashlib, json, os, shutil, stat, subprocess, tempfile
from pathlib import Path

ap=argparse.ArgumentParser(description="Build FlexOS-authored files into updateable .deb packages.")
ap.add_argument("--source-root",default=".")
ap.add_argument("--output",default="dist/packages")
ap.add_argument("--package-version",required=True)
ap.add_argument("--product-version",required=True)
ap.add_argument("--base-url",default="")
ap.add_argument("--channel",default="beta")
args=ap.parse_args()

root=Path(args.source_root).resolve()
out=Path(args.output).resolve()
out.mkdir(parents=True,exist_ok=True)
mapping=json.loads((root/"packages/package-map.json").read_text(encoding="utf-8"))

def copy_item(src:Path,dst:Path):
    if src.is_dir():
        shutil.copytree(src,dst,dirs_exist_ok=True,copy_function=shutil.copy2)
    else:
        dst.parent.mkdir(parents=True,exist_ok=True)
        shutil.copy2(src,dst)

def normalize_modes(pkgroot:Path):
    for p in pkgroot.rglob("*"):
        if not p.is_file() or "DEBIAN" in p.parts:
            continue
        try:
            first=p.open("rb").read(2)
        except Exception:
            first=b""
        rel=p.relative_to(pkgroot).as_posix()
        if (
            first==b"#!" or rel.startswith("usr/bin/") or rel.startswith("usr/lib/flexos/")
            or rel.startswith("etc/grub.d/")
        ):
            p.chmod(0o755)
        else:
            p.chmod(0o644)

built=[]
for name,spec in mapping.items():
    with tempfile.TemporaryDirectory(prefix=f"{name}-") as td:
        pkgroot=Path(td)/name
        debian=pkgroot/"DEBIAN"
        debian.mkdir(parents=True)

        missing=[]
        for rel in spec["paths"]:
            src=root/"config/includes.chroot"/rel
            if not src.exists():
                missing.append(rel)
                continue
            copy_item(src,pkgroot/rel)
        if missing:
            raise SystemExit(f"{name}: missing source paths: {', '.join(missing)}")

        normalize_modes(pkgroot)

        depends=spec.get("depends","")
        control=[
            f"Package: {name}",
            f"Version: {args.package_version}",
            "Section: admin",
            "Priority: optional",
            "Architecture: all",
            "Maintainer: Pifo <noreply@users.noreply.github.com>",
        ]
        if depends:
            control.append(f"Depends: {depends}")
        control += [
            f"Description: {spec['description']}",
            f" FlexOS-authored component from product build {args.product_version}.",
        ]
        (debian/"control").write_text("\n".join(control)+"\n",encoding="utf-8")

        post=root/"packages/postinst"/f"{name}.postinst"
        if post.exists():
            shutil.copy2(post,debian/"postinst")
            (debian/"postinst").chmod(0o755)

        filename=f"{name}_{args.package_version}_all.deb"
        dest=out/filename
        subprocess.run(
            ["dpkg-deb","--root-owner-group","--build",str(pkgroot),str(dest)],
            check=True
        )
        digest=hashlib.sha256(dest.read_bytes()).hexdigest()
        url=f"{args.base_url.rstrip('/')}/{filename}" if args.base_url else filename
        built.append({
            "name":name,
            "version":args.package_version,
            "filename":filename,
            "sha256":digest,
            "size":dest.stat().st_size,
            "url":url,
        })

manifest={
    "format":1,
    "product_version":args.product_version,
    "package_version":args.package_version,
    "channel":args.channel,
    "packages":built,
}
(out/"flexos-packages-manifest.json").write_text(
    json.dumps(manifest,ensure_ascii=False,indent=2)+"\n",encoding="utf-8"
)
with (out/"SHA256SUMS").open("w",encoding="utf-8") as f:
    for row in built:
        f.write(f"{row['sha256']}  {row['filename']}\n")

print(f"Built {len(built)} FlexOS packages into {out}")
