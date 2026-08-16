# FlexOS

**FlexOS** is an open-source Debian 13 (Trixie) based desktop Linux distribution created by **Pifo**.
FlexOS uses **KDE Plasma 6 as its only supported desktop** and provides its own management, recovery,
update and first-run tools.

> Current source status: **0.5.0-beta.1-dev**. This is beta-development source, not a declared stable release.

## FlexOS identity

- Creator: Pifo
- Base: Debian 13 (Trixie)
- Desktop: KDE Plasma 6
- Installer: Calamares
- Architecture: amd64 / x86_64
- Package manager: APT / dpkg
- FlexOS-authored component updates: `.deb` packages + `flex-self-update`
- Project / downloads / support: GitHub (`EtliBiftek/FlexOS`)

FlexOS is based on Debian but is not produced or endorsed by the Debian Project or KDE.

## FlexOS System Suite

The 0.5 beta-development tree includes:

- Flex Center
- Flex Welcome / OOBE
- Flex Profiles
- Flex Update Center
- Flex Driver Manager
- Flex Snapshot (Btrfs + Snapper)
- Flex Recovery, including GRUB recovery entries
- Flex Performance (power profiles, zRAM, swappiness)
- Flex Hardware Recommendations
- Flex App Installer (APT and optional Flatpak/Flathub)
- Flex Cleanup
- Flex Boot & Kernel Manager
- Flex Logs
- Flex Backup and local-folder Flex Sync
- Flex Privacy and Flex Security
- Flex System Report
- FlexOS component package/self-update pipeline

## Build

On Debian 13:

```bash
sudo apt update
sudo apt install -y live-build debootstrap squashfs-tools xorriso isolinux \
  syslinux-common grub-efi-amd64-bin grub-efi-amd64-signed shim-signed \
  grub-pc-bin dosfstools mtools memtest86+ ca-certificates
sudo ./build.sh
```

GitHub Actions is the primary reproducible build path for development releases.

## Beta release policy

The repository contains a machine-readable test matrix in `qa/test-matrix.json`.
A `v0.5...` tag is blocked by CI unless required manual tests are marked as passed and all
automated checks succeed.

See:

- `docs/BETA_EXIT_CRITERIA.md`
- `docs/BETA_TEST_MATRIX.md`
- `docs/INSTALL.md`
- `docs/RECOVERY.md`
- `docs/UPDATES.md`
- `docs/KNOWN_ISSUES.md`

## Warning

0.5 beta-development builds are for testing. Keep backups and do not use a beta build as the
only copy of important data until its release gates are complete.
