#!/usr/bin/env bash
set -Eeuo pipefail

ISO="${1:-}"
[[ -n "$ISO" && -f "$ISO" ]] || {
  echo "Usage: $0 FlexOS-*.iso" >&2
  exit 2
}

for cmd in xorriso sha256sum unsquashfs grep python3; do
  command -v "$cmd" >/dev/null 2>&1 || {
    echo "$cmd is required" >&2
    exit 1
  }
done

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

if ! xorriso -indev "$ISO" -report_el_torito plain >"$tmp/el-torito.txt" 2>&1; then
  echo "ERROR: xorriso failed while inspecting boot entries:" >&2
  cat "$tmp/el-torito.txt" >&2
  exit 1
fi

if ! xorriso -indev "$ISO" \
  -find / -maxdepth 3 -type f -exec lsdl -- \
  >"$tmp/iso-files.txt" 2>&1; then
  echo "ERROR: xorriso failed while listing ISO files:" >&2
  cat "$tmp/iso-files.txt" >&2
  exit 1
fi

grep -qi 'BIOS' "$tmp/el-torito.txt" || {
  echo "ERROR: BIOS boot entry not detected." >&2
  exit 1
}

grep -Eqi 'UEFI|EFI' "$tmp/el-torito.txt" || {
  echo "ERROR: EFI boot entry not detected." >&2
  exit 1
}

for required in \
  /live/filesystem.squashfs \
  /live/vmlinuz \
  /live/initrd.img
do
  grep -Fq "$required" "$tmp/iso-files.txt" || {
    echo "ERROR: ISO is missing $required" >&2
    exit 1
  }
done

if ! xorriso \
  -osirrox on \
  -indev "$ISO" \
  -extract /live/filesystem.squashfs "$tmp/filesystem.squashfs" \
  >"$tmp/extract.txt" 2>&1; then
  echo "ERROR: failed to extract live filesystem from ISO:" >&2
  cat "$tmp/extract.txt" >&2
  exit 1
fi

cat_sq() {
  unsquashfs -cat "$tmp/filesystem.squashfs" "${1#/}"
}

cat_sq /etc/os-release >"$tmp/os-release"

grep -qx 'ID=flexos' "$tmp/os-release" || {
  echo "ERROR: live filesystem identity is not FlexOS." >&2
  echo "Detected /etc/os-release:" >&2
  cat "$tmp/os-release" >&2
  exit 1
}

grep -qx 'BUILD_ID="0\.5\.0-beta\.1-dev"' "$tmp/os-release" || {
  echo "ERROR: unexpected FlexOS beta build ID." >&2
  echo "Detected BUILD_ID:" >&2
  grep '^BUILD_ID=' "$tmp/os-release" >&2 || true
  exit 1
}

cat_sq /var/lib/dpkg/status >"$tmp/dpkg-status"

for pkg in \
  flexos-base \
  flexos-branding \
  flexos-center \
  flexos-welcome \
  flexos-tools \
  flexos-calamares \
  flexos-plymouth
do
  grep -q "^Package: $pkg$" "$tmp/dpkg-status" || {
    echo "ERROR: FlexOS component package is not installed in live filesystem: $pkg" >&2
    exit 1
  }
done

# KDE-only invariant.
cat_sq /usr/share/flexos/desktop-profiles.json >"$tmp/desktops.json"

python3 - "$tmp/desktops.json" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as f:
    data = json.load(f)

assert set(data) == {"kde"}, data
PY

# Alpha regressions that must never return.
cat_sq /boot/grub/themes/flexos/theme.txt >"$tmp/grub-theme.txt"

if grep -q '^terminal-box:' "$tmp/grub-theme.txt"; then
  echo "ERROR: invalid GRUB terminal-box setting returned." >&2
  exit 1
fi

cat_sq /usr/share/plymouth/themes/flexos/flexos.script >"$tmp/plymouth.script"

if grep -q 'Image.Text("Starting"' "$tmp/plymouth.script"; then
  echo "ERROR: static Plymouth Starting text returned." >&2
  exit 1
fi

for path in \
  /usr/bin/flex-center \
  /usr/bin/flex-welcome \
  /usr/bin/flex-self-update \
  /usr/bin/flex-beta-check \
  /usr/lib/flexos/flex-recovery-console \
  /usr/lib/systemd/system/flexos-recovery.target \
  /etc/grub.d/41_flexos_recovery
do
  if ! unsquashfs \
    -ll "$tmp/filesystem.squashfs" \
    "${path#/}" 2>/dev/null |
    grep -Fq "${path#/}"
  then
    echo "ERROR: live filesystem missing $path" >&2
    exit 1
  fi
done

sha256sum "$ISO"

echo "FlexOS ISO structural + live-filesystem smoke test passed."
