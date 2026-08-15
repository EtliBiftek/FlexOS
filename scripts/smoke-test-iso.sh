#!/usr/bin/env bash
set -Eeuo pipefail

ISO="${1:-}"

[[ -n "$ISO" && -f "$ISO" ]] || {
    echo "Usage: $0 FlexOS-*.iso" >&2
    exit 2
}

command -v xorriso >/dev/null 2>&1 || {
    echo "xorriso is required" >&2
    exit 1
}

command -v sha256sum >/dev/null 2>&1 || {
    echo "sha256sum is required" >&2
    exit 1
}

# Inspect boot entries.
xorriso \
    -indev "$ISO" \
    -report_el_torito plain \
    >/tmp/flexos-el-torito.txt 2>&1

# Inspect the first levels of the ISO filesystem.
xorriso \
    -indev "$ISO" \
    -sh_style_result on \
    -find / -maxdepth 2 -type f -exec echo -- \
    >/tmp/flexos-iso-files.txt 2>&1

grep -qi 'BIOS' /tmp/flexos-el-torito.txt \
    || echo "WARN: BIOS entry not explicitly detected"

grep -Eqi 'UEFI|EFI' /tmp/flexos-el-torito.txt \
    || echo "WARN: EFI entry not explicitly detected"

echo
echo "ISO SHA256:"
sha256sum "$ISO"

echo
echo "ISO structural smoke test passed."
