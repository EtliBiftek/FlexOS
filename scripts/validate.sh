#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

errors=0
fail() { echo "[FAIL] $*" >&2; errors=$((errors+1)); }
ok() { echo "[ OK ] $*"; }

required=(
  VERSION build.sh clean.sh README.md LICENSE
  branding/boot-splash.svg scripts/package-release.sh scripts/check-package-list.sh
  config/package-lists/flexos.list.chroot
  config/includes.chroot/etc/os-release
  config/includes.chroot/usr/share/flexos/branding/flexos-logo.svg
  config/includes.chroot/usr/share/wallpapers/FlexOS/contents/images/2560x1440.svg
  config/includes.chroot/usr/share/applications/flexos-installer.desktop
  config/includes.chroot/usr/bin/flexos-installer
  config/includes.chroot/usr/bin/flexos-info
  config/hooks/live/010-flexos-branding.hook.chroot
  config/hooks/live/020-flexos-calamares.hook.chroot
  config/hooks/live/030-flexos-services.hook.chroot
)
for f in "${required[@]}"; do
  [[ -e "$f" ]] || fail "Missing $f"
done
[[ $errors -eq 0 ]] && ok "required project files"

for f in build.sh clean.sh scripts/*.sh config/hooks/live/*.hook.chroot config/includes.chroot/usr/bin/flexos-installer config/includes.chroot/usr/lib/flexos/flexos-first-login; do
  [[ -f "$f" ]] || continue
  bash -n "$f" || fail "shell syntax: $f"
done
[[ $errors -eq 0 ]] && ok "shell syntax"

pkg="config/package-lists/flexos.list.chroot"
if [[ -f "$pkg" ]]; then
  dupes="$(grep -Ev '^\s*(#|$)' "$pkg" | sort | uniq -d || true)"
  [[ -z "$dupes" ]] || fail "duplicate packages: $dupes"
  ok "package list has no duplicates"
  grep -qx 'plasma-workspace-wayland' "$pkg" && fail "obsolete package plasma-workspace-wayland is not in Debian 13" || true
  grep -qx 'kwin-wayland' "$pkg" || fail "Wayland support requires kwin-wayland"
fi

osr="config/includes.chroot/etc/os-release"
if [[ -f "$osr" ]]; then
  grep -qx 'ID=flexos' "$osr" || fail "os-release ID is not flexos"
  grep -q '^ID_LIKE=debian' "$osr" || fail "os-release must declare Debian compatibility"
  grep -q 'github.com/EtliBiftek/FlexOS' "$osr" || fail "os-release missing official URL"
  ok "os-release identity"
fi

if grep -RIl $'\r' --exclude='*.png' --exclude='*.jpg' . >/dev/null 2>&1; then
  fail "CRLF line endings detected"
else
  ok "LF line endings"
fi


if command -v python3 >/dev/null 2>&1; then
  python3 - <<'PY2' || fail "structured asset validation"
from pathlib import Path
import configparser
import xml.etree.ElementTree as ET

for p in Path('branding').rglob('*.svg'):
    ET.parse(p)
for p in Path('config/includes.chroot/usr/share').rglob('*.svg'):
    ET.parse(p)

for p in Path('config/includes.chroot/usr/share/applications').glob('*.desktop'):
    cp = configparser.ConfigParser(interpolation=None, strict=False)
    cp.optionxform = str
    cp.read(p, encoding='utf-8')
    assert 'Desktop Entry' in cp, f'{p}: missing [Desktop Entry]'
    assert cp['Desktop Entry'].get('Type'), f'{p}: missing Type'
    assert cp['Desktop Entry'].get('Name'), f'{p}: missing Name'
PY2
  ok "SVG and desktop-entry structure"
fi

if command -v python3 >/dev/null 2>&1; then
  python3 - <<'PY2' || fail "YAML validation"
from pathlib import Path
try:
    import yaml
except Exception:
    raise SystemExit(0)
for p in list(Path('.github').rglob('*.yml')) + list(Path('.github').rglob('*.yaml')):
    yaml.safe_load(p.read_text(encoding='utf-8'))
PY2
  ok "YAML (when PyYAML is available)"
fi

if (( errors )); then
  echo "Validation failed with $errors error(s)." >&2
  exit 1
fi

echo "FlexOS source validation passed."
