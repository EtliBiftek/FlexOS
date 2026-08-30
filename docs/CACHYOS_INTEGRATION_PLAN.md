# FlexOS CachyOS Integration

FlexOS remains a Debian 13/Trixie distribution. CachyOS is used as an upstream for the kernel and for performance/gaming design ideas; Arch repositories and `.pkg.tar.zst` packages are never mixed into the Debian root.

## Current status

The initial CachyOS-derived FlexOS kernel successfully completed real GitHub CI as native Debian `linux-image`/`linux-headers` packages. The userspace feature layer below is implemented on `feature/cachyos-stack` and has a dedicated lightweight validation workflow so ordinary userspace changes do not rebuild the kernel.

## 1. Kernel — implemented

- CachyOS `linux-cachyos` source/config ingestion with official maintainer PGP verification.
- Debian-native image/header `.deb` output and `-flexos-cachy` local version.
- Generic portable CPU target for the ISO instead of `-march=native`.
- Cachy/BORE configuration retained where supported.
- Custom kernel becomes the live default while Debian `linux-image-amd64` remains installed as fallback.
- `kernel-latest` rolling release/fetch/checksum architecture.
- Kernel CI only watches the kernel build source. Userspace/UI changes do not trigger a multi-hour kernel compile.
- Weekly lightweight upstream watcher triggers a kernel build only when CachyOS changes the source release.

## 2. System performance policy — implemented

- zstd ZRAM sized to RAM, priority 100.
- CachyOS-derived sysctl values, journal cap and systemd limits/timeouts.
- Runtime BBR/FQ, NTSYNC and sched_ext capability detection.
- `flexos-performance.service`, `flex-kernel-info`, `flex-performance-config`.

## 3. sched_ext / SCX — implemented

- `flex-scx` status/list/install/set/mode/disable manager.
- Upstream `sched-ext/scx-loader` integration (`scx_loader`, `scxctl`, `scxtui`).
- Stable sched-ext scheduler source install path with LAVD, bpfland, rusty, flash, cosmos and cake when available.
- Auto, Gaming, LowLatency, PowerSave and Server modes.
- Safe fallback to the in-kernel scheduler when sched_ext attach fails or is unsupported.
- power-profiles-daemon mapping via `flexos-scx-profile-sync.timer`: balanced→Auto, performance→Gaming, power-saver→PowerSave.
- `flex-game-performance` temporarily switches an active SCX scheduler to Gaming and restores the previous mode.

SCX source builds are optional and never make the base ISO depend on a Rust build succeeding.

## 4. Process prioritization / Ananicy — implemented

- `flex-ananicy` install/status/enable/disable/update-rules manager.
- ananicy-cpp is built with systemd support from its tagged upstream source.
- CachyOS ananicy-rules are installed from a tagged source and provenance is recorded.
- It is left disabled by default when installed because GameMode and Ananicy can compete over process nice levels; Flex Center warns about this combination.

## 5. Gaming stack — implemented

`flex-gaming` provides independent install actions for:

- GameMode, MangoHud, GOverlay, Lutris, Vulkan tools and vkBasalt.
- Steam with Debian i386 multiarch and 32-bit Mesa/Vulkan support.
- Gamescope from Trixie Backports.
- Heroic through Flathub.
- official umu-launcher Debian 13 release packages with GitHub-provided SHA256 verification.
- Proton-CachyOS Steam Linux Runtime x86_64/x86_64-v3 release assets with SHA256 verification and per-user Steam compatibility-tool installation.
- NTSYNC status is surfaced in diagnostics.

No Arch gaming repository is added.

## 6. Hardware detection / driver policy — implemented

`flex-hwd` detects CPU/GPU/network hardware and safe firmware/Mesa/microcode packages. It also provides explicit NVIDIA profiles:

- proprietary Debian NVIDIA driver;
- NVIDIA open kernel DKMS;
- Nouveau fallback.

NVIDIA switches create a Btrfs/Snapper snapshot when possible, require matching active-kernel headers for DKMS, check Secure Boot readiness, refresh initramfs/depmod and can sign DKMS modules when a FlexOS MOK exists.

Handheld DMI detection covers Steam Deck, ROG Ally, Legion Go and common generic handheld families; a safe handheld performance profile can be applied without installing vendor-specific Arch packages.

## 7. Btrfs / Snapper — implemented

- Root Snapper setup for supported Btrfs subvolume layouts.
- Paired APT/dpkg pre/post snapshots.
- Driver/system-update snapshots.
- Flex Center create/delete/rollback controls.
- Debian fallback kernel is protected from the Flex kernel manager removal path.

## 8. Flex Center management UX — implemented

Flex Center now exposes:

- SCX scheduler/mode controls and installer;
- Ananicy controls;
- zRAM/swappiness;
- Gaming stack installers;
- `flex-hwd` safe packages and all NVIDIA modes;
- CachyOS kernel status/update and Debian fallback repair;
- mirror ranking and optimized-repository auto selection;
- Secure Boot/MOK preparation, enrollment, kernel signing and DKMS signing;
- handheld profile controls;
- existing update, snapshot, recovery, privacy, app/profile and diagnostics pages.

## 9. Kernel Manager equivalent — implemented

`flex-kernel-manager` lists the active/installed kernel set, protects the Debian fallback meta-package and running kernel, repairs the fallback kernel, and installs `kernel-latest` FlexOS CachyOS kernel assets with release SHA256 verification.

## 10. Secure Boot / module signing — implemented

`flex-secureboot` can:

- report state;
- generate a local 3072-bit MOK key with the private key restricted to root;
- request MOK enrollment through `mokutil`;
- configure DKMS to reuse that key;
- sign compressed/uncompressed DKMS modules;
- sign installed `vmlinuz-*flexos-cachy` images with `sbsign`;
- automatically sign newly installed FlexOS CachyOS kernels when the local MOK is prepared.

The private signing key is never stored in the Git repository.

## 11. Mirror ranking and optimized APT repositories — implemented framework + publication pipeline

- `flex-mirror` benchmarks HTTPS Debian mirrors, backs up APT source files, applies only Debian mirror URI changes and can restore the backup.
- `flex-repo` detects baseline/x86-64-v3/x86-64-v4 capability and Zen4-class targets, verifies `InRelease` availability before enabling a profile, and automatically falls back to baseline if an optimized repository is absent or invalid.
- `build-optimized-repo.yml` can rebuild selected Debian source packages with x86-64-v3, x86-64-v4 or znver4 flags, create a signed APT repository and publish it to `apt-v3`, `apt-v4` or `apt-zen4`.

The selector never points a machine at an unpublished repository. Optimized branches become selectable only after a signed `InRelease` exists.

## 12. QA / release behavior — implemented

- `validate-cachyos-stack.sh` checks Python/shell syntax, JSON manifests, package ownership, kernel fallback, ZRAM/sysctl policy, SCX modes, Steam multiarch, Gamescope backports, Proton source, Secure Boot/MOK, NVIDIA modes, Flex Center wiring and the no-Arch-repo rule.
- `validate-cachyos-userspace.yml` runs on PR userspace changes and builds every FlexOS component `.deb` without compiling the kernel.
- The expensive kernel CI is isolated from normal FlexOS work.

## Release rules

1. FlexOS identity/branding always remains FlexOS.
2. Debian fallback kernel stays installed.
3. A driver switch must not silently bypass Secure Boot/DKMS safety.
4. Optimized repositories must pass signed `InRelease` health checking before selection.
5. External release downloads used by FlexOS management tools must be checksum-verified where the upstream API exposes a digest.
6. Base installation must remain bootable when optional SCX/Ananicy/gaming components are absent.
