#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"
VERSION="$(tr -d '[:space:]' < VERSION)"
OUTPUT="FlexOS-${VERSION}-amd64.iso"
if [[ ${EUID:-$(id -u)} -ne 0 ]]; then echo "ERROR: FlexOS build must run as root." >&2; exit 1; fi
for cmd in lb sha256sum find cp; do command -v "$cmd" >/dev/null 2>&1 || { echo "ERROR: Missing $cmd" >&2; exit 1; }; done
./scripts/validate.sh
lb clean --purge || true
rm -rf config/binary config/bootstrap config/bootloaders config/chroot config/common config/source
rm -f FlexOS-*.iso FlexOS-*.iso.sha256 build.log
lb config noauto \
  --mode debian --distribution trixie --architectures amd64 --linux-flavours amd64 \
  --binary-images iso-hybrid --bootloaders "syslinux grub-efi" \
  --archive-areas "main contrib non-free non-free-firmware" \
  --apt-recommends false --cache false --apt-source-archives false \
  --debian-installer none --memtest memtest86+ --checksums sha256 \
  --chroot-squashfs-compression-type xz \
  --bootappend-live "boot=live components username=flex hostname=flexos user-fullname=FlexOS locales=en_US.UTF-8 keyboard-layouts=us quiet splash" \
  --bootappend-live-failsafe "boot=live components username=flex hostname=flexos user-fullname=FlexOS noapic noapm nodma nomce nolapic nomodeset nosmp nosplash vga=normal" \
  --iso-application "FlexOS ${VERSION}" --iso-preparer "FlexOS Build System" \
  --iso-publisher "Pifo; https://github.com/EtliBiftek/FlexOS" \
  --iso-volume "FLEXOS_$(echo "$VERSION" | tr '.-' '__' | tr '[:lower:]' '[:upper:]')"
if [[ -d /usr/share/live/build/bootloaders ]]; then
  cp -a /usr/share/live/build/bootloaders config/bootloaders
  while IFS= read -r -d '' splash; do cp -f branding/boot-splash.svg "$splash"; done < <(find config/bootloaders -type f -name 'splash.svg' -print0)
  while IFS= read -r -d '' f; do
    sed -i -e 's/Debian GNU\/Linux/FlexOS/g' -e 's/Debian Live/FlexOS Live/g' -e 's/Debian GNU/FlexOS/g' "$f" || true
  done < <(find config/bootloaders -type f \( -name '*.cfg' -o -name '*.conf' -o -name '*.txt' \) -print0)
fi
lb build 2>&1 | tee build.log
iso="$(find . -maxdepth 1 -type f \( -name 'live-image-amd64.hybrid.iso' -o -name 'live-image-amd64.iso' -o -name '*.hybrid.iso' -o -name '*.iso' \) -print -quit)"
[[ -n "$iso" ]] || { echo "ERROR: no ISO found" >&2; exit 1; }
mv "$iso" "$OUTPUT"
sha256sum "$OUTPUT" > "$OUTPUT.sha256"
printf '\nBuilt: %s\n' "$OUTPUT"
