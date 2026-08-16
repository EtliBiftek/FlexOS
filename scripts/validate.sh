#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)";cd "$ROOT";errors=0
fail(){ echo "[FAIL] $*" >&2;errors=$((errors+1)); }
required=(VERSION build.sh clean.sh README.md LICENSE config/package-lists/flexos.list.chroot config/includes.chroot/etc/os-release config/includes.chroot/usr/bin/flexos-installer config/includes.chroot/usr/bin/flex config/includes.chroot/usr/bin/flex-center config/includes.chroot/usr/bin/flex-welcome config/includes.chroot/usr/bin/flex-system-report config/includes.chroot/usr/lib/flexos/flexlib.py config/includes.chroot/usr/lib/flexos/flexsuite.py config/includes.chroot/usr/lib/flexos/flex-admin config/includes.chroot/usr/share/flexos/apps.json config/includes.chroot/usr/share/flexos/package-profiles.json config/includes.chroot/usr/share/flexos/calamares/modules/packagechooser-flexpackages.conf config/hooks/live/010-flexos-branding.hook.chroot config/hooks/live/020-flexos-calamares.hook.chroot config/hooks/live/030-flexos-services.hook.chroot)
for f in "${required[@]}";do [[ -e "$f" ]]||fail "Missing $f";done
for f in build.sh clean.sh scripts/*.sh config/hooks/live/*.hook.chroot config/includes.chroot/usr/bin/flexos-installer config/includes.chroot/usr/lib/flexos/flexos-first-login config/includes.chroot/usr/lib/flexos/flex-identity-apply config/includes.chroot/usr/lib/flexos/flex-snapshot-pre;do
  [[ -f "$f" ]] || continue
  bash -n "$f" || fail "shell syntax: $f"
done
pkg=config/package-lists/flexos.list.chroot
dupes="$(grep -Ev '^\s*(#|$)' "$pkg"|sort|uniq -d||true)";[[ -z "$dupes" ]]||fail "duplicate packages: $dupes"
for x in kwin-wayland python3-pyqt6 snapper flatpak ufw systemd-zram-generator;do grep -qx "$x" "$pkg"||fail "missing package $x";done
grep -qx 'ID=flexos' config/includes.chroot/etc/os-release||fail "os-release ID"
python3 - <<'PY' || fail "Python/JSON validation"
from pathlib import Path
import json,py_compile
for p in Path("config/includes.chroot/usr/share/flexos").glob("*.json"):json.loads(p.read_text())
for p in [Path("config/includes.chroot/usr/bin/flex"),Path("config/includes.chroot/usr/bin/flex-center"),Path("config/includes.chroot/usr/bin/flex-welcome"),Path("config/includes.chroot/usr/bin/flex-system-report"),Path("config/includes.chroot/usr/lib/flexos/flexlib.py"),Path("config/includes.chroot/usr/lib/flexos/flexsuite.py"),Path("config/includes.chroot/usr/lib/flexos/flex-admin"),Path("config/includes.chroot/usr/lib/flexos/flex-package-profile-install"),Path("config/includes.chroot/usr/lib/flexos/flex-profile-apply")]:py_compile.compile(str(p),doraise=True)
PY
(( errors==0 ))||exit 1
echo "FlexOS source validation passed."
