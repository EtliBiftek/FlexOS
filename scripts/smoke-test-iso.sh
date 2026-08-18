#!/usr/bin/env bash
set -Eeuo pipefail

ISO="${1:-}"
[[ -n "$ISO" && -f "$ISO" ]] || { echo "Usage: $0 FlexOS-*.iso" >&2; exit 2; }

for cmd in xorriso sha256sum unsquashfs grep; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "$cmd is required" >&2; exit 1; }
done

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

xorriso -indev "$ISO" -report_el_torito plain >"$tmp/el-torito.txt" 2>&1
if ! xorriso -indev "$ISO" -find / -maxdepth 3 -type f -exec lsdl -- >"$tmp/iso-files.txt" 2>&1; then
  echo "ERROR: xorriso failed while listing ISO files:"
  cat "$tmp/iso-files.txt"
  exit 1
fi

grep -qi 'BIOS' "$tmp/el-torito.txt" || { echo "ERROR: BIOS boot entry not detected." >&2; exit 1; }
grep -qi 'UEFI\|EFI' "$tmp/el-torito.txt" || { echo "ERROR: EFI boot entry not detected." >&2; exit 1; }

for required in /live/filesystem.squashfs /live/vmlinuz /live/initrd.img; do
  grep -Fq "$required" "$tmp/iso-files.txt" || {
    echo "ERROR: ISO is missing $required" >&2
    exit 1
  }
done

xorriso -osirrox on -indev "$ISO" -extract /live/filesystem.squashfs "$tmp/filesystem.squashfs" >/dev/null 2>&1

cat_sq() {
  unsquashfs -cat "$tmp/filesystem.squashfs" "${1#/}"
}

cat_sq /etc/os-release >"$tmp/os-release"
grep -qx 'ID=flexos' "$tmp/os-release" || { echo "ERROR: live filesystem identity is not FlexOS." >&2; exit 1; }
grep -q '^BUILD_ID="\\?0.5.0-beta.1' "$tmp/os-release" || { echo "ERROR: unexpected FlexOS beta build ID." >&2; exit 1; }

cat_sq /var/lib/dpkg/status >"$tmp/dpkg-status"
for pkg in flexos-base flexos-branding flexos-center flexos-welcome flexos-tools flexos-calamares flexos-plymouth; do
  grep -q "^Package: $pkg$" "$tmp/dpkg-status" || {
    echo "ERROR: FlexOS component package is not installed in live filesystem: $pkg" >&2
    exit 1
  }
done

# KDE-only invariant.
cat_sq /usr/share/flexos/desktop-profiles.json >"$tmp/desktops.json"
python3 - "$tmp/desktops.json" <<'PY'
import json,sys
d=json.load(open(sys.argv[1],encoding="utf-8"))
assert set(d)=={"kde"}, d
PY

# Alpha regressions that must never return.
cat_sq /boot/grub/themes/flexos/theme.txt >"$tmp/grub-theme.txt"
! grep -q '^terminal-box:' "$tmp/grub-theme.txt" || {
  echo "ERROR: invalid GRUB terminal-box setting returned." >&2
  exit 1
}

cat_sq /usr/share/plymouth/themes/flexos/flexos.script >"$tmp/plymouth.script"
! grep -q 'Image.Text("Starting"' "$tmp/plymouth.script" || {
  echo "ERROR: static Plymouth Starting text returned." >&2
  exit 1
}

for path in \
  /usr/bin/flex-center \
  /usr/bin/flex-welcome \
  /usr/bin/flex-self-update \
  /usr/bin/flex-beta-check \
  /usr/lib/flexos/flex-recovery-console \
  /usr/lib/systemd/system/flexos-recovery.target \
  /etc/grub.d/41_flexos_recovery
do
  unsquashfs -ll "$tmp/filesystem.squashfs" "${path#/}" 2>/dev/null | grep -Fq "${path#/}" || {
    echo "ERROR: live filesystem missing $path" >&2
    exit 1
  }
done

sha256sum "$ISO"
echo "FlexOS ISO structural + live-filesystem smoke test passed."
