# FlexOS CachyOS Integration Plan

FlexOS remains a Debian 13 (Trixie) userspace distribution. CachyOS is used as an upstream source for kernel technology, performance policy and selected desktop/gaming ideas; Arch Linux packages and repositories are not installed directly on FlexOS.

## Design rules

1. Keep FlexOS branding, Calamares, GRUB, Plymouth and release identity.
2. Build native Debian `.deb` packages for the CachyOS-derived kernel.
3. Keep Debian `linux-image-amd64` installed as a bootable fallback until the CachyOS-derived kernel has passed release QA on supported hardware.
4. Never add an Arch repository or install a `.pkg.tar.zst` package into the Debian root filesystem.
5. Features that do not exist in Debian are rebuilt/package-managed in the FlexOS repository instead of being copied unmanaged into `/usr`.
6. Every performance change must remain reversible and must not break the recovery environment.

## Phase 1 — CachyOS-derived kernel

Status: **implemented by this integration branch**

- Add a dedicated GitHub Actions kernel build pipeline.
- Read the current CachyOS kernel release metadata and config from the official `CachyOS/linux-cachyos` repository.
- Build the official CachyOS kernel source as Debian packages with FlexOS local-version branding.
- Use a distribution-safe generic x86-64 build rather than `-march=native` so one ISO remains portable between machines.
- Prefer the current CachyOS LLVM/ThinLTO-oriented configuration when the build host supports it.
- Publish `linux-image` and `linux-headers` packages as `kernel-latest` release assets.
- Make the ISO build consume `kernel-latest` when present.
- Keep Debian `linux-image-amd64` as fallback.
- Verify the selected kernel, headers and fallback with `flex-kernel-info`.

Release-gate follow-up:

- Make the kernel asset mandatory for tagged FlexOS releases after the first successful `kernel-latest` build.
- Add real-hardware boot tests for AMD, Intel, NVIDIA proprietary/open DKMS and Secure Boot/MOK flows before removing the transitional optional download.

## Phase 2 — CachyOS-style system performance policy

Status: **implemented by this integration branch**

- ZRAM generator profile using zstd, RAM-sized dynamic zram and priority 100.
- Desktop-oriented VM/VFS/dirty-page sysctl policy based on CachyOS Settings.
- Increased file-handle and network receive backlog limits.
- Disable NMI watchdog for the performance profile.
- Shorter systemd service stop/start timeouts and higher file descriptor limits.
- Bounded persistent/runtime journal size.
- Runtime BBR/FQ activation when the active kernel exposes the required support.
- A boot-time `flexos-performance.service` that records capability status without failing boot on unsupported hardware/kernels.

## Phase 3 — sched-ext and process prioritization

Status: **planned; kernel capability detection is implemented**

- Package the current `scx`/sched-ext scheduler userspace tools as native FlexOS Debian packages.
- Provide scheduler presets in Flex Center: Balanced, Gaming/Latency, Throughput and Power Save.
- Use systemd-managed scheduler selection with automatic fallback to the in-kernel scheduler.
- Package `ananicy-cpp` and CachyOS Ananicy rules only after dependency/licensing review and Debian integration tests.
- Avoid running Ananicy rules that fight an active sched-ext scheduler.

## Phase 4 — gaming stack parity

Status: **partially present; expansion planned**

Already present in the FlexOS Gaming profile:

- GameMode
- MangoHud
- Vulkan tools

Planned:

- Steam installation path appropriate for Debian multiarch.
- Lutris and Heroic installation choices.
- Gamescope when a maintained Debian/FlexOS package is available.
- Proton-CachyOS/umu integration packaged or downloaded through a versioned, checksum-verified installer rather than Arch packages.
- Controller/handheld udev rules and gaming power profile integration.
- Optional NVIDIA open/proprietary driver flow with DKMS + matching CachyOS kernel headers.

## Phase 5 — CachyOS Hardware Detection equivalent

Status: **planned**

Create `flex-hwd` as the Debian-native equivalent of `chwd`:

- Detect AMD/Intel/NVIDIA GPUs and install the correct Debian/FlexOS driver set.
- Detect Intel/AMD CPU microcode.
- Detect common Wi-Fi firmware needs.
- Add profiles for supported handhelds and special hardware only when the necessary kernel/userspace pieces exist in Debian or the FlexOS repository.
- Never silently replace a working graphics stack without a rollback path.

## Phase 6 — optimized FlexOS repositories

Status: **planned**

CachyOS optimized Arch repositories cannot be consumed by Debian. Reproduce the idea using FlexOS repositories:

- Baseline repository: Debian-compatible generic x86-64.
- Optional x86-64-v3 repository for modern CPUs.
- Optional Zen 4+ optimized repository where benchmarks justify it.
- Select high-impact packages for PGO/LTO/BOLT rather than rebuilding the whole Debian archive initially.
- Automatic CPU capability selection must always fall back to the baseline repository.

## Phase 7 — Btrfs/snapshot integration

Status: **foundation already exists in FlexOS**

FlexOS already configures Snapper when installed on a compatible Btrfs subvolume layout. Next parity work:

- Create pre/post APT transaction snapshots.
- Surface snapshots in Flex Recovery.
- Add bootloader snapshot entries only after read-only snapshot boot/rollback has been validated with the FlexOS GRUB layout.
- Keep snapshot cleanup bounded.

## Phase 8 — desktop, installer and management UX

Status: **planned**

- Add Kernel/Performance pages to Flex Center.
- Show active kernel, fallback kernel, sched-ext, BBR, ZRAM and current performance preset.
- Add one-click kernel rollback to the Debian fallback.
- Add hardware/driver status and gaming stack management.
- Keep the existing FlexOS KDE/Calamares/GRUB/Plymouth branding; no CachyOS logo or distribution identity is imported.

## Definition of “CachyOS feature parity” for FlexOS

Parity means implementing the useful capability on Debian, not cloning CachyOS package-for-package. Arch-specific infrastructure (pacman hooks, Arch repositories, package names, mirror tooling and PKGBUILDs) is replaced by APT/dpkg, FlexOS repository packages and Debian-compatible hooks. This preserves Debian reliability while retaining the CachyOS performance and gaming ideas that are technically portable.
