#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
errors=0

fail(){ echo "[FAIL] $*" >&2; errors=$((errors+1)); }
ok(){ echo "[ OK ] $*"; }

required=(
  VERSION build.sh clean.sh README.md LICENSE CHANGELOG.md
  .github/workflows/build-iso.yml .github/workflows/build-packages.yml .github/ISSUE_TEMPLATE/beta-bug-report.yml
  branding/boot-splash.svg config/package-lists/flexos.list.chroot config/includes.chroot/etc/os-release
  config/includes.chroot/usr/bin/flex config/includes.chroot/usr/bin/flex-center config/includes.chroot/usr/bin/flex-welcome
  config/includes.chroot/usr/bin/flex-session-launch config/includes.chroot/usr/bin/flex-self-update config/includes.chroot/usr/bin/flex-system-report
  config/includes.chroot/usr/bin/flex-beta-check config/includes.chroot/usr/bin/flex-hwd config/includes.chroot/usr/bin/flex-mirror
  config/includes.chroot/usr/bin/flex-gaming config/includes.chroot/usr/bin/flex-scx config/includes.chroot/usr/bin/flex-secureboot
  config/includes.chroot/usr/bin/flexos-installer config/includes.chroot/usr/lib/flexos/flexlib.py config/includes.chroot/usr/lib/flexos/flexsuite.py
  config/includes.chroot/usr/lib/flexos/flexui.py config/includes.chroot/usr/lib/flexos/flexcachy.py
  config/includes.chroot/usr/lib/flexos/flex-admin config/includes.chroot/usr/lib/flexos/flex-privileged-session
  config/includes.chroot/usr/lib/flexos/session-bin/pkexec config/includes.chroot/usr/lib/flexos/flex-recovery-console config/includes.chroot/usr/lib/flexos/flex-postinstall
  config/includes.chroot/usr/lib/flexos/flex-desktop-install config/includes.chroot/usr/lib/flexos/flex-hyprdots-install
  config/includes.chroot/usr/lib/systemd/system/flexos-recovery.target config/includes.chroot/usr/lib/systemd/system/flexos-recovery.service
  config/includes.chroot/usr/lib/systemd/system/flexos-ci-smoke.service config/includes.chroot/etc/grub.d/41_flexos_recovery
  config/includes.chroot/usr/share/flexos/apps.json config/includes.chroot/usr/share/flexos/identity.json
  config/includes.chroot/usr/share/flexos/desktop-profiles.json config/includes.chroot/usr/share/flexos/package-profiles.json
  config/includes.chroot/usr/share/flexos/calamares/branding/branding.desc config/includes.chroot/usr/share/flexos/calamares/branding/stylesheet.qss
  config/includes.chroot/usr/share/flexos/calamares/branding/welcome.svg config/includes.chroot/usr/share/flexos/calamares/branding/show.qml
  config/includes.chroot/usr/share/flexos/calamares/branding/hyprdots.qml
  config/includes.chroot/usr/share/flexos/calamares/modules/packagechooser-desktop.conf
  config/includes.chroot/usr/share/flexos/calamares/modules/packagechooser-hyprdots.conf
  config/includes.chroot/usr/share/flexos/calamares/modules/contextualprocess-flexdesktop.conf
  config/includes.chroot/usr/share/flexos/calamares/modules/contextualprocess-hyprdots.conf
  config/includes.chroot/usr/share/flexos/calamares/modules/packagechooser-flexpackages.conf
  config/includes.chroot/usr/share/flexos/calamares/modules/shellprocess-flexpostinstall.conf
  config/hooks/live/010-flexos-branding.hook.chroot config/hooks/live/020-flexos-calamares.hook.chroot config/hooks/live/030-flexos-services.hook.chroot
  packages/package-map.json scripts/build-flexos-packages.py scripts/build-apt-repo.sh scripts/version-to-deb.py scripts/qemu-boot-smoke.sh scripts/beta-gate.py
  qa/test-matrix.json qa/record-test.py qa/test-userland-security.py docs/BETA_EXIT_CRITERIA.md docs/BETA_TEST_MATRIX.md docs/RECOVERY.md docs/UPDATES.md
)
for f in "${required[@]}"; do [[ -e "$f" ]] || fail "Missing $f"; done
[[ $errors -eq 0 ]] && ok "required beta project files"

nested_workflows="$(find .github/workflows -mindepth 2 -type f \( -name '*.yml' -o -name '*.yaml' \) -print 2>/dev/null || true)"
[[ -z "$nested_workflows" ]] && ok "GitHub workflow layout" || fail "GitHub ignores nested workflow files; move them directly under .github/workflows/: $nested_workflows"
[[ ! -d .github/workflows/ISSUE_TEMPLATE ]] && ok "GitHub issue template layout" || fail "Issue templates must live under .github/ISSUE_TEMPLATE, not .github/workflows/ISSUE_TEMPLATE"

for f in build.sh clean.sh scripts/*.sh config/hooks/live/*.hook.chroot config/includes.chroot/usr/bin/flexos-installer config/includes.chroot/usr/lib/flexos/flexos-first-login config/includes.chroot/usr/lib/flexos/flex-identity-apply config/includes.chroot/usr/lib/flexos/flex-snapshot-pre config/includes.chroot/usr/lib/flexos/flex-recovery-console config/includes.chroot/etc/grub.d/41_flexos_recovery; do
  [[ -f "$f" ]] || continue; bash -n "$f" || fail "shell syntax: $f"
done
[[ $errors -eq 0 ]] && ok "shell syntax"

pkg="config/package-lists/flexos.list.chroot"
if [[ -f "$pkg" ]]; then
  dupes="$(grep -Ev '^\s*(#|$)' "$pkg" | sort | uniq -d || true)"; [[ -z "$dupes" ]] || fail "duplicate packages: $dupes"
  for name in kwin-wayland python3-pyqt6 snapper flatpak ufw systemd-zram-generator whiptail cracklib-runtime; do grep -qx "$name" "$pkg" || fail "missing required package: $name"; done
  grep -qx 'plasma-workspace-wayland' "$pkg" && fail "obsolete plasma-workspace-wayland package" || true
  [[ -z "$dupes" ]] && ok "package list"
fi

python3 - <<'PY' || fail "structured beta validation"
from pathlib import Path
import configparser,json,py_compile,re,xml.etree.ElementTree as ET
version=Path("VERSION").read_text().strip()
assert re.fullmatch(r"\d+\.\d+(?:\.\d+)?(?:[-+][0-9A-Za-z.-]+)?",version), f"Unexpected FlexOS VERSION: {version}"
for p in Path("config/includes.chroot/usr/share/flexos").glob("*.json"): json.loads(p.read_text(encoding="utf-8"))
matrix=json.loads(Path("qa/test-matrix.json").read_text(encoding="utf-8")); assert isinstance(matrix.get("release"),str) and matrix["release"]; assert len({t["id"] for t in matrix["tests"]})==len(matrix["tests"])
desktop=json.loads(Path("config/includes.chroot/usr/share/flexos/desktop-profiles.json").read_text()); assert set(desktop)=={"kde","gnome","hyprland"}, "FlexOS desktop profiles must include KDE, GNOME and Hyprland"
identity=json.loads(Path("config/includes.chroot/usr/share/flexos/identity.json").read_text()); assert identity["build_id"]==version
osr=Path("config/includes.chroot/etc/os-release").read_text(); assert "ID=flexos" in osr; assert f'BUILD_ID="{version}"' in osr
local_validation=json.loads(Path("LOCAL_VALIDATION.json").read_text(encoding="utf-8")); assert local_validation.get("source_version")==version, "LOCAL_VALIDATION source_version must match VERSION"
assert matrix.get("release")==version, "QA test matrix release must match VERSION"
pkgmap=json.loads(Path("packages/package-map.json").read_text())
for name,spec in pkgmap.items():
    for rel in spec["paths"]: assert (Path("config/includes.chroot")/rel).exists(), f"{name}: package source path missing: {rel}"
roots=[Path("config/includes.chroot/usr/bin"),Path("config/includes.chroot/usr/lib/flexos"),Path("scripts"),Path("qa")]
pyfiles=[]
for root in roots:
    for p in root.rglob("*"):
        if not p.is_file():continue
        if any("kernel" in part.lower() for part in p.parts):continue
        try:head=p.read_bytes()[:80]
        except OSError:continue
        first=head.splitlines()[0] if head else b""
        if p.suffix==".py" or b"python3" in first:
            pyfiles.append(p)
for p in sorted(set(pyfiles)):py_compile.compile(str(p),doraise=True)
for p in Path("branding").rglob("*.svg"): ET.parse(p)
for p in Path("config/includes.chroot/usr/share").rglob("*.svg"): ET.parse(p)
for p in Path("config/includes.chroot/usr/share/applications").glob("*.desktop"):
    cp=configparser.ConfigParser(interpolation=None,strict=False); cp.optionxform=str; cp.read(p,encoding="utf-8"); assert "Desktop Entry" in cp; assert cp["Desktop Entry"].get("Type"); assert cp["Desktop Entry"].get("Name")
branding=Path("config/includes.chroot/usr/share/flexos/calamares/branding/branding.desc").read_text()
assert 'slideshow:' in branding and 'slideshowAPI:' in branding
assert 'sidebar: widget,left' in branding, "Calamares installer must keep the clean vertical progress sidebar"
assert 'navigation: widget,bottom' in branding, "Calamares navigation must remain at the bottom"
stylesheet=Path("config/includes.chroot/usr/share/flexos/calamares/branding/stylesheet.qss").read_text(); assert '#sidebarApp' in stylesheet and 'QPushButton:default' in stylesheet
assert "terminal-box:" not in Path("config/includes.chroot/boot/grub/themes/flexos/theme.txt").read_text()
assert 'Image.Text("Starting"' not in Path("config/includes.chroot/usr/share/plymouth/themes/flexos/flexos.script").read_text()
hook=Path("config/hooks/live/020-flexos-calamares.hook.chroot").read_text()
for token in ("packagechooser@desktop","packagechooserq@hyprdots","contextualprocess@flexdesktop","contextualprocess@flexhyprdots","shellprocess@flexpostinstall","availableFileSystemTypes","stylesheet.qss"):
    assert token in hook, f"Calamares hook missing {token}"
dots=Path("config/includes.chroot/usr/share/flexos/calamares/branding/hyprdots.qml").read_text()
assert "pctrade" in dots and "end-4" in dots and "screenshots/" in dots and "model: 6" in dots
print(f"structured validation OK ({len(pyfiles)} userland Python files compiled; kernel paths excluded)")
PY
[[ $errors -eq 0 ]] && ok "Python / JSON / SVG / desktop / beta invariants"

python3 qa/test-userland-security.py || fail "userland security regressions"
[[ $errors -eq 0 ]] && ok "userland security regressions"

if command -v python3 >/dev/null 2>&1; then
python3 - <<'PY' || fail "YAML validation"
from pathlib import Path
try: import yaml
except Exception: raise SystemExit(0)
paths=list(Path(".github/workflows").glob("*.yml"))+list(Path(".github/workflows").glob("*.yaml"))+list(Path(".github/ISSUE_TEMPLATE").glob("*.yml"))+list(Path(".github/ISSUE_TEMPLATE").glob("*.yaml"))+list(Path("config/includes.chroot/usr/share/flexos/calamares/modules").glob("*.conf"))+[Path("config/includes.chroot/usr/share/flexos/calamares/branding/branding.desc")]
for p in paths: yaml.safe_load(p.read_text(encoding="utf-8"))
PY
fi
if grep -RIl $'\r' --exclude='*.png' --exclude='*.jpg' --exclude='*.zip' --exclude='*.deb' . >/dev/null 2>&1; then fail "CRLF line endings detected"; else ok "LF line endings"; fi
if (( errors )); then echo "Validation failed with $errors error(s)." >&2; exit 1; fi
echo "FlexOS source validation passed for $(cat VERSION)."
