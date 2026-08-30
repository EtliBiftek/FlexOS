#!/usr/bin/env bash
set -Eeuo pipefail
BASE='https://raw.githubusercontent.com/CachyOS/linux-cachyos/master'
variants=(default bore bmq deckify eevdf hardened lts rc rt-bore server)
tmp="$(mktemp -d)";trap 'rm -rf "$tmp"' EXIT
for variant in "${variants[@]}"; do
  if [[ "$variant" == default ]]; then dir=linux-cachyos; else dir="linux-cachyos-$variant"; fi
  file="$tmp/$variant.PKGBUILD"
  curl -fsSL --retry 3 "$BASE/$dir/PKGBUILD" -o "$file"
  out="$(env -u CI -u GITHUB_RUN_ID bash -c '
    set -e
    source "$1"
    printf "src=%s pkgver=%s pkgrel=%s scheduler=%s lto=%s hz=%s\n" "$_srcname" "$pkgver" "$pkgrel" "$_cpusched" "$_use_llvm_lto" "$_HZ_ticks"
    found=0
    for item in "${source[@]}"; do
      case "$item" in https://*.tar.gz) found=1;; esac
    done
    [[ "$found" == 1 ]]
  ' bash "$file")"
  [[ "$out" == src=* ]] || { echo "[FAIL] $variant metadata invalid" >&2; exit 1; }
  printf '%-10s %s\n' "$variant" "$out"
done
