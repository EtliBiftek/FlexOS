#!/usr/bin/env bash
set -Eeuo pipefail

ISO="${1:?Usage: qemu-boot-smoke.sh FlexOS.iso}"
TIMEOUT="${FLEXOS_QEMU_TIMEOUT:-240}"

for c in xorriso qemu-system-x86_64 timeout grep; do
  command -v "$c" >/dev/null 2>&1 || { echo "Missing command: $c" >&2; exit 2; }
done

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

xorriso -osirrox on -indev "$ISO" -extract /live/vmlinuz "$tmp/vmlinuz" >/dev/null 2>&1
xorriso -osirrox on -indev "$ISO" -extract /live/initrd.img "$tmp/initrd.img" >/dev/null 2>&1

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

if grep -q "FLEXOS_CI_BOOT_OK" "$log"; then
  if grep -Eq 'Linux version [^[:space:]]*flexos-cachy' "$log" || grep -q 'flexos-cachy' "$log"; then
    echo "[PASS] FlexOS CachyOS-derived kernel reached multi-user.target in QEMU."
    exit 0
  fi
  echo "[FAIL] QEMU reached live userspace, but the running kernel was not the FlexOS CachyOS-derived kernel." >&2
  grep -m1 -E 'Linux version ' "$log" >&2 || true
  exit 1
fi

if grep -Fq "Unable to find a medium containing a live file system" "$log"; then
  echo "[FAIL] QEMU initramfs could not discover the ISO live medium." >&2
  echo "Expected optical/storage modules: ata_piix sr_mod isofs" >&2
  grep -m1 -E 'Linux version ' "$log" >&2 || true
  tail -n 160 "$log" >&2
  exit 1
fi

if grep -Eq 'Linux version [^[:space:]]*flexos-cachy' "$log"; then
  echo "[FAIL] QEMU booted the FlexOS CachyOS-derived kernel but did not reach live userspace (qemu exit $rc)." >&2
else
  echo "[FAIL] QEMU booted a kernel, but it was not the FlexOS CachyOS-derived kernel." >&2
  grep -m1 -E 'Linux version ' "$log" >&2 || true
fi

echo "Last 160 lines:" >&2
tail -n 160 "$log" >&2
exit 1
