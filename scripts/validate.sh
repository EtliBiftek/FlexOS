#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
errors=0

fail(){ echo "[FAIL] $*" >&2; errors=$((errors+1)); }
ok(){ echo "[ OK ] $*"; }

required=(
  VERSION build.sh clean.sh README.md LICENSE CHANGELOG.md
  branding/boot-splash.svg
  config/package-lists/flexos.list.chroot
  config/includes.chroot/etc/os-release
  config/includes.chroot/usr/bin/flex
  config/includes.chroot/usr/bin/flex-center
  config/includes.chroot/usr/bin/flex-welcome
  config/includes.chroot/usr/bin/flex-self-update
  config/includes.chroot/usr/bin/flex-system-report
  config/includes.chroot/usr/bin/flex-beta-check
  config/includes.chroot/usr/bin/flexos-installer
  config/includes.chroot/usr/lib/flexos/flexlib.py
  config/includes.chroot/usr/lib/flexos/flexsuite.py
  config/includes.chroot/usr/lib/flexos/flex-admin
  config/includes.chroot/usr/lib/flexos/flex-recovery-console
  config/includes.chroot/usr/lib/flexos/flex-postinstall
  config/includes.chroot/usr/lib/systemd/system/flexos-recovery.target
  config/includes.chroot/usr/lib/systemd/system/flexos-recovery.service
  config/includes.chroot/usr/lib/systemd/system/flexos-ci-smoke.service
  config/includes.chroot/etc/grub.d/41_flexos_recovery
  config/includes.chroot/usr/share/flexos/apps.json
  config/includes.chroot/usr/share/flexos/identity.json
  config/includes.chroot/usr/share/flexos/desktop-profiles.json
  config/includes.chroot/usr/share/flexos/package-profiles.json
  config/includes.chroot/usr/share/flexos/calamares/modules/packagechooser-flexpackages.conf
  config/includes.chroot/usr/share/flexos/calamares/modules/shellprocess-flexpostinstall.conf
  config/hooks/live/010-flexos-branding.hook.chroot
  config/hooks/live/020-flexos-calamares.hook.chroot
  config/hooks/live/030-flexos-services.hook.chroot
  packages/package-map.json
  scripts/build-flexos-packages.py
  scripts/build-apt-repo.sh
  scripts/version-to-deb.py
  scripts/qemu-boot-smoke.sh
  scripts/beta-gate.py
  qa/test-matrix.json
  qa/record-test.py
  docs/BETA_EXIT_CRITERIA.md
  docs/BETA_TEST_MATRIX.md
  docs/RECOVERY.md
  docs/UPDATES.md
)

for f in "${required[@]}"; do
  [[ -e "$f" ]] || fail "Missing $f"
done
[[ $errors -eq 0 ]] && ok "required beta project files"

for f in \
  build.sh clean.sh scripts/*.sh config/hooks/live/*.hook.chroot \
  config/includes.chroot/usr/bin/flexos-installer \
  config/includes.chroot/usr/lib/flexos/flexos-first-login \
  config/includes.chroot/usr/lib/flexos/flex-identity-apply \
  config/includes.chroot/usr/lib/flexos/flex-snapshot-pre \
  config/includes.chroot/usr/lib/flexos/flex-recovery-console \
  config/includes.chroot/etc/grub.d/41_flexos_recovery
do
  [[ -f "$f" ]] || continue
  bash -n "$f" || fail "shell syntax: $f"
done
[[ $errors -eq 0 ]] && ok "shell syntax"

pkg="config/package-lists/flexos.list.chroot"
if [[ -f "$pkg" ]]; then
  dupes="$(grep -Ev '^\s*(#|$)' "$pkg" | sort | uniq -d || true)"
  [[ -z "$dupes" ]] || fail "duplicate packages: $dupes"
  for name in kwin-wayland python3-pyqt6 snapper flatpak ufw systemd-zram-generator whiptail cracklib-runtime; do
    grep -qx "$name" "$pkg" || fail "missing required package: $name"
  done
  grep -qx 'plasma-workspace-wayland' "$pkg" && fail "obsolete plasma-workspace-wayland package" || true
  [[ -z "$dupes" ]] && ok "package list"
fi

python3 - <<'PY' || fail "structured beta validation"
from pathlib import Path
import configparser,json,py_compile,xml.etree.ElementTree as ET

version=Path("VERSION").read_text().strip()
import re
assert re.fullmatch(r"0\.5\.0-beta\.1(?:-dev)?",version), f"Unexpected 0.5 beta VERSION: {version}"

# JSON
for p in Path("config/includes.chroot/usr/share/flexos").glob("*.json"):
    json.loads(p.read_text(encoding="utf-8"))
matrix=json.loads(Path("qa/test-matrix.json").read_text(encoding="utf-8"))
assert matrix["release"]=="0.5.0-beta.1"
assert len({t["id"] for t in matrix["tests"]})==len(matrix["tests"])

desktop=json.loads(Path("config/includes.chroot/usr/share/flexos/desktop-profiles.json").read_text())
assert set(desktop)=={"kde"}, "FlexOS beta must be KDE-only"

identity=json.loads(Path("config/includes.chroot/usr/share/flexos/identity.json").read_text())
assert identity["build_id"]==version

osr=Path("config/includes.chroot/etc/os-release").read_text()
assert "ID=flexos" in osr
assert f'BUILD_ID="{version}"' in osr

# Every path promised by a FlexOS .deb package must exist in the source tree.
pkgmap=json.loads(Path("packages/package-map.json").read_text())
for name,spec in pkgmap.items():
    for rel in spec["paths"]:
        p=Path("config/includes.chroot")/rel
        assert p.exists(), f"{name}: package source path missing: {rel}"

# Python
pyfiles=[
    Path("config/includes.chroot/usr/bin/flex"),
    Path("config/includes.chroot/usr/bin/flex-center"),
    Path("config/includes.chroot/usr/bin/flex-welcome"),
    Path("config/includes.chroot/usr/bin/flex-self-update"),
    Path("config/includes.chroot/usr/bin/flex-system-report"),
    Path("config/includes.chroot/usr/bin/flex-beta-check"),
    Path("config/includes.chroot/usr/lib/flexos/flexlib.py"),
    Path("config/includes.chroot/usr/lib/flexos/flexsuite.py"),
    Path("config/includes.chroot/usr/lib/flexos/flex-admin"),
    Path("config/includes.chroot/usr/lib/flexos/flex-postinstall"),
    Path("config/includes.chroot/usr/lib/flexos/flex-package-profile-install"),
    Path("config/includes.chroot/usr/lib/flexos/flex-profile-apply"),
    Path("scripts/build-flexos-packages.py"),
    Path("scripts/version-to-deb.py"),
    Path("scripts/beta-gate.py"),
    Path("qa/record-test.py"),
]
for p in pyfiles:
    py_compile.compile(str(p),doraise=True)

# SVG
for p in Path("branding").rglob("*.svg"):
    ET.parse(p)
for p in Path("config/includes.chroot/usr/share").rglob("*.svg"):
    ET.parse(p)

# .desktop
for p in Path("config/includes.chroot/usr/share/applications").glob("*.desktop"):
    cp=configparser.ConfigParser(interpolation=None,strict=False)
    cp.optionxform=str
    cp.read(p,encoding="utf-8")
    assert "Desktop Entry" in cp, f"{p}: no [Desktop Entry]"
    assert cp["Desktop Entry"].get("Type"), f"{p}: no Type"
    assert cp["Desktop Entry"].get("Name"), f"{p}: no Name"

# Branding / boot regressions seen during alpha.
branding=Path("config/includes.chroot/usr/share/flexos/calamares/branding/branding.desc").read_text()
assert 'slideshow:' in branding and 'slideshowAPI:' in branding
grub=Path("config/includes.chroot/boot/grub/themes/flexos/theme.txt").read_text()
assert "terminal-box:" not in grub, "invalid GRUB terminal-box regression"
ply=Path("config/includes.chroot/usr/share/plymouth/themes/flexos/flexos.script").read_text()
assert 'Image.Text("Starting"' not in ply, "static Plymouth Starting regression"

hook=Path("config/hooks/live/020-flexos-calamares.hook.chroot").read_text()
assert "shellprocess@flexpostinstall" in hook
assert "availableFileSystemTypes" in hook

print("structured validation OK")
PY
[[ $errors -eq 0 ]] && ok "Python / JSON / SVG / desktop / beta invariants"

if command -v python3 >/dev/null 2>&1; then
  python3 - <<'PY' || fail "YAML validation"
from pathlib import Path
try:
    import yaml
except Exception:
    raise SystemExit(0)
paths=list(Path(".github/workflows").glob("*.yml"))
paths += list(Path(".github/ISSUE_TEMPLATE").glob("*.yml"))
paths += list(Path("config/includes.chroot/usr/share/flexos/calamares/modules").glob("*.conf"))
paths += [Path("config/includes.chroot/usr/share/flexos/calamares/branding/branding.desc")]
for p in paths:
    yaml.safe_load(p.read_text(encoding="utf-8"))
PY
fi

if grep -RIl $'\r' \
    --exclude='*.png' --exclude='*.jpg' --exclude='*.zip' --exclude='*.deb' . >/dev/null 2>&1; then
  fail "CRLF line endings detected"
else
  ok "LF line endings"
fi

if (( errors )); then
  echo "Validation failed with $errors error(s)." >&2
  exit 1
fi

echo "FlexOS source validation passed for $(cat VERSION)."
