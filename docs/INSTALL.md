# Installing FlexOS

FlexOS 0.5 beta-development uses Calamares and KDE Plasma 6.

## Before installation

- Back up important data.
- Verify the ISO SHA256.
- Test the ISO in a VM before real hardware.
- Do not assume Secure Boot compatibility until the exact ISO has been tested.

## Filesystem choice

The beta installer exposes:

- **ext4** — conservative default
- **Btrfs** — enables Flex Snapshot / Snapper rollback after installation

Disk encryption remains available through Calamares where supported by the selected partitioning mode.

## After installation

FlexOS post-install finalization:

- removes live-session SDDM autologin configuration
- records KDE as the FlexOS desktop
- configures Snapper automatically when `/` is Btrfs
- enables core FlexOS services
- regenerates initramfs and GRUB, including FlexOS Recovery entries

At first login, Flex Welcome starts the OOBE.

For beta QA, run `flex beta-check` or create a Flex System Report from Flex Center.
