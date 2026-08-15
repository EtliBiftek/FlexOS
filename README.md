# FlexOS

**FlexOS** is a clean, minimal, open-source Linux distribution created by **Pifo**. It is based on Debian 13 (Trixie), uses KDE Plasma 6, and ships a graphical Calamares installer.

> **Current status:** `0.1.0-alpha.1` — development preview. Do not use this alpha as your only operating system or on a machine without backups.

## Identity

- **Name:** FlexOS
- **Creator:** Pifo
- **Base:** Debian 13 (Trixie)
- **Desktop:** KDE Plasma 6
- **Installer:** Calamares
- **Architecture:** amd64 / x86_64
- **Official project:** https://github.com/EtliBiftek/FlexOS
- **Downloads:** GitHub Releases
- **Support / bugs:** GitHub Issues

There is intentionally no separate website yet. The GitHub repository is the canonical source for source code, downloads, documentation and support.

## Design goals

- A clean install with no office suite or large application bundle
- Modern KDE Plasma 6 desktop with Wayland and X11 sessions
- Dark grey / black FlexOS visual identity
- Live session before installation
- Graphical disk/user/locale setup through Calamares
- BIOS and UEFI boot support
- Useful firmware for common AMD/Intel/Wi-Fi hardware
- Reproducible-ish, reviewable ISO build configuration using Debian `live-build`

## Included desktop software

Dolphin, Konsole, Kate, Ark, Spectacle, Gwenview, Okular, Firefox ESR, System Monitor and the core KDE settings tools. Wi-Fi, Bluetooth and PipeWire audio are included.

## Build on Debian 13

```bash
sudo apt update
sudo apt install -y live-build debootstrap squashfs-tools xorriso isolinux syslinux-common grub-efi-amd64-bin grub-efi-amd64-signed shim-signed grub-pc-bin dosfstools mtools memtest86+
sudo ./build.sh
```

The build first validates the project and package selection. The result is named like:

```text
FlexOS-0.1.0-alpha.1-amd64.iso
FlexOS-0.1.0-alpha.1-amd64.iso.sha256
```

You can also develop from Windows without installing Linux locally: push the source tree to GitHub and run **Build FlexOS ISO** in GitHub Actions. Successful `main` builds replace the `dev-latest` prerelease; version tags create versioned releases. Oversized ISOs are automatically split into GitHub-compatible parts with reconstruction instructions.

See [`docs/INSTALL.md`](docs/INSTALL.md) for installation, [`docs/VERIFY.md`](docs/VERIFY.md) for checksum verification, and [`docs/KNOWN_ISSUES.md`](docs/KNOWN_ISSUES.md) before testing.

## Before real-hardware testing

Use a VM first. This is an alpha installer that can repartition disks. Keep backups. Secure Boot compatibility is not considered guaranteed until it is explicitly verified on the published ISO.

## License

FlexOS-authored project files are MIT licensed unless a file states otherwise. Software installed into the generated ISO remains under each upstream project's own license. FlexOS is based on Debian but is not produced or endorsed by the Debian Project or KDE.
