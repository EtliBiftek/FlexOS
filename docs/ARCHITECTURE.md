# FlexOS Architecture

FlexOS 0.1 is a Debian derivative built as a Debian Live image.

## Layers

1. **Debian 13 / Trixie** supplies packages, security updates, kernel and firmware.
2. **live-build** creates the hybrid BIOS/UEFI live ISO.
3. **KDE Plasma 6** provides the desktop; the full `kde-full` metapackage is intentionally avoided.
4. **Calamares** installs the live filesystem. FlexOS reuses `calamares-settings-debian` for tested Debian-specific EFI, source and cleanup integration.
5. **FlexOS overlay** supplies `/etc/os-release`, branding, KDE defaults, wallpapers, installer launcher and boot visuals.

FlexOS does not currently maintain a custom binary package repository. Installed systems use Debian package repositories, which reduces maintenance and security risk for the early releases.
