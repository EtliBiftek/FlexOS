#!/usr/bin/env bash
set -Eeuo pipefail

ISO="${1:?Usage: qemu-boot-smoke.sh FlexOS.iso}"
TIMEOUT="${FLEXOS_QEMU_TIMEOUT:-180}"

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
  -append "boot=live components username=flex hostname=flexos user-fullname=FlexOS locales=en_US.UTF-8 keyboard-layouts=us console=ttyS0,115200n8 flexos.ci=1 systemd.show_status=1" \
  -display none \
  -serial stdio \
  -monitor none \
  -no-reboot 2>&1 | tee "$log"
rc=${PIPESTATUS[0]}
set -e

if grep -q "FLEXOS_CI_BOOT_OK" "$log"; then
  echo "[PASS] FlexOS live system reached multi-user.target in QEMU."
  exit 0
fi

echo "[FAIL] FlexOS live boot sentinel was not observed (qemu exit $rc)." >&2
echo "Last 120 lines:" >&2
tail -n 120 "$log" >&2
exit 1
