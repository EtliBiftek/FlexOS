#!/usr/bin/env bash
set -Eeuo pipefail

ISO="${1:?Usage: qemu-boot-smoke.sh FlexOS.iso}"
TIMEOUT="${FLEXOS_QEMU_TIMEOUT:-240}"

for c in xorriso qemu-system-x86_64 timeout grep sed; do
  command -v "$c" >/dev/null 2>&1 || { echo "Missing command: $c" >&2; exit 2; }
done

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# Do not use /live/vmlinuz and /live/initrd.img independently here. live-build
# creates those generic Syslinux aliases separately, so a stale Debian initrd
# could previously be paired with the FlexOS kernel and let this test miss the
# broken versioned GRUB entry.
xorriso -indev "$ISO" \
  -find /live -maxdepth 1 -type f -name 'vmlinuz-*-flexos-cachy' -exec lsdl -- \
  >"$tmp/custom-kernel-list.txt" 2>/dev/null

mapfile -t custom_kernels < <(
  sed -n "s#.*'\(/live/vmlinuz-[^']*-flexos-cachy\)'.*#\1#p" "$tmp/custom-kernel-list.txt"
)

if (( ${#custom_kernels[@]} != 1 )); then
  printf '[FAIL] expected exactly one versioned FlexOS CachyOS-derived live kernel, found %d.\n' "${#custom_kernels[@]}" >&2
  cat "$tmp/custom-kernel-list.txt" >&2 || true
  exit 1
fi

kernel_iso="${custom_kernels[0]}"
kernel_version="${kernel_iso#/live/vmlinuz-}"
initrd_iso="/live/initrd.img-${kernel_version}"

if ! xorriso -osirrox on -indev "$ISO" -extract "$kernel_iso" "$tmp/vmlinuz" >/dev/null 2>&1; then
  echo "[FAIL] unable to extract versioned live kernel: $kernel_iso" >&2
  exit 1
fi
if ! xorriso -osirrox on -indev "$ISO" -extract "$initrd_iso" "$tmp/initrd.img" >/dev/null 2>&1; then
  echo "[FAIL] ISO is missing the version-matched live initrd: $initrd_iso" >&2
  exit 1
fi

log="$tmp/qemu.log"

set +e
timeout "$TIMEOUT" qemu-system-x86_64 \
  -machine accel=tcg \
  -m 2048 \
  -smp 2 \
  -cdrom "$ISO" \
  -kernel "$tmp/vmlinuz" \
  -initrd "$tmp/initrd.img" \
  -append "boot=live components live-media-timeout=30 username=flex hostname=flexos user-fullname=FlexOS locales=en_US.UTF-8 keyboard-layouts=us console=ttyS0,115200n8 flexos.ci=1 systemd.unit=multi-user.target systemd.show_status=1" \
  -display none \
  -serial stdio \
  -monitor none \
  -no-reboot 2>&1 | tee "$log"
rc=${PIPESTATUS[0]}
set -e

if grep -q 'FLEXOS_CI_FAILED_UNIT=' "$log"; then
  failed_unit="$(grep -oEm1 'FLEXOS_CI_FAILED_UNIT=[^[:space:]]+' "$log" | cut -d= -f2- || true)"
  echo "[FAIL] FlexOS reached userspace, but ${failed_unit:-a required service} failed during boot." >&2
  exit 1
fi

if grep -q "FLEXOS_CI_BOOT_OK" "$log"; then
  if grep -Eq 'FLEXOS_CI_KERNEL=[^[:space:]]*flexos-cachy' "$log"; then
    kernel="$(grep -oEm1 'FLEXOS_CI_KERNEL=[^[:space:]]+' "$log" | cut -d= -f2- || true)"
    echo "[PASS] FlexOS CachyOS-derived kernel ${kernel:-unknown} reached multi-user.target in QEMU."
    exit 0
  fi
  echo "[FAIL] QEMU reached live userspace, but the runtime kernel is not the FlexOS CachyOS-derived kernel." >&2
  grep -oEm1 'FLEXOS_CI_KERNEL=[^[:space:]]+' "$log" >&2 || true
  exit 1
fi

if grep -Fq "Unable to find a medium containing a live file system" "$log" || \
   grep -Fq "Can not mount /dev/loop0" "$log"; then
  echo "[FAIL] QEMU initramfs could not mount the ISO live filesystem." >&2
  echo "Expected built-in live boot support: ata_piix sr_mod isofs loop squashfs squashfs_xz" >&2
  grep -m1 -E 'Linux version ' "$log" >&2 || true
  tail -n 160 "$log" >&2
  exit 1
fi

if grep -Eq 'Linux version [^[:space:]]*flexos-cachy' "$log"; then
  echo "[FAIL] QEMU booted the FlexOS CachyOS-derived kernel but did not reach live userspace (qemu exit $rc)." >&2
else
  echo "[FAIL] QEMU did not reach the FlexOS CI boot sentinel (qemu exit $rc)." >&2
  grep -m1 -E 'Linux version ' "$log" >&2 || true
fi

echo "Last 160 lines:" >&2
tail -n 160 "$log" >&2
exit 1