# Changelog

## 0.5.0-beta.1-dev

Beta-development implementation:

- KDE Plasma 6 locked as the only supported FlexOS desktop.
- Flex Center and Flex Welcome expanded into the FlexOS management / OOBE layer.
- Flex Update Center with separate Debian-system and FlexOS-component update paths.
- FlexOS-authored components can be built as `flexos-*.deb` packages.
- Rolling `packages-latest` component release and SHA256-verified self-updater.
- Optional signed FlexOS APT repository publishing pipeline.
- Flex Driver Manager NVIDIA install and recovery/uninstall path.
- Btrfs + Snapper setup, pre-update snapshots and rollback tools.
- Flex Recovery systemd target and GRUB recovery / safe-graphics entries.
- Recovery TTY menu for package, initramfs, GRUB, network and NVIDIA recovery.
- Flex Performance zRAM / swappiness / power profiles.
- Flex Security and privacy controls.
- Flex System Report and installed-system beta verifier.
- Calamares post-install finalization and ext4/Btrfs beta filesystem choices.
- Modern FlexOS Calamares branding.
- Plymouth static `Starting` / `Stopping` text removed.
- CI source validation, component-package validation and QEMU live-kernel boot smoke test.
- Machine-readable beta QA matrix and strict tagged-release gate.
- Boot-time FlexOS services hardened with bounded startup time.

This version remains `-dev` until the required beta QA matrix passes.

## 0.1.0-alpha.1

Initial FlexOS source release:

- Debian 13 / KDE Plasma 6 live image definition
- FlexOS grey-black branding and wallpaper
- Calamares graphical installer integration
- Wayland and X11 desktop sessions
- NetworkManager, Bluetooth, PipeWire and common firmware
- BIOS/UEFI hybrid ISO configuration
- GRUB/Plymouth visual identity
- GitHub Actions ISO build and release automation
- Minimal explicit Plasma package selection with Wayland (`kwin-wayland`) and X11 fallback
- Rolling `dev-latest` GitHub prerelease plus version-tag releases
- Automatic release splitting/checksums for large ISO files
- Debian package availability/dependency preflight in CI
