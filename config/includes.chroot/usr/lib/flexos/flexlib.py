#!/usr/bin/env python3
from __future__ import annotations
import json, os, shutil, subprocess
from pathlib import Path

IDENTITY=Path("/usr/share/flexos/identity.json")
PROFILE_FILE=Path("/etc/flexos/profile")
PACKAGES=Path("/usr/share/flexos/package-profiles.json")

FLEX_PROFILES={
    "balanced":{"power":"balanced","description":"Dengeli günlük kullanım."},
    "performance":{"power":"performance","description":"Maksimum kullanılabilir performans."},
    "gaming":{"power":"performance","description":"Oyun odaklı performans profili."},
    "battery":{"power":"power-saver","description":"Daha düşük güç tüketimi."},
    "creator":{"power":"performance","description":"Render ve üretim işleri için performans."},
    "minimal":{"power":"balanced","description":"Agresif tuning olmadan temel FlexOS davranışı."},
}

def run(cmd,timeout=12):
    try:
        p=subprocess.run(cmd,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=timeout)
        return p.returncode,(p.stdout or "").strip()
    except Exception as e:
        return 127,str(e)

def identity():
    try:return json.loads(IDENTITY.read_text(encoding="utf-8"))
    except Exception:return {}

def current_profile():
    try:return PROFILE_FILE.read_text(encoding="utf-8").strip() or "balanced"
    except Exception:return "balanced"

def package_profiles():
    try:return json.loads(PACKAGES.read_text(encoding="utf-8"))
    except Exception:return {}

def available_power_profiles():
    if not shutil.which("powerprofilesctl"):return []
    rc,out=run(["powerprofilesctl","list"])
    if rc:return []
    return [x for x in ("performance","balanced","power-saver") if x in out]

def apply_profile(name):
    if name not in FLEX_PROFILES:raise ValueError(f"Unknown profile: {name}")
    PROFILE_FILE.parent.mkdir(parents=True,exist_ok=True)
    requested=FLEX_PROFILES[name]["power"]
    available=available_power_profiles()
    if requested in available:
        rc,out=run(["powerprofilesctl","set",requested])
        if rc:raise RuntimeError(out or "powerprofilesctl failed")
        result=requested
    else:
        result="recorded-only"
    PROFILE_FILE.write_text(name+"\n",encoding="utf-8")
    return result

def doctor():
    checks=[]
    osid=""
    try:
        for line in Path("/etc/os-release").read_text().splitlines():
            if line.startswith("ID="):osid=line.split("=",1)[1].strip().strip('"')
    except Exception:pass
    checks.append(("OK" if osid=="flexos" else "WARN",f"OS identity: {osid or 'unknown'}"))
    checks.append(("OK" if Path("/boot/grub/themes/flexos/theme.txt").exists() else "WARN","FlexOS GRUB theme"))
    checks.append(("OK" if Path("/usr/bin/flex-center").exists() else "WARN","Flex Center"))
    if shutil.which("systemctl"):
        rc,out=run(["systemctl","--failed","--no-legend"])
        failed=[x for x in out.splitlines() if x.strip()]
        checks.append(("OK" if not failed else "WARN",f"Failed systemd units: {len(failed)}"))
    try:
        usage=shutil.disk_usage("/")
        free=usage.free/1024**3
        checks.append(("OK" if free>=5 else "WARN",f"Free disk space: {free:.1f} GiB"))
    except Exception:pass
    return checks
