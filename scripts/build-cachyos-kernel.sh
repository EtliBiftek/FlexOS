#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${1:-$ROOT/dist/kernel}"
WORK="${FLEXOS_KERNEL_WORKDIR:-$ROOT/.kernel-work}"
JOBS="${FLEXOS_KERNEL_JOBS:-$(nproc)}"
PKGBUILD_URL="https://raw.githubusercontent.com/CachyOS/linux-cachyos/master/linux-cachyos/PKGBUILD"
CONFIG_URL="https://raw.githubusercontent.com/CachyOS/linux-cachyos/master/linux-cachyos/config"
CACHY_SIGNERS=(
  E18447AC260021D31F3FF6C4C8A2A4774B8B63C4
  E8B9AA39F054E30E8290D492C3C4820857F654FE
)

need(){ command -v "$1" >/dev/null 2>&1 || { echo "ERROR: missing command: $1" >&2; exit 1; }; }
for cmd in curl tar make dpkg-deb sha256sum sed grep awk nproc; do need "$cmd"; done

rm -rf "$WORK" "$OUT"
mkdir -p "$WORK" "$OUT"

curl -fsSL "$PKGBUILD_URL" -o "$WORK/PKGBUILD"
curl -fsSL "$CONFIG_URL" -o "$WORK/config"

read_var(){
  local key="$1" value
  value="$(sed -nE "s/^${key}=([^#]+).*/\\1/p" "$WORK/PKGBUILD" | head -n1 | tr -d '"[:space:]')"
  [[ -n "$value" ]] || { echo "ERROR: unable to read ${key} from CachyOS PKGBUILD" >&2; exit 1; }
  printf '%s' "$value"
}

major="$(read_var _major)"
minor="$(read_var _minor)"
tagrel="$(read_var _tagrel)"
pkgrel="$(read_var pkgrel)"
pkgver="${major}.${minor}"
srcname="cachyos-${pkgver}-${tagrel}"
tarball="$WORK/${srcname}.tar.gz"
sigfile="$tarball.asc"
source_url="https://github.com/CachyOS/linux/releases/download/${srcname}/${srcname}.tar.gz"

printf 'CachyOS source: %s\n' "$srcname"
printf 'Downloading: %s\n' "$source_url"
curl -fL --retry 4 --retry-delay 3 "$source_url" -o "$tarball"

signature_status=skipped
if [[ "${FLEXOS_KERNEL_VERIFY_SIGNATURES:-1}" == "1" ]]; then
  need gpg
  curl -fL --retry 4 --retry-delay 3 "${source_url}.asc" -o "$sigfile"
  export GNUPGHOME="$WORK/gnupg"
  install -d -m 0700 "$GNUPGHOME"
  for key in "${CACHY_SIGNERS[@]}"; do
    gpg --batch --keyserver hkps://keyserver.ubuntu.com --recv-keys "$key"
  done
  verify_status="$(gpg --batch --status-fd=1 --verify "$sigfile" "$tarball" 2>&1)" || {
    printf '%s\n' "$verify_status" >&2
    echo 'ERROR: CachyOS kernel source signature verification failed.' >&2
    exit 1
  }
  if ! printf '%s\n' "$verify_status" | grep -Eq "\[GNUPG:\] VALIDSIG (${CACHY_SIGNERS[0]}|${CACHY_SIGNERS[1]}) "; then
    printf '%s\n' "$verify_status" >&2
    echo 'ERROR: kernel archive was not signed by an approved CachyOS maintainer key.' >&2
    exit 1
  fi
  signature_status=verified
fi

tar -xf "$tarball" -C "$WORK"

SRC="$WORK/$srcname"
[[ -d "$SRC" ]] || { echo "ERROR: expected kernel source directory not found: $SRC" >&2; exit 1; }
cd "$SRC"
cp "$WORK/config" .config

# FlexOS ships one portable ISO. Do not inherit CachyOS' per-machine native CPU
# optimization from the Arch PKGBUILD; keep the upstream config generic instead.
if [[ -x scripts/config ]]; then
  scripts/config -d X86_NATIVE_CPU || true
  scripts/config -d MZEN4 || true
  scripts/config -e GENERIC_CPU || true
  scripts/config -e CACHY || true
  scripts/config -e SCHED_BORE || true
  scripts/config --set-str LOCALVERSION "-flexos-cachy"
  scripts/config -d LOCALVERSION_AUTO
fi

# Rust support in a very new kernel can require a newer toolchain than Debian 13
# currently provides. Keep the kernel buildable and portable rather than failing
# the whole distribution build over optional Rust drivers.
if grep -q '^CONFIG_RUST=y' .config; then
  if ! command -v rustc >/dev/null 2>&1; then
    scripts/config -d RUST || true
  fi
fi

build_flags=()
if command -v clang >/dev/null 2>&1 && command -v ld.lld >/dev/null 2>&1; then
  build_flags+=(LLVM=1 LLVM_IAS=1)
fi

make "${build_flags[@]}" olddefconfig

# Keep the result explicitly branded as FlexOS while preserving CachyOS source
# provenance in the metadata file shipped next to the packages.
export KBUILD_BUILD_USER=flexos
export KBUILD_BUILD_HOST=github-actions
export KDEB_PKGVERSION="${pkgver}-${pkgrel}flexos1"

make -j"$JOBS" "${build_flags[@]}" bindeb-pkg

shopt -s nullglob
images=("$WORK"/linux-image-*.deb)
headers=("$WORK"/linux-headers-*.deb)
if (( ${#images[@]} == 0 )); then
  echo "ERROR: kernel build produced no linux-image .deb" >&2
  exit 1
fi

cp -f "${images[@]}" "$OUT/"
if (( ${#headers[@]} )); then cp -f "${headers[@]}" "$OUT/"; fi

cat > "$OUT/KERNEL_INFO" <<EOF
upstream=CachyOS/linux-cachyos
upstream_source=${srcname}
upstream_pkgver=${pkgver}
upstream_pkgrel=${pkgrel}
source_signature=${signature_status}
flexos_localversion=-flexos-cachy
architecture=amd64
cpu_tuning=generic
build_compiler=$(if (( ${#build_flags[@]} )); then echo llvm; else echo gcc; fi)
build_date=$(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF

(
  cd "$OUT"
  sha256sum linux-*.deb KERNEL_INFO > SHA256SUMS
)

printf '\nBuilt FlexOS CachyOS-derived kernel packages:\n'
find "$OUT" -maxdepth 1 -type f -printf '  %f\n' | sort
