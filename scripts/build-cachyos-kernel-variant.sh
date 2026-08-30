#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VARIANT="${1:-default}"
OUT="${2:-$ROOT/dist/kernel-$VARIANT}"
WORK="${FLEXOS_KERNEL_WORKDIR:-$ROOT/.kernel-variant-work/$VARIANT}"
JOBS="${FLEXOS_KERNEL_JOBS:-$(nproc)}"
CPU="${FLEXOS_KERNEL_CPU:-generic}"
LTO_OVERRIDE="${FLEXOS_KERNEL_LTO:-upstream}"
KCFI="${FLEXOS_KERNEL_KCFI:-0}"
AUTOFDO_INSTRUMENT="${FLEXOS_KERNEL_AUTOFDO_INSTRUMENT:-0}"
AUTOFDO_PROFILE="${FLEXOS_KERNEL_AUTOFDO_PROFILE:-}"
PROPELLER_PREFIX="${FLEXOS_KERNEL_PROPELLER_PREFIX:-}"
HZ_OVERRIDE="${FLEXOS_KERNEL_HZ:-}"
PREEMPT_OVERRIDE="${FLEXOS_KERNEL_PREEMPT:-}"
THP_OVERRIDE="${FLEXOS_KERNEL_THP:-}"
CACHY_BASE="https://raw.githubusercontent.com/CachyOS/linux-cachyos/master"
CACHY_SIGNERS=(E18447AC260021D31F3FF6C4C8A2A4774B8B63C4 E8B9AA39F054E30E8290D492C3C4820857F654FE)

case "$VARIANT" in
  default) UPSTREAM_DIR=linux-cachyos; FLAVOUR=flexos-cachy ;;
  bore|bmq|deckify|eevdf|hardened|lts|rc|rt-bore|server) UPSTREAM_DIR="linux-cachyos-$VARIANT"; FLAVOUR="flexos-cachy-$VARIANT" ;;
  *) echo "Unsupported variant: $VARIANT" >&2; exit 2 ;;
esac
case "$CPU" in generic|v3|v4|zen4|native) :;; *) echo "Invalid CPU profile: $CPU" >&2; exit 2;; esac
case "$LTO_OVERRIDE" in upstream|none|thin|full|thin-dist) :;; *) echo "Invalid LTO mode: $LTO_OVERRIDE" >&2; exit 2;; esac
case "$KCFI" in 0|1) :;; *) echo "FLEXOS_KERNEL_KCFI must be 0 or 1" >&2; exit 2;; esac

need(){ command -v "$1" >/dev/null 2>&1 || { echo "ERROR: missing command: $1" >&2; exit 1; }; }
for c in curl tar make patch sha256sum gpg dpkg-deb nproc; do need "$c"; done
[[ "$OUT" = /* ]] || OUT="$ROOT/$OUT"
[[ "$WORK" = /* ]] || WORK="$ROOT/$WORK"
rm -rf "$WORK" "$OUT"; mkdir -p "$WORK" "$OUT"

curl -fsSL "$CACHY_BASE/$UPSTREAM_DIR/PKGBUILD" -o "$WORK/PKGBUILD"
curl -fsSL "$CACHY_BASE/$UPSTREAM_DIR/config" -o "$WORK/config"
PATCH_URLS=()

# Read only declarative PKGBUILD metadata/options. The actual build below remains Debian-native.
mapfile -t META < <(env -u CI -u GITHUB_RUN_ID bash -c '
  set -e
  source "$1"
  printf "SRCNAME=%s\nPKGVER=%s\nPKGREL=%s\nCPUSCHED=%s\nLTO=%s\nHZ=%s\nTICK=%s\nPREEMPT=%s\nTHP=%s\nCACHYCFG=%s\nO3=%s\n" \
    "$_srcname" "$pkgver" "$pkgrel" "$_cpusched" "$_use_llvm_lto" "$_HZ_ticks" "$_tickrate" "$_preempt" "$_hugepage" "$_cachy_config" "$_cc_harder"
  for item in "${source[@]}"; do
    item="${item%%::*}"
    case "$item" in
      https://*.tar.gz) printf "TARBALL=%s\n" "$item" ;;
      https://*.tar.gz.asc) printf "SIGNATURE=%s\n" "$item" ;;
      https://*.patch) printf "PATCH=%s\n" "$item" ;;
    esac
  done
' bash "$WORK/PKGBUILD")

for line in "${META[@]}"; do
  case "$line" in
    SRCNAME=*) SRCNAME=${line#*=};; PKGVER=*) PKGVER=${line#*=};; PKGREL=*) PKGREL=${line#*=};;
    CPUSCHED=*) CPUSCHED=${line#*=};; LTO=*) UPSTREAM_LTO=${line#*=};; HZ=*) UPSTREAM_HZ=${line#*=};;
    TICK=*) TICK=${line#*=};; PREEMPT=*) UPSTREAM_PREEMPT=${line#*=};; THP=*) UPSTREAM_THP=${line#*=};;
    CACHYCFG=*) CACHYCFG=${line#*=};; O3=*) O3=${line#*=};; TARBALL=*) TARBALL_URL=${line#*=};;
    SIGNATURE=*) SIGNATURE_URL=${line#*=};; PATCH=*) PATCH_URLS+=("${line#*=}");;
  esac
done
: "${SRCNAME:?missing source name}" "${PKGVER:?missing pkgver}" "${PKGREL:?missing pkgrel}" "${TARBALL_URL:?missing tarball URL}"
SIGNATURE_URL="${SIGNATURE_URL:-${TARBALL_URL}.asc}"
LTO="$UPSTREAM_LTO"; [[ "$LTO_OVERRIDE" != upstream ]] && LTO="$LTO_OVERRIDE"
HZ="${HZ_OVERRIDE:-$UPSTREAM_HZ}"; PREEMPT="${PREEMPT_OVERRIDE:-$UPSTREAM_PREEMPT}"; THP="${THP_OVERRIDE:-$UPSTREAM_THP}"
case "$HZ" in 100|250|300|500|600|750|1000) :;; *) echo "Invalid HZ: $HZ" >&2; exit 2;; esac
case "$THP" in always|madvise) :;; *) echo "Invalid THP mode: $THP" >&2; exit 2;; esac

archive="$WORK/${TARBALL_URL##*/}"; sig="$archive.asc"
curl -fL --retry 4 --retry-delay 3 "$TARBALL_URL" -o "$archive"
curl -fL --retry 4 --retry-delay 3 "$SIGNATURE_URL" -o "$sig"
export GNUPGHOME="$WORK/gnupg"; install -d -m 0700 "$GNUPGHOME"
for key in "${CACHY_SIGNERS[@]}"; do gpg --batch --keyserver hkps://keyserver.ubuntu.com --recv-keys "$key"; done
verify="$(gpg --batch --status-fd=1 --verify "$sig" "$archive" 2>&1)" || { printf '%s\n' "$verify" >&2; exit 1; }
printf '%s\n' "$verify" | grep -Eq "\[GNUPG:\] VALIDSIG (${CACHY_SIGNERS[0]}|${CACHY_SIGNERS[1]}) " || { echo 'Unapproved kernel source signature' >&2; exit 1; }

tar -xf "$archive" -C "$WORK"
SRC="$WORK/$SRCNAME"; [[ -d "$SRC" ]] || { echo "Missing source directory: $SRC" >&2; exit 1; }
for url in "${PATCH_URLS[@]}"; do
  file="$WORK/${url##*/}"; curl -fL --retry 4 --retry-delay 3 "$url" -o "$file"; patch -d "$SRC" -Np1 < "$file"
done

cd "$SRC"; cp "$WORK/config" .config
cfg=scripts/config; [[ -x "$cfg" ]] || { echo 'scripts/config unavailable' >&2; exit 1; }
$cfg --set-str LOCALVERSION "-$FLAVOUR" -d LOCALVERSION_AUTO
case "$CPU" in
  generic) $cfg -e GENERIC_CPU -d MZEN4 -d X86_NATIVE_CPU --set-val X86_64_VERSION 1;;
  v3) $cfg -e GENERIC_CPU -d MZEN4 -d X86_NATIVE_CPU --set-val X86_64_VERSION 3;;
  v4) $cfg -e GENERIC_CPU -d MZEN4 -d X86_NATIVE_CPU --set-val X86_64_VERSION 4;;
  zen4) $cfg -d GENERIC_CPU -e MZEN4 -d X86_NATIVE_CPU;;
  native) $cfg -d GENERIC_CPU -d MZEN4 -e X86_NATIVE_CPU;;
esac
[[ "$CACHYCFG" == yes ]] && $cfg -e CACHY || true
case "$CPUSCHED" in
  cachyos|bore|hardened) $cfg -e SCHED_BORE;;
  bmq) $cfg -e SCHED_ALT -e SCHED_BMQ;;
  eevdf) $cfg -d SCHED_BORE -d SCHED_ALT;;
  rt) $cfg -e PREEMPT_RT;;
  rt-bore) $cfg -e SCHED_BORE -e PREEMPT_RT;;
  *) echo "Unknown upstream scheduler: $CPUSCHED" >&2; exit 1;;
esac
case "$LTO" in
  none) $cfg -e LTO_NONE -d LTO_CLANG_THIN -d LTO_CLANG_FULL -d LTO_CLANG_THIN_DIST;;
  thin) $cfg -e LTO_CLANG_THIN;; full) $cfg -e LTO_CLANG_FULL;; thin-dist) $cfg -e LTO_CLANG_THIN_DIST;;
esac
[[ "$KCFI" == 1 ]] && $cfg -e ARCH_SUPPORTS_CFI_CLANG -e CFI_CLANG -e CFI_AUTO_DEFAULT || true
$cfg -d HZ_100 -d HZ_250 -d HZ_300 -d HZ_500 -d HZ_600 -d HZ_750 -d HZ_1000 -e "HZ_$HZ" --set-val HZ "$HZ"
case "$TICK" in periodic) $cfg -d NO_HZ_IDLE -d NO_HZ_FULL -d NO_HZ -d NO_HZ_COMMON -e HZ_PERIODIC;; idle) $cfg -d HZ_PERIODIC -d NO_HZ_FULL -e NO_HZ_IDLE -e NO_HZ -e NO_HZ_COMMON;; full) $cfg -d HZ_PERIODIC -d NO_HZ_IDLE -e NO_HZ_FULL -e NO_HZ -e NO_HZ_COMMON -e CONTEXT_TRACKING;; *) echo "Unknown tick mode: $TICK" >&2; exit 1;; esac
if [[ "$CPUSCHED" != rt && "$CPUSCHED" != rt-bore ]]; then
  case "$PREEMPT" in full) $cfg -e PREEMPT -d PREEMPT_LAZY;; lazy) $cfg -d PREEMPT -e PREEMPT_LAZY;; dynamic) $cfg -e PREEMPT_DYNAMIC;; *) echo "Invalid preempt mode: $PREEMPT" >&2; exit 2;; esac
fi
[[ "$O3" == yes ]] && $cfg -d CC_OPTIMIZE_FOR_PERFORMANCE -e CC_OPTIMIZE_FOR_PERFORMANCE_O3 || true
case "$THP" in always) $cfg -d TRANSPARENT_HUGEPAGE_MADVISE -e TRANSPARENT_HUGEPAGE_ALWAYS;; madvise) $cfg -d TRANSPARENT_HUGEPAGE_ALWAYS -e TRANSPARENT_HUGEPAGE_MADVISE;; esac

build_flags=()
if [[ "$LTO" != none || "$KCFI" == 1 || "$AUTOFDO_INSTRUMENT" == 1 || -n "$AUTOFDO_PROFILE" || -n "$PROPELLER_PREFIX" ]]; then need clang; need ld.lld; build_flags+=(LLVM=1 LLVM_IAS=1); fi
if [[ "$AUTOFDO_INSTRUMENT" == 1 || -n "$AUTOFDO_PROFILE" ]]; then $cfg -e AUTOFDO_CLANG; fi
if [[ -n "$AUTOFDO_PROFILE" ]]; then [[ -f "$AUTOFDO_PROFILE" ]] || { echo "AutoFDO profile missing: $AUTOFDO_PROFILE" >&2; exit 2; }; build_flags+=(CLANG_AUTOFDO_PROFILE="$(readlink -f "$AUTOFDO_PROFILE")"); fi
if [[ -n "$PROPELLER_PREFIX" ]]; then [[ -f "${PROPELLER_PREFIX}_cc_profile.txt" && -f "${PROPELLER_PREFIX}_ld_profile.txt" ]] || { echo 'Propeller profile pair missing' >&2; exit 2; }; $cfg -e PROPELLER_CLANG; build_flags+=(CLANG_PROPELLER_PROFILE_PREFIX="$(readlink -f "$PROPELLER_PREFIX")"); fi
if grep -q '^CONFIG_RUST=y' .config && ! command -v rustc >/dev/null 2>&1; then $cfg -d RUST || true; fi

make "${build_flags[@]}" olddefconfig
export KBUILD_BUILD_USER=flexos KBUILD_BUILD_HOST=github-actions
export KDEB_PKGVERSION="${PKGVER}-${PKGREL}flexos1+${VARIANT}"
make -j"$JOBS" "${build_flags[@]}" bindeb-pkg
shopt -s nullglob
images=("$WORK"/linux-image-*.deb); headers=("$WORK"/linux-headers-*.deb); runtime=()
for f in "${images[@]}"; do [[ "$f" == *-dbg_* ]] || runtime+=("$f"); done
(( ${#runtime[@]} )) || { echo 'No runtime kernel image produced' >&2; exit 1; }
cp -f "${runtime[@]}" "$OUT/"; (( ${#headers[@]} )) && cp -f "${headers[@]}" "$OUT/"
cat > "$OUT/KERNEL_INFO" <<META
upstream=CachyOS/linux-cachyos/$UPSTREAM_DIR
upstream_source=$SRCNAME
upstream_pkgver=$PKGVER
upstream_pkgrel=$PKGREL
source_signature=verified
flexos_variant=$VARIANT
flexos_flavour=$FLAVOUR
architecture=amd64
cpu_tuning=$CPU
scheduler=$CPUSCHED
lto=$LTO
kcfi=$KCFI
autofdo=$([[ "$AUTOFDO_INSTRUMENT" == 1 || -n "$AUTOFDO_PROFILE" ]] && echo yes || echo no)
propeller=$([[ -n "$PROPELLER_PREFIX" ]] && echo yes || echo no)
hz=$HZ
tick=$TICK
preempt=$PREEMPT
thp=$THP
build_date=$(date -u +%Y-%m-%dT%H:%M:%SZ)
META
(cd "$OUT" && sha256sum linux-image-*.deb linux-headers-*.deb KERNEL_INFO > SHA256SUMS)
echo "Built FlexOS CachyOS variant '$VARIANT' into $OUT"
