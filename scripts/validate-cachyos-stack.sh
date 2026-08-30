#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)";cd "$ROOT"
required=(
  docs/CACHYOS_INTEGRATION_PLAN.md scripts/build-cachyos-kernel.sh scripts/fetch-cachyos-kernel.py
  .github/workflows/build-cachyos-kernel.yml .github/workflows/check-cachyos-kernel.yml .github/workflows/validate-cachyos-userspace.yml
  config/includes.chroot/etc/systemd/zram-generator.conf config/includes.chroot/etc/sysctl.d/70-flexos-performance.conf
  config/includes.chroot/etc/systemd/system.conf.d/70-flexos-performance.conf config/includes.chroot/etc/systemd/user.conf.d/70-flexos-performance.conf config/includes.chroot/etc/systemd/journald.conf.d/70-flexos-performance.conf
  config/includes.chroot/usr/lib/flexos/flex-performance-apply config/includes.chroot/usr/lib/flexos/flex-scx-profile-sync
  config/includes.chroot/usr/lib/systemd/system/flexos-performance.service config/includes.chroot/usr/lib/systemd/system/flexos-scx-profile-sync.service config/includes.chroot/usr/lib/systemd/system/flexos-scx-profile-sync.timer
  config/includes.chroot/usr/bin/flex-kernel-info config/includes.chroot/usr/bin/flex-kernel-manager config/includes.chroot/usr/bin/flex-game-performance config/includes.chroot/usr/bin/flex-performance-config
  config/includes.chroot/usr/bin/flex-scx config/includes.chroot/usr/bin/flex-ananicy config/includes.chroot/usr/bin/flex-gaming
  config/includes.chroot/usr/bin/flex-hwd config/includes.chroot/usr/bin/flex-mirror config/includes.chroot/usr/bin/flex-repo config/includes.chroot/usr/bin/flex-secureboot
  config/includes.chroot/usr/lib/flexos/flexcachy.py config/includes.chroot/usr/bin/flex-center
  config/includes.chroot/usr/lib/flexos/flex-snapshot-pre config/includes.chroot/usr/lib/flexos/flex-snapshot-post
  config/includes.chroot/etc/kernel/postinst.d/zz-flexos-sign-kernel config/includes.chroot/usr/share/flexos/optimized-repos.json
  packages/postinst/flexos-performance.postinst
)
for f in "${required[@]}";do [[ -f "$f" ]]||{ echo "[FAIL] missing CachyOS integration file: $f" >&2;exit 1;};done
bash -n scripts/build-cachyos-kernel.sh
bash -n config/includes.chroot/usr/bin/flex-game-performance
for f in config/includes.chroot/usr/lib/flexos/flex-performance-apply config/includes.chroot/usr/lib/flexos/flex-scx-profile-sync config/includes.chroot/usr/bin/flex-kernel-info config/includes.chroot/usr/lib/flexos/flex-snapshot-pre config/includes.chroot/usr/lib/flexos/flex-snapshot-post config/includes.chroot/etc/kernel/postinst.d/zz-flexos-sign-kernel packages/postinst/flexos-performance.postinst;do sh -n "$f";done
python3 -m py_compile scripts/fetch-cachyos-kernel.py \
  config/includes.chroot/usr/bin/flex-hwd config/includes.chroot/usr/bin/flex-scx config/includes.chroot/usr/bin/flex-ananicy \
  config/includes.chroot/usr/bin/flex-gaming config/includes.chroot/usr/bin/flex-mirror config/includes.chroot/usr/bin/flex-repo \
  config/includes.chroot/usr/bin/flex-secureboot config/includes.chroot/usr/bin/flex-kernel-manager config/includes.chroot/usr/bin/flex-performance-config \
  config/includes.chroot/usr/lib/flexos/flexcachy.py config/includes.chroot/usr/bin/flex-center config/includes.chroot/usr/bin/flex-system-report
python3 - <<'PY'
import json
from pathlib import Path
for f in ('packages/package-map.json','config/includes.chroot/usr/share/flexos/package-profiles.json','config/includes.chroot/usr/share/flexos/optimized-repos.json'):json.loads(Path(f).read_text())
m=json.loads(Path('packages/package-map.json').read_text());perf=set(m['flexos-performance']['paths']);tools=set(m['flexos-tools']['paths']);gaming=set(m['flexos-gaming']['paths'])
assert {'usr/bin/flex-scx','usr/bin/flex-ananicy','usr/bin/flex-performance-config','usr/lib/systemd/system/flexos-scx-profile-sync.timer'} <= perf
assert {'usr/bin/flex-hwd','usr/bin/flex-mirror','usr/bin/flex-repo','usr/bin/flex-secureboot','usr/bin/flex-kernel-manager','usr/lib/flexos/flexcachy.py','etc/kernel/postinst.d/zz-flexos-sign-kernel'} <= tools
assert 'usr/bin/flex-gaming' in gaming
assert 'flexos-performance' in m['flexos-center']['depends'] and 'flexos-gaming' in m['flexos-center']['depends']
PY
grep -qx 'linux-image-amd64' config/package-lists/flexos.list.chroot || { echo '[FAIL] Debian fallback kernel must remain installed.' >&2;exit 1; }
grep -q -- '--linux-flavours flexos-cachy --linux-packages none' build.sh || { echo '[FAIL] custom live kernel selection missing.' >&2;exit 1; }
grep -q '^compression-algorithm = zstd$' config/includes.chroot/etc/systemd/zram-generator.conf
grep -q '^zram-size = ram$' config/includes.chroot/etc/systemd/zram-generator.conf
grep -q '^swap-priority = 100$' config/includes.chroot/etc/systemd/zram-generator.conf
grep -q '^vm.swappiness = 100$' config/includes.chroot/etc/sysctl.d/70-flexos-performance.conf
grep -q '^kernel.nmi_watchdog = 0$' config/includes.chroot/etc/sysctl.d/70-flexos-performance.conf
grep -q '^DPkg::Pre-Invoke' config/includes.chroot/etc/apt/apt.conf.d/80flexos-snapshot
grep -q '^DPkg::Post-Invoke' config/includes.chroot/etc/apt/apt.conf.d/80flexos-snapshot
grep -q "dpkg','--add-architecture','i386" config/includes.chroot/usr/bin/flex-gaming
grep -q 'trixie-backports' config/includes.chroot/usr/bin/flex-gaming
grep -q 'CachyOS/proton-cachyos' config/includes.chroot/usr/bin/flex-gaming
grep -q "'gaming':'Gaming'" config/includes.chroot/usr/bin/flex-scx
grep -q "'powersave':'PowerSave'" config/includes.chroot/usr/bin/flex-scx
grep -q 'MOK.key' config/includes.chroot/usr/bin/flex-secureboot
grep -q -- '--nvidia' config/includes.chroot/usr/bin/flex-hwd
grep -q 'flexos-scx-profile-sync.timer' config/hooks/live/030-flexos-services.hook.chroot
grep -q 'flexos-scx-profile-sync.timer' config/includes.chroot/usr/lib/flexos/flex-postinstall
for token in flex-scx flex-ananicy flex-gaming flex-hwd flex-secureboot flex-kernel-manager flex-repo flex-mirror;do grep -q "$token" config/includes.chroot/usr/bin/flex-center||{ echo "[FAIL] Flex Center missing $token" >&2;exit 1;};done
if grep -RIE '(^|[[:space:]])(Server|URIs):.*(archlinux|cachyos)' config/includes.chroot/etc/apt 2>/dev/null;then echo '[FAIL] Arch/CachyOS binary repository found in Debian APT config.' >&2;exit 1;fi
if grep -A20 '^  pull_request:' .github/workflows/build-cachyos-kernel.yml | grep -Eq "config/includes|package-map|validate-cachyos";then echo '[FAIL] kernel workflow still watches userspace paths.' >&2;exit 1;fi
echo 'FlexOS CachyOS integration validation passed.'
