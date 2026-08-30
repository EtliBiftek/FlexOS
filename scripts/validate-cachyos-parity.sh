#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"; cd "$ROOT"
required=(scripts/build-cachyos-kernel-variant.sh .github/workflows/build-cachyos-kernel-variants.yml config/includes.chroot/usr/share/flexos/kernel-variants.json config/includes.chroot/usr/bin/flex-regdomain config/includes.chroot/usr/bin/flex-pci-latency config/includes.chroot/usr/bin/flex-topmem config/includes.chroot/usr/bin/flex-zink-run config/includes.chroot/usr/bin/flex-dlss-run config/includes.chroot/usr/lib/systemd/system/flexos-regdomain.service config/includes.chroot/usr/lib/systemd/system/flexos-pci-latency.service)
for f in "${required[@]}"; do [[ -f "$f" ]] || { echo "[FAIL] missing parity file: $f" >&2; exit 1; }; done
bash -n scripts/build-cachyos-kernel-variant.sh
bash -n config/includes.chroot/usr/bin/flex-pci-latency
bash -n config/includes.chroot/usr/bin/flex-zink-run
bash -n config/includes.chroot/usr/bin/flex-dlss-run
python3 -m py_compile config/includes.chroot/usr/bin/flex-regdomain config/includes.chroot/usr/bin/flex-topmem config/includes.chroot/usr/bin/flex-kernel-manager
python3 - <<'PY'
import json
from pathlib import Path
variants=json.loads(Path('config/includes.chroot/usr/share/flexos/kernel-variants.json').read_text());expected={'default','bore','bmq','deckify','eevdf','hardened','lts','rc','rt-bore','server'};assert set(variants)==expected
m=json.loads(Path('packages/package-map.json').read_text());tools=set(m['flexos-tools']['paths']);needed={'usr/bin/flex-regdomain','usr/bin/flex-pci-latency','usr/bin/flex-topmem','usr/bin/flex-zink-run','usr/bin/flex-dlss-run','usr/share/flexos/kernel-variants.json','usr/lib/systemd/system/flexos-regdomain.service','usr/lib/systemd/system/flexos-pci-latency.service'};assert needed <= tools,'extended parity package paths missing';assert 'iw' in m['flexos-tools']['depends'].split(', ')
PY
for v in default bore bmq deckify eevdf hardened lts rc rt-bore server; do grep -q "$v" .github/workflows/build-cachyos-kernel-variants.yml || exit 1; done
grep -q 'FLEXOS_KERNEL_AUTOFDO_PROFILE' scripts/build-cachyos-kernel-variant.sh
grep -q 'FLEXOS_KERNEL_PROPELLER_PREFIX' scripts/build-cachyos-kernel-variant.sh
grep -q 'LTO_CLANG_THIN_DIST' scripts/build-cachyos-kernel-variant.sh
grep -q 'CFI_CLANG' scripts/build-cachyos-kernel-variant.sh
grep -q 'ConditionPathExists=/etc/flexos/regdomain' config/includes.chroot/usr/lib/systemd/system/flexos-regdomain.service
if grep -q 'enable flexos-pci-latency.service' config/hooks/live/030-flexos-services.hook.chroot; then echo '[FAIL] PCI latency tuning must remain opt-in.' >&2;exit 1;fi
echo 'Extended CachyOS parity validation passed.'
