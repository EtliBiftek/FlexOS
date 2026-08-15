#!/usr/bin/env bash
set -Eeuo pipefail

ISO="${1:-}"
OUT="${2:-release-assets}"
[[ -f "$ISO" ]] || { echo "Usage: $0 <FlexOS.iso> [output-dir]" >&2; exit 2; }
[[ -f "$ISO.sha256" ]] || { echo "ERROR: missing checksum file: $ISO.sha256" >&2; exit 2; }

rm -rf "$OUT"
mkdir -p "$OUT"
base="$(basename "$ISO")"
size="$(stat -c '%s' "$ISO")"
# GitHub Release individual assets must be below 2 GiB. 1800 MiB leaves margin.
part_mib="${FLEXOS_RELEASE_PART_MIB:-1800}"
[[ "$part_mib" =~ ^[0-9]+$ ]] && (( part_mib > 0 )) || { echo "Invalid FLEXOS_RELEASE_PART_MIB" >&2; exit 2; }
limit=$((part_mib * 1024 * 1024))

if (( size <= limit )); then
  cp -f "$ISO" "$OUT/$base"
else
  split -b "${part_mib}M" -d -a 2 "$ISO" "$OUT/$base.part-"
fi

cp -f "$ISO.sha256" "$OUT/$base.sha256"

parts=("$OUT/$base".part-*)
if [[ -e "${parts[0]}" ]]; then
  cmd_join=""
  for p in "${parts[@]}"; do
    name="$(basename "$p")"
    [[ -n "$cmd_join" ]] && cmd_join+="+"
    cmd_join+="\"$name\""
  done
else
  cmd_join="(not needed: ISO is a single asset)"
fi

cat > "$OUT/REASSEMBLE.txt" <<EOF2
FlexOS GitHub Release packaging
===============================

If this release contains a single "$base", use it directly.
If it contains "$base.part-00", "$base.part-01", ... first reconstruct it.

Linux / macOS:
  cat "$base".part-* > "$base"

Windows PowerShell:
  \$parts = Get-ChildItem "$base.part-*" | Sort-Object Name; \$out = [IO.File]::Create("$base"); foreach (\$p in \$parts) { \$b = [IO.File]::ReadAllBytes(\$p.FullName); \$out.Write(\$b, 0, \$b.Length) }; \$out.Close()

Windows cmd.exe:
  copy /b $cmd_join "$base"

Then verify the reconstructed ISO against "$base.sha256".
EOF2

(
  cd "$OUT"
  sha256sum -- * > SHA256SUMS
)

echo "Release assets prepared in: $OUT"
ls -lh "$OUT"
