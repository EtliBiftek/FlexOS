#!/usr/bin/env python3
from __future__ import annotations
import json, os, platform, shutil, subprocess, socket
from pathlib import Path

IDENTITY = Path("/usr/share/flexos/identity.json")
DESKTOPS = Path("/usr/share/flexos/desktop-profiles.json")
PACKAGES = Path("/usr/share/flexos/package-profiles.json")
PROFILE_FILE = Path("/etc/flexos/profile")
DESKTOP_FILE = Path("/etc/flexos/desktop-profile")
DESKTOP_STATUS_FILE = Path("/etc/flexos/desktop-profile-status")

FLEX_PROFILES = {
    "balanced": {"power": "balanced", "description": "Balanced performance and efficiency."},
    "performance": {"power": "performance", "description": "Maximum available performance."},
    "gaming": {"power": "performance", "description": "Performance-oriented gaming mode."},
    "battery": {"power": "power-saver", "description": "Lower power use for laptops."},
    "creator": {"power": "performance", "description": "Performance profile for creative workloads."},
    "minimal": {"power": "balanced", "description": "Conservative FlexOS defaults with no aggressive tuning."},
}

def load_json(path):
    try:
        return json.loads(Path(path).read_text(encoding="utf-8"))
    except Exception:
        return {}

def run(cmd, check=False, capture=True):
    kwargs = {"text": True}
    if capture:
        kwargs.update(stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    p = subprocess.run(cmd, **kwargs)
    if check and p.returncode:
        raise RuntimeError((p.stdout or "").strip() or f"Command failed: {' '.join(cmd)}")
    return p

def command_exists(name):
    return shutil.which(name) is not None

def identity():
    return load_json(IDENTITY)

def current_profile():
    try:
        return PROFILE_FILE.read_text(encoding="utf-8").strip() or "balanced"
    except Exception:
        return "balanced"

def current_desktop_profile():
    try:
        return DESKTOP_FILE.read_text(encoding="utf-8").strip() or "kde"
    except Exception:
        return "kde"

def hardware():
    data = {
        "cpu": platform.processor() or "Unknown CPU",
        "kernel": platform.release(),
        "architecture": platform.machine(),
        "memory_gib": None,
        "gpus": [],
        "network": [],
        "battery": False,
        "virtualization": "none",
        "boot_mode": "UEFI" if Path("/sys/firmware/efi").exists() else "BIOS/Legacy",
    }
    try:
        cpuinfo = Path("/proc/cpuinfo").read_text(errors="ignore")
        for line in cpuinfo.splitlines():
            if line.lower().startswith("model name"):
                data["cpu"] = line.split(":", 1)[1].strip()
                break
    except Exception:
        pass
    try:
        mem = Path("/proc/meminfo").read_text()
        kb = int(next(x.split()[1] for x in mem.splitlines() if x.startswith("MemTotal:")))
        data["memory_gib"] = round(kb / 1024 / 1024, 1)
    except Exception:
        pass
    if command_exists("lspci"):
        out = run(["lspci"], capture=True).stdout or ""
        for line in out.splitlines():
            low = line.lower()
            if "vga compatible controller" in low or "3d controller" in low or "display controller" in low:
                data["gpus"].append(line.split(": ",1)[-1])
            if "network controller" in low or "ethernet controller" in low:
                data["network"].append(line.split(": ",1)[-1])
    data["battery"] = any(Path("/sys/class/power_supply").glob("BAT*"))
    if command_exists("systemd-detect-virt"):
        p = run(["systemd-detect-virt"], capture=True)
        if p.returncode == 0 and p.stdout:
            data["virtualization"] = p.stdout.strip()
    return data

def hardware_text():
    h = hardware()
    lines = [
        f"CPU: {h['cpu']}",
        f"RAM: {h['memory_gib']} GiB" if h["memory_gib"] is not None else "RAM: Unknown",
        f"Kernel: {h['kernel']}",
        f"Architecture: {h['architecture']}",
        f"Boot: {h['boot_mode']}",
        f"Virtualization: {h['virtualization']}",
        f"Battery: {'Yes' if h['battery'] else 'No'}",
    ]
    if h["gpus"]:
        lines.append("GPU:")
        lines.extend(f"  - {x}" for x in h["gpus"])
    if h["network"]:
        lines.append("Network:")
        lines.extend(f"  - {x}" for x in h["network"])
    nvidia = any("nvidia" in g.lower() for g in h["gpus"])
    if nvidia:
        lines += ["", "Recommendation: NVIDIA GPU detected. Proprietary NVIDIA driver is not bundled in FlexOS alpha."]
    return "\n".join(lines)

def available_power_profiles():
    if not command_exists("powerprofilesctl"):
        return []
    p = run(["powerprofilesctl", "list"], capture=True)
    out = p.stdout or ""
    result = []
    for name in ("performance", "balanced", "power-saver"):
        if name in out:
            result.append(name)
    return result

def apply_profile(name):
    if name not in FLEX_PROFILES:
        raise ValueError(f"Unknown profile: {name}")
    PROFILE_FILE.parent.mkdir(parents=True, exist_ok=True)
    requested = FLEX_PROFILES[name]["power"]
    available = available_power_profiles()
    if command_exists("powerprofilesctl") and requested in available:
        run(["powerprofilesctl", "set", requested], check=True)
    PROFILE_FILE.write_text(name + "\n", encoding="utf-8")
    return requested if requested in available else "recorded-only"

def package_profiles():
    return load_json(PACKAGES)

def desktop_profiles():
    return load_json(DESKTOPS)

def doctor():
    checks = []
    os_id = ""
    try:
        for line in Path("/etc/os-release").read_text().splitlines():
            if line.startswith("ID="):
                os_id = line.split("=",1)[1].strip().strip('"')
    except Exception:
        pass
    checks.append(("OK" if os_id == "flexos" else "WARN", f"OS identity: {os_id or 'unknown'}"))
    checks.append(("OK" if Path("/boot/grub/themes/flexos/theme.txt").exists() else "WARN", "FlexOS GRUB theme"))
    checks.append(("OK" if Path("/usr/bin/flex-center").exists() else "WARN", "Flex Center"))
    checks.append(("OK" if command_exists("NetworkManager") or command_exists("nmcli") else "WARN", "NetworkManager"))
    if command_exists("systemctl"):
        p = run(["systemctl", "--failed", "--no-legend"], capture=True)
        failed = [x for x in (p.stdout or "").splitlines() if x.strip()]
        checks.append(("OK" if not failed else "WARN", f"Failed systemd units: {len(failed)}"))
    try:
        usage = shutil.disk_usage("/")
        free_gib = usage.free / 1024**3
        checks.append(("OK" if free_gib >= 5 else "WARN", f"Free disk space: {free_gib:.1f} GiB"))
    except Exception:
        pass
    return checks
