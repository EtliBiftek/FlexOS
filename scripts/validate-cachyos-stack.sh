#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

required=(
  docs/CACHYOS_INTEGRATION_PLAN.md
  scripts/build-cachyos-kernel.sh
  scripts/fetch-cachyos-kernel.py
  .github/workflows/build-cachyos-kernel.yml
  config/includes.chroot/etc/systemd/zram-generator.conf
  config/includes.chroot/etc/sysctl.d/70-flexos-performance.conf
  config/includes.chroot/etc/systemd/system.conf.d/70-flexos-performance.conf
  config/includes.chroot/etc/systemd/user.conf.d/70-flexos-performance.conf
  config/includes.chroot/etc/systemd/journald.conf.d/70-flexos-performance.conf
  config/includes.chroot/usr/lib/flexos/flex-performance-apply
  config/includes.chroot/usr/lib/systemd/system/flexos-performance.service
  config/includes.chroot/usr/bin/flex-kernel-info
  config/includes.chroot/usr/bin/flex-game-performance
  packages/postinst/flexos-performance.postinst
)

for f in "${required[@]}"; do
  [[ -f "$f" ]] || { echo "[FAIL] missing CachyOS integration file: $f" >&2; exit 1; }
done

bash -n scripts/build-cachyos-kernel.sh
bash -n config/includes.chroot/usr/bin/flex-game-performance
sh -n config/includes.chroot/usr/lib/flexos/flex-performance-apply
sh -n config/includes.chroot/usr/bin/flex-kernel-info
sh -n packages/postinst/flexos-performance.postinst
python3 -m py_compile scripts/fetch-cachyos-kernel.py

grep -qx 'linux-image-amd64' config/package-lists/flexos.list.chroot || {
  echo '[FAIL] Debian fallback kernel meta-package must remain installed.' >&2
  exit 1
}

grep -q -- '--linux-flavours flexos-cachy --linux-packages none' build.sh || {
  echo '[FAIL] live-build is not configured to boot the custom kernel when available.' >&2
  exit 1
}

grep -q '^compression-algorithm = zstd$' config/includes.chroot/etc/systemd/zram-generator.conf
grep -q '^swap-priority = 100$' config/includes.chroot/etc/systemd/zram-generator.conf
grep -q '^vm.swappiness = 100$' config/includes.chroot/etc/sysctl.d/70-flexos-performance.conf
grep -q '^kernel.nmi_watchdog = 0$' config/includes.chroot/etc/sysctl.d/70-flexos-performance.conf

python3 - <<'PY'
import json
from pathlib import Path
m=json.loads(Path('packages/package-map.json').read_text())
p=m.get('flexos-performance')
assert p, 'flexos-performance package missing'
required={
    'etc/systemd/zram-generator.conf',
    'etc/sysctl.d/70-flexos-performance.conf',
    'usr/lib/flexos/flex-performance-apply',
    'usr/lib/systemd/system/flexos-performance.service',
    'usr/bin/flex-kernel-info',
    'usr/bin/flex-game-performance',
}
assert required.issubset(set(p['paths'])), 'flexos-performance package map incomplete'
PY

grep -q 'flexos-performance.service' config/hooks/live/030-flexos-services.hook.chroot
grep -q 'flexos-performance.service' config/includes.chroot/usr/lib/flexos/flex-postinstall

echo 'FlexOS CachyOS integration validation passed.'
