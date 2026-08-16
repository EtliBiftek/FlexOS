#!/usr/bin/env python3
from __future__ import annotations
import argparse,json,re,subprocess
from pathlib import Path

ap=argparse.ArgumentParser(description="Promote FlexOS beta-development source to a taggable beta version.")
ap.add_argument("version",help="Example: 0.5.0-beta.1")
ap.add_argument("--skip-gate",action="store_true",help="For development only; do not use for public release.")
args=ap.parse_args()

if not re.fullmatch(r"\d+\.\d+\.\d+-beta\.\d+",args.version):
    raise SystemExit("Version must look like 0.5.0-beta.1")

if not args.skip_gate:
    rc=subprocess.run([
        "python3","scripts/beta-gate.py","--strict","--assume-automated-pass"
    ]).returncode
    if rc:
        raise SystemExit("Manual beta QA is incomplete. Promotion refused.")

old=Path("VERSION").read_text(encoding="utf-8").strip()
if not old.endswith("-dev"):
    raise SystemExit(f"Current VERSION is not a development beta: {old}")

Path("VERSION").write_text(args.version+"\n",encoding="utf-8")

# Update machine identity.
osr=Path("config/includes.chroot/etc/os-release")
text=osr.read_text(encoding="utf-8")
text=re.sub(r'^PRETTY_NAME=.*$', 'PRETTY_NAME="FlexOS 0.5 Beta"', text, flags=re.M)
text=re.sub(r'^VERSION=.*$', 'VERSION="0.5 Beta"', text, flags=re.M)
text=re.sub(r'^BUILD_ID=.*$', f'BUILD_ID="{args.version}"', text, flags=re.M)
osr.write_text(text,encoding="utf-8")

template=Path("config/includes.chroot/usr/share/flexos/identity/os-release")
template.write_text(text,encoding="utf-8")

identity_path=Path("config/includes.chroot/usr/share/flexos/identity.json")
identity=json.loads(identity_path.read_text(encoding="utf-8"))
identity["version"]="0.5 Beta"
identity["build_id"]=args.version
identity["channel"]="beta"
identity_path.write_text(json.dumps(identity,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")

# Replace release-facing preview strings without touching QA expectations.
targets=[
    Path("config/includes.chroot/etc/flexos-release"),
    Path("config/includes.chroot/etc/lsb-release"),
    Path("config/includes.chroot/etc/issue"),
    Path("config/includes.chroot/etc/issue.net"),
    Path("config/includes.chroot/etc/motd"),
    Path("config/includes.chroot/etc/lsb-release"),
    Path("config/includes.chroot/usr/share/flexos/identity/issue"),
    Path("config/includes.chroot/usr/share/flexos/identity/issue.net"),
    Path("config/includes.chroot/usr/share/flexos/identity/motd"),
    Path("config/includes.chroot/usr/share/flexos/release-info"),
    Path("config/includes.chroot/usr/share/flexos/calamares/branding/branding.desc"),
    Path("config/includes.chroot/usr/share/flexos/calamares/branding/welcome.svg"),
    Path("config/includes.chroot/usr/bin/flex-center"),
    Path("config/includes.chroot/usr/bin/flex-welcome"),
    Path("README.md"),
    Path("CHANGELOG.md"),
    Path("docs/KNOWN_ISSUES.md"),
    Path("docs/INSTALL.md"),
    Path("docs/RECOVERY.md"),
    Path("docs/UPDATES.md"),
    Path("docs/PACKAGE_REPOSITORY.md"),
]
for p in targets:
    if not p.exists():continue
    t=p.read_text(encoding="utf-8")
    t=t.replace(old,args.version)
    t=t.replace("0.5 Beta Preview","0.5 Beta")
    t=t.replace("beta-development","beta")
    t=t.replace("Beta Preview","Beta")
    p.write_text(t,encoding="utf-8")

print(f"FlexOS source promoted: {old} -> {args.version}")
print(f"Next: commit the promotion and create tag v{args.version}. CI will run the strict beta gate again.")
