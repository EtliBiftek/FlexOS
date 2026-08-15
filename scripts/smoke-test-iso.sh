#!/usr/bin/env bash
set -Eeuo pipefail
ISO="${1:-}"
[[ -n "$ISO" && -f "$ISO" ]] || { echo "Usage: $0 FlexOS-*.iso" >&2; exit 2; }

command -v xorriso >/dev/null 2>&1 || { echo "xorriso is required" >&2; exit 1; }
command -v sha256sum >/dev/null 2>&1 || { echo "sha256sum is required" >&2; exit 1; }

xorriso -indev "$ISO" -report_el_torito plain >/tmp/flexos-el-torito.txt 2>&1
xorriso -indev "$ISO" -find / -maxdepth 2 -type f -print >/tmp/flexos-iso-files.txt 2>&1

grep -qi 'BIOS' /tmp/flexos-el-torito.txt || echo "WARN: BIOS entry not explicitly detected"
grep -qi 'UEFI\|EFI' /tmp/flexos-el-torito.txt || echo "WARN: EFI entry not explicitly detected"
sha256sum "$ISO"
echo "ISO structural smoke test passed."
