#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

VERSION="$(tr -d '[:space:]' < VERSION)"
OUTPUT="FlexOS-${VERSION}-amd64.iso"

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  echo "ERROR: FlexOS build must run as root (use sudo)." >&2
  exit 1
fi

for cmd in lb sha256sum find cp python3 dpkg-deb; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "ERROR: Missing build command: $cmd" >&2; exit 1; }
done

./scripts/validate.sh
./scripts/validate-cachyos-stack.sh

version_args=( "$VERSION" )
if [[ -n "${GITHUB_COMMIT_EPOCH:-}" ]]; then version_args+=( --epoch "$GITHUB_COMMIT_EPOCH" );
elif [[ -n "${GITHUB_RUN_NUMBER:-}" ]]; then version_args+=( --ci-run "$GITHUB_RUN_NUMBER" );fi
[[ -n "${GITHUB_SHA:-}" ]] && version_args+=( --sha "$GITHUB_SHA" )
PACKAGE_VERSION="$(python3 scripts/version-to-deb.py "${version_args[@]}")"
COMPONENT_BASE_URL="https://github.com/${GITHUB_REPOSITORY:-EtliBiftek/FlexOS}/releases/download/packages-latest"

rm -rf config/packages.chroot
mkdir -p config/packages.chroot
python3 scripts/build-flexos-packages.py --output config/packages.chroot --package-version "$PACKAGE_VERSION" --product-version "$VERSION" --base-url "$COMPONENT_BASE_URL" --channel beta
echo "FlexOS component package version embedded in ISO: $PACKAGE_VERSION"

has_runtime_cachy_kernel() {
  [[ -d dist/kernel ]] && find dist/kernel -maxdepth 1 -type f -name 'linux-image-*.deb' ! -name '*-dbg_*' -print -quit 2>/dev/null | grep -q .
}

if ! has_runtime_cachy_kernel && [[ "${FLEXOS_FETCH_CACHY_KERNEL:-1}" != "0" ]]; then
  python3 scripts/fetch-cachyos-kernel.py dist/kernel || true
fi

if [[ -f dist/kernel/SHA256SUMS ]]; then (cd dist/kernel && sha256sum -c SHA256SUMS);fi

CACHY_KERNEL=0
mapfile -t CACHY_IMAGES < <(find dist/kernel -maxdepth 1 -type f -name 'linux-image-*.deb' ! -name '*-dbg_*' -print 2>/dev/null | sort || true)
mapfile -t CACHY_HEADERS < <(find dist/kernel -maxdepth 1 -type f -name 'linux-headers-*.deb' -print 2>/dev/null | sort || true)
if (( ${#CACHY_IMAGES[@]} > 0 )); then
  cp -f "${CACHY_IMAGES[@]}" config/packages.chroot/
  if (( ${#CACHY_HEADERS[@]} > 0 )); then cp -f "${CACHY_HEADERS[@]}" config/packages.chroot/;fi
  CACHY_KERNEL=1
  echo "CachyOS-derived FlexOS runtime kernel packages embedded in ISO (debug packages excluded)."
elif [[ "${FLEXOS_REQUIRE_CACHY_KERNEL:-0}" == "1" ]]; then
  echo "ERROR: FLEXOS_REQUIRE_CACHY_KERNEL=1 but dist/kernel has no runtime kernel package." >&2;exit 1
else
  echo "WARNING: no CachyOS-derived kernel artifact found; using Debian kernel only." >&2
fi

lb clean --purge || true
rm -rf config/binary config/bootstrap config/bootloaders config/chroot config/common config/source
rm -f FlexOS-*.iso FlexOS-*.iso.sha256 build.log

linux_args=(--linux-flavours amd64)
if [[ "$CACHY_KERNEL" == "1" ]]; then linux_args=(--linux-flavours flexos-cachy --linux-packages none);fi

lb config noauto \
  --mode debian \
  --distribution trixie \
  --architectures amd64 \
  "${linux_args[@]}" \
  --binary-images iso-hybrid \
  --bootloaders "syslinux grub-efi" \
  --archive-areas "main contrib non-free non-free-firmware" \
  --apt-recommends false \
  --cache false \
  --apt-source-archives false \
  --debian-installer none \
  --memtest memtest86+ \
  --checksums sha256 \
  --chroot-squashfs-compression-type xz \
  --bootappend-live "boot=live components username=flex hostname=flexos user-fullname=FlexOS locales=en_US.UTF-8 keyboard-layouts=us quiet splash" \
  --bootappend-live-failsafe "boot=live components username=flex hostname=flexos user-fullname=FlexOS noapic noapm nodma nomce nolapic nomodeset nosmp nosplash vga=normal" \
  --iso-application "FlexOS ${VERSION}" \
  --iso-preparer "FlexOS Build System" \
  --iso-publisher "Pifo; https://github.com/EtliBiftek/FlexOS" \
  --iso-volume "FLEXOS_$(echo "$VERSION" | tr '.-' '__' | tr '[:lower:]' '[:upper:]')"

if [[ -d /usr/share/live/build/bootloaders ]]; then
  cp -a /usr/share/live/build/bootloaders config/bootloaders
  while IFS= read -r -d '' splash; do cp -f branding/boot-splash.svg "$splash";done < <(find config/bootloaders -type f -name 'splash.svg' -print0)
  while IFS= read -r -d '' f; do
    sed -i -e 's/Debian GNU\/Linux/FlexOS/g' -e 's/Debian Live/FlexOS Live/g' -e 's/Debian GNU/FlexOS/g' "$f" || true
  done < <(find config/bootloaders -type f \( -name '*.cfg' -o -name '*.conf' -o -name '*.txt' \) -print0)
fi

lb build 2>&1 | tee build.log
iso="$(find . -maxdepth 1 -type f \( -name 'live-image-amd64.hybrid.iso' -o -name 'live-image-amd64.iso' -o -name '*.hybrid.iso' -o -name '*.iso' \) -print -quit)"
[[ -n "$iso" ]] || { echo "ERROR: live-build completed but no ISO was found." >&2;exit 1; }
mv "$iso" "$OUTPUT"
sha256sum "$OUTPUT" > "$OUTPUT.sha256"
printf '\nBuilt: %s\nChecksum: %s.sha256\nEmbedded FlexOS components: %s\nCachyOS-derived kernel: %s\n' "$OUTPUT" "$OUTPUT" "$PACKAGE_VERSION" "$CACHY_KERNEL"
