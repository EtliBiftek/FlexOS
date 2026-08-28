# FlexOS CachyOS Integration Plan

FlexOS remains a Debian 13 (Trixie) userspace distribution. CachyOS is used as an upstream source for kernel technology, performance policy and desktop/gaming ideas; Arch Linux packages and repositories are never installed directly on FlexOS.

## Design rules

1. Keep FlexOS branding, Calamares, GRUB, Plymouth and release identity.
2. Build native Debian `.deb` packages for CachyOS-derived components.
3. Keep Debian `linux-image-amd64` installed as a bootable fallback until the CachyOS-derived kernel has passed release QA on supported hardware.
4. Never add an Arch repository or install a `.pkg.tar.zst` package into the Debian root filesystem.
5. Features that do not exist in Debian are rebuilt/package-managed in the FlexOS repository instead of being copied unmanaged into `/usr`.
6. Every performance change must remain reversible and must not break the recovery environment.
7. Hardware-specific tweaks are applied only after hardware detection; do not copy global AMD/NVIDIA/handheld settings to every machine.

## Phase 1 — CachyOS-derived kernel

Status: **implemented by this integration branch; first CI build still required**

- Dedicated GitHub Actions kernel build pipeline.
- Read current CachyOS kernel release metadata/config from `CachyOS/linux-cachyos`.
- Build the CachyOS kernel source as Debian `linux-image` and `linux-headers` packages with `-flexos-cachy` branding.
- Use a distribution-safe generic x86-64 build rather than `-march=native` so one ISO remains portable.
- Prefer LLVM/ThinLTO-oriented CachyOS configuration when the build host supports it.
- Publish packages as rolling `kernel-latest` release assets with checksums and provenance metadata.
- ISO builds fetch and verify `kernel-latest` automatically.
- `live-build` boots the `flexos-cachy` flavour by default when present.
- Debian `linux-image-amd64` remains installed as an additional bootable fallback.
- `flex-kernel-info` reports active kernel, fallback, sched-ext, NTSYNC, BBR and ZRAM.

Next kernel parity work:

- Add build profiles for the CachyOS variants: default, BORE, BMQ, EEVDF, LTS, hardened, RC, server, RT-BORE and deckify/handheld.
- Add optional LLVM LTO counterparts where applicable.
- Add AutoFDO/Propeller profile pipeline for the default kernel after repeatable profiling infrastructure exists.
- Add optional kCFI build.
- Add prebuilt/CI-tested NVIDIA open/proprietary module compatibility packages and optional ZFS package, keeping licensing boundaries intact.
- Add x86-64-v3/v4 and Zen4+ kernel builds as optional repository packages, never as the only ISO kernel.
- Add real-hardware boot tests for AMD, Intel, NVIDIA DKMS/open modules and Secure Boot/MOK.

## Phase 2 — CachyOS-style system performance policy

Status: **implemented by this integration branch**

- ZRAM generator profile using zstd, RAM-sized dynamic zram and priority 100.
- Desktop-oriented VM/VFS/dirty-page sysctl policy based on current CachyOS Settings.
- Increased file-handle and network receive backlog limits.
- NMI watchdog disabled for the performance-oriented default.
- Shorter systemd service stop/start timeouts and higher file descriptor limits.
- Bounded system journal size.
- Runtime BBR/FQ activation when the active kernel exposes the required support.
- Runtime NTSYNC module activation when available.
- `flexos-performance.service` records kernel/performance capability state without making unsupported hardware fail boot.
- `flex-game-performance` temporarily switches to the performance power profile while a game is running.

Planned parity additions:

- Optional PCI latency helper after hardware-specific testing.
- Regulatory-domain helper using the user-selected country rather than geolocation guesses.
- Zink launch helper.
- Sysctl profile manager in Flex Center with Restore Defaults.

## Phase 3 — sched-ext and process prioritization

Status: **kernel capability detection implemented; userspace packaging planned**

- Package current `scx` schedulers and `scx_loader`/`scxctl` as native FlexOS Debian packages.
- Provide scheduler presets in Flex Center: Balanced, Gaming/Latency, Throughput and Power Save.
- Use systemd-managed scheduler selection with automatic fallback to the in-kernel scheduler.
- Package `ananicy-cpp` and the CachyOS Ananicy rules after Debian dependency/licensing review.
- Avoid Ananicy rules that conflict with an active sched-ext scheduler.
- Expose scheduler state in `flex-kernel-info`, system reports and Flex Center.

## Phase 4 — gaming stack parity

Status: **partially implemented**

Already present or implemented:

- GameMode.
- MangoHud.
- Vulkan tools.
- `flex-game-performance`.
- NTSYNC activation when the kernel provides it.

Planned:

- Debian multiarch setup and Steam/steam-devices installation flow.
- Lutris and GOverlay packages from Debian.
- Heroic and other launchers through a maintained FlexOS package or verified Flatpak flow.
- Gamescope from Debian backports/FlexOS repository after repository policy is implemented.
- Proton-CachyOS/umu integration through a versioned checksum-verified installer/package, including NTSYNC defaults and protonfixes support.
- Gaming libraries/meta-package equivalent to `cachyos-gaming-meta`.
- Controller/handheld udev rules.
- Optional vkBasalt/ReplaySorcery and gaming capture tooling.
- Gaming-session mode for supported handheld hardware.

## Phase 5 — CachyOS Hardware Detection equivalent

Status: **started**

`flex-hwd` now detects PCI vendor/class IDs, CPU vendor and safe firmware/Mesa/microcode recommendations. `--apply-safe` can install only the low-risk set. It intentionally does not silently replace NVIDIA drivers.

Next:

- Add explicit NVIDIA proprietary/open driver profiles with matching CachyOS kernel headers and rollback snapshots.
- Add Wi-Fi/Bluetooth firmware profiles and device-specific quirks.
- Add VM profiles.
- Add T2 Mac profiles only after required Debian/FlexOS packages are available.
- Add Steam Deck, ROG Ally, Legion Go and other handheld profiles with deckify kernel selection where appropriate.
- Integrate detection into Calamares and Flex Center.

## Phase 6 — optimized FlexOS repositories

Status: **planned**

CachyOS optimized Arch repositories cannot be consumed by Debian. Reproduce the concept using native FlexOS APT repositories:

- Baseline repository: Debian-compatible generic x86-64.
- Optional x86-64-v3 repository.
- Optional x86-64-v4 repository.
- Optional Zen4/Zen5 optimized repository.
- Select high-impact packages for PGO/LTO/BOLT instead of rebuilding the entire Debian archive initially.
- Maintain patched/backported high-impact packages where Debian stable is too old for supported gaming/hardware features.
- CPU capability selection must always fall back to the baseline repository.
- Add benchmark gates so an optimized build is only retained when it provides a measurable benefit without regressions.

## Phase 7 — Btrfs/snapshot integration

Status: **pre/post APT snapshot pairing implemented; boot integration planned**

FlexOS already configured Snapper on compatible Btrfs installations. This branch upgrades package transactions to paired pre/post snapshots.

Next:

- Surface paired package snapshots in Flex Recovery.
- Keep a protected clean-install baseline snapshot.
- Add restore-to-first-snapshot helper.
- Add GRUB snapshot boot entries only after read-only snapshot boot/rollback is validated with the FlexOS layout.
- Keep automatic cleanup bounded.

## Phase 8 — desktop, installer and management UX

Status: **existing FlexOS equivalents are strong; CachyOS-specific controls planned**

FlexOS already has KDE-only Calamares integration, Flex Welcome and Flex Center. Do not replace them with CachyOS branding/apps. Add the missing capabilities to the FlexOS apps instead:

- Kernel Manager page: available/installed kernel variants, active/default/fallback kernel and removal safeguards.
- Custom kernel build page exposing supported scheduler, tick, preemption, LTO, architecture and hardening options.
- sched-ext manager.
- Hardware/driver profiles.
- Gaming package installer.
- Performance/sysctl manager.
- Optimized repository selector.
- Snapshot/rollback UX.
- One-click Debian fallback kernel selection.

## Phase 9 — CachyOS application-suite equivalents

Status: **mapped to FlexOS components; remaining functions planned**

- CachyOS Hello -> extend **Flex Welcome** and **Flex Center**.
- CachyOS Package Installer -> extend Flex Center package/app profiles and Flatpak integration.
- CachyOS Kernel Manager -> new Flex Center Kernel Manager backed by FlexOS `.deb` kernel repository.
- CachyOS rate-mirrors -> `flex-mirror` for Debian/FlexOS APT sources, with measured latency/throughput and rollback.
- systemd-boot-manager -> optional Flex boot manager backend; GRUB remains the supported default until systemd-boot installation/rollback is proven.
- CachyOS bugreport/topmem/kerver-style utilities -> integrate into `flex-system-report`, `flex-kernel-info` and Flex Doctor rather than duplicate commands unnecessarily.

## Phase 10 — Secure Boot and boot management

Status: **foundation present; planned expansion**

- Keep current MOK/Secure Boot detection.
- Sign FlexOS CachyOS kernel packages in the release pipeline.
- Sign out-of-tree modules or guide MOK enrollment for DKMS packages.
- Add Secure Boot status and remediation to Flex Center.
- Test GRUB, fallback kernel and recovery entries after every kernel transaction.
- Only add a systemd-boot option after installation and rollback are fully supported.

## Phase 11 — special hardware and kernel patch capabilities

Status: **planned/covered by CachyOS upstream source where enabled**

Track and expose supported upstream CachyOS patch capabilities such as handheld compatibility, selected AMD/Intel device enablement, HDR/VRR-related fixes and other hardware patches. Userspace packages and modprobe settings are installed only when `flex-hwd` matches the hardware. No global copy of CachyOS device-specific settings.

## Phase 12 — release, QA and maintenance

Status: **validation framework started**

- `validate-cachyos-stack.sh` gates integration invariants.
- Kernel packages carry checksums/provenance metadata.
- Add kernel ABI/DKMS matrix tests.
- Add QEMU boot test using the CachyOS-derived kernel explicitly.
- Add bare-metal test matrix for AMD/Intel/NVIDIA and laptop/desktop/handheld classes.
- Track current upstream CachyOS kernel/config changes weekly and build only when source metadata changes.
- Prevent publication if the Debian fallback kernel is missing.
- Keep upstream license/notices for every imported or adapted component.

## Full parity inventory

The parity target covers these CachyOS capability groups:

- Kernel base patchset and kernel variants.
- LLVM/GCC, LTO, AutoFDO, Propeller, kCFI, timer/preemption/THP and architecture tuning.
- sched-ext/SCX and process prioritization.
- ZRAM/sysctl/systemd/journal/network performance defaults.
- Hardware detection and driver profiles.
- NVIDIA/open module compatibility and optional ZFS integration.
- Gaming libraries, launchers, Gamescope, MangoHud/GOverlay, GameMode, Proton-CachyOS/umu and NTSYNC.
- Handheld/device-specific support.
- Btrfs/Snapper transaction snapshots and rollback.
- Optimized x86-64-v3/v4/Zen4+ repositories and selective PGO/LTO/BOLT packages.
- Welcome/package installer/kernel manager/sysctl manager equivalents.
- Mirror ranking/update infrastructure.
- Secure Boot/module signing/boot management.
- Diagnostic/support helpers.
- Installer and KDE integration without importing CachyOS identity/branding.

## Definition of “CachyOS feature parity” for FlexOS

Parity means implementing the useful capability on Debian, not cloning CachyOS package-for-package. Arch-specific infrastructure (pacman hooks, Arch repositories, package names, mirrorlists and PKGBUILDs) is replaced by APT/dpkg, FlexOS repository packages and Debian-compatible hooks. Existing FlexOS applications are extended instead of installing duplicate CachyOS-branded applications. This preserves Debian reliability while retaining portable CachyOS performance, hardware and gaming features.
