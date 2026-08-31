#!/usr/bin/env bash
set -Eeuo pipefail

ISO="${1:-}"
[[ -n "$ISO" && -f "$ISO" ]] || {
  echo "Usage: $0 FlexOS-*.iso" >&2
  exit 2
}

for cmd in xorriso sha256sum unsquashfs grep python3 cmp; do
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

# Extracting by exact ISO path avoids false positives such as treating
# initrd.img-<version> as if the generic /live/initrd.img alias existed.
extract_iso_file() {
  local path="$1" output="$2"
  rm -f "$output"
  if ! xorriso \
    -osirrox on \
    -indev "$ISO" \
    -extract "$path" "$output" \
    >"$tmp/extract-$(basename "$output").txt" 2>&1; then
    echo "ERROR: ISO is missing or cannot extract $path" >&2
    cat "$tmp/extract-$(basename "$output").txt" >&2
    return 1
  fi
  if [[ ! -s "$output" ]]; then
    echo "ERROR: ISO file is empty: $path" >&2
    return 1
  fi
}

extract_iso_file /live/filesystem.squashfs "$tmp/filesystem.squashfs"
extract_iso_file /live/vmlinuz "$tmp/vmlinuz-generic"
extract_iso_file /live/initrd.img "$tmp/initrd-generic"

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

expected_build_id="$(tr -d '\r\n' < VERSION)"
detected_build_id="$(sed -n 's/^BUILD_ID="\(.*\)"$/\1/p' "$tmp/os-release")"
if [[ "$detected_build_id" != "$expected_build_id" ]]; then
  echo "ERROR: unexpected FlexOS build ID." >&2
  echo "Expected BUILD_ID: $expected_build_id" >&2
  echo "Detected BUILD_ID: ${detected_build_id:-<missing>}" >&2
  exit 1
fi

cat_sq /var/lib/dpkg/status >"$tmp/dpkg-status"

for pkg in \
  flexos-base \
  flexos-branding \
  flexos-center \
  flexos-welcome \
  flexos-tools \
  flexos-performance \
  flexos-gaming \
  flexos-calamares \
  flexos-plymouth
do
  grep -q "^Package: $pkg$" "$tmp/dpkg-status" || {
    echo "ERROR: FlexOS component package is not installed in live filesystem: $pkg" >&2
    exit 1
  }
done

if ! grep -Eq '^Package: linux-image-[^[:space:]]*flexos-cachy' "$tmp/dpkg-status"; then
  echo "ERROR: live filesystem does not contain a FlexOS CachyOS-derived runtime kernel package." >&2
  exit 1
fi

if ! grep -Eq '^Package: linux-headers-[^[:space:]]*flexos-cachy' "$tmp/dpkg-status"; then
  echo "ERROR: live filesystem does not contain matching FlexOS CachyOS kernel headers." >&2
  exit 1
fi

grep -q '^Package: linux-image-amd64$' "$tmp/dpkg-status" || {
  echo "ERROR: Debian fallback kernel meta-package is missing from the live filesystem." >&2
  exit 1
}

# GRUB uses the versioned pair while Syslinux uses the generic aliases. Verify
# both point to the exact same FlexOS kernel/initramfs so a structurally valid
# ISO cannot hide a missing or mismatched custom initrd.
custom_kernel_pkg="$(grep -Em1 '^Package: linux-image-[0-9][^[:space:]]*-flexos-cachy$' "$tmp/dpkg-status" | cut -d' ' -f2 || true)"
if [[ -z "$custom_kernel_pkg" ]]; then
  echo "ERROR: unable to identify the versioned FlexOS CachyOS kernel package." >&2
  exit 1
fi
custom_kernel_version="${custom_kernel_pkg#linux-image-}"

extract_iso_file "/live/vmlinuz-${custom_kernel_version}" "$tmp/vmlinuz-custom"
extract_iso_file "/live/initrd.img-${custom_kernel_version}" "$tmp/initrd-custom"

cmp -s "$tmp/vmlinuz-generic" "$tmp/vmlinuz-custom" || {
  echo "ERROR: /live/vmlinuz does not match vmlinuz-${custom_kernel_version}." >&2
  exit 1
}

cmp -s "$tmp/initrd-generic" "$tmp/initrd-custom" || {
  echo "ERROR: /live/initrd.img does not match initrd.img-${custom_kernel_version}." >&2
  exit 1
}

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
  /usr/bin/flex-scx \
  /usr/bin/flex-gaming \
  /usr/bin/flex-hwd \
  /usr/bin/flex-kernel-manager \
  /usr/bin/flex-secureboot \
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

echo "FlexOS ISO structural + version-matched CachyOS-kernel/initramfs smoke test passed."