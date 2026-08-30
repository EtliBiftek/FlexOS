# FlexOS CachyOS Integration

FlexOS remains a Debian 13/Trixie distribution. CachyOS is used as an upstream for kernel technology and performance/gaming design; Arch repositories and `.pkg.tar.zst` packages are never mixed into the Debian root.

## Current status

The CachyOS-derived FlexOS stack is merged to `main`. The default kernel completed a real GitHub CI build as native Debian `linux-image`/`linux-headers` packages and is published as `kernel-latest`. Userspace parity has separate lightweight validation so ordinary desktop changes do not trigger a multi-hour kernel compile.

## Kernel — implemented

- Official CachyOS source/config ingestion with maintainer PGP verification and Debian-native `.deb` output.
- The generic default is the ISO kernel; Debian `linux-image-amd64` remains a protected fallback.
- Weekly upstream watcher rebuilds only when the source release changes.
- Extended manual matrix: default, BORE, BMQ, Deckify, EEVDF, Hardened, LTS, RC, RT-BORE and Server.
- Variant builds apply scheduler/hardening/RT patch URLs selected by the current upstream PKGBUILD while producing Debian packages.
- CPU targets: generic, x86-64-v3, x86-64-v4, Zen4 and native.
- LLVM modes: upstream, none, ThinLTO, Full LTO and distributed ThinLTO; optional kCFI.
- Advanced profile hooks: HZ, preemption, THP, AutoFDO instrumentation/profile input and Propeller profile input.
- Experimental/specialized variants use independent rolling releases and never silently replace the universal ISO default.

## System performance — implemented

- zstd ZRAM sized to RAM, priority 100; CachyOS-derived sysctl/systemd/journald policy; BBR/FQ/NTSYNC capability handling.
- sched_ext/SCX manager with Auto/Gaming/LowLatency/PowerSave/Server modes and power-profile synchronization.
- Ananicy-cpp + CachyOS rules, kept optional to avoid GameMode priority conflicts.
- `flex-game-performance`, `flex-performance-config` and kernel diagnostics.
- Optional `flex-pci-latency` reproduces CachyOS PCI audio-latency tuning but is never enabled globally by default.
- `flex-regdomain` persists only an explicitly selected ISO country code; no geolocation guessing.
- `flex-zink-run` and `flex-topmem` provide the portable CachyOS helper behavior on Debian.

## Gaming — implemented

- GameMode, MangoHud, GOverlay, Lutris, Vulkan tools, vkBasalt.
- Steam with Debian i386 multiarch and 32-bit Mesa/Vulkan.
- Gamescope via Trixie Backports; Heroic via Flathub; verified umu-launcher.
- Checksum-verified Proton-CachyOS x86_64/x86_64-v3 installer.
- NTSYNC diagnostics.
- `flex-dlss-run` provides the CachyOS DLSS latest-preset environment, with optional NGX updater; `flex-zink-run` provides Zink launch mode.

## Hardware / drivers — implemented

`flex-hwd` handles safe firmware/Mesa/microcode plus explicit NVIDIA proprietary, NVIDIA open-DKMS and Nouveau profiles. Driver switching is snapshot-aware, requires matching headers, checks Secure Boot/MOK readiness and can sign DKMS modules. Handheld detection covers Steam Deck, ROG Ally, Legion Go and generic handheld families with a safe hardware-gated profile.

## Snapshots / recovery — implemented

Snapper root setup, paired APT/dpkg pre/post snapshots, update/driver snapshots, Flex Center create/delete/rollback and protected Debian fallback kernel.

## Flex Center / app equivalents — implemented

Flex Center replaces duplicate CachyOS-branded management apps: SCX/Ananicy, Gaming, drivers, kernel manager, mirror ranking, optimized repositories, Secure Boot/MOK, handhelds, snapshots, updates and diagnostics are integrated in one application. Advanced RC/RT/native kernel compilation remains a maintainer-CI action to prevent accidental experimental installs.

## Kernel Manager — implemented

`flex-kernel-manager` protects the running kernel and Debian fallback, installs the verified `kernel-latest` default, lists separately published variants and installs `install <variant> [cpu]`. Downloads are checked against GitHub asset digests when exposed and against release `SHA256SUMS`.

## Secure Boot — implemented

`flex-secureboot` generates a local root-only MOK key, requests enrollment, configures DKMS signing, signs DKMS modules and installed FlexOS CachyOS kernels and hooks future kernel installation. No private signing key is stored in Git.

## Mirrors / optimized repositories — implemented

`flex-mirror` benchmarks HTTPS Debian mirrors with rollback. `flex-repo` selects baseline/v3/v4/Zen4 only after signed `InRelease` health validation. The optimized repository workflow rebuilds selected Debian source packages and publishes signed profile branches.

## CachyOS Settings helper parity — implemented

- bugreport/kernel inspection → `flex-system-report`, `flex-kernel-info`, Flex Doctor.
- topmem → `flex-topmem`.
- zink-run → `flex-zink-run`.
- dlss-swapper → `flex-dlss-run`.
- pci-latency → opt-in `flex-pci-latency`/service.
- regulatory-domain handling → `flex-regdomain`/service.
- sbctl batch signing → `flex-secureboot`.

## QA / release behavior — implemented

- `validate-cachyos-stack.sh`: default integration invariants.
- `validate-cachyos-userspace.yml`: userspace syntax and every FlexOS component `.deb`.
- `validate-cachyos-parity.sh`: extended kernel matrix/helper layer.
- `build-cachyos-kernel-variants.yml`: manual matrix builder because every variant can consume hours of CI.
- Normal ISO pipeline: source/package validation, ISO structural smoke test and QEMU live-kernel boot test.

## Release rules

1. FlexOS branding/identity always remains FlexOS.
2. Debian fallback kernel stays installed.
3. Driver switching may not bypass Secure Boot/DKMS safety.
4. Optimized repositories require signed `InRelease` validation.
5. External release downloads are checksum-verified where upstream exposes a digest/checksum.
6. Optional SCX/Ananicy/gaming/helper components may not make the base install unbootable.
7. RC, RT, native-CPU and architecture-specialized kernels are never the universal ISO default.
8. Device-specific settings remain opt-in or hardware-gated.

## Definition of parity

“CachyOS feature parity” means providing the useful capability with Debian-native packaging, services and FlexOS safety rules. Arch/pacman infrastructure, CachyOS branding and hardware-specific assumptions are not copied literally. Where a CachyOS helper is already covered by a stronger integrated FlexOS tool, FlexOS keeps one implementation instead of duplicating branded commands.
