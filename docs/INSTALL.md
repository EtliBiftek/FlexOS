# Installing FlexOS

> FlexOS 0.1 is alpha software. Test in a VM first and back up real hardware.

1. Download the newest ISO (or numbered ISO parts) from this repository's GitHub Releases page.
2. If the release is split, reconstruct the ISO using `REASSEMBLE.txt` from the same release.
3. Verify the SHA256 checksum.
4. Write the ISO to a USB drive with a raw-image capable tool, or attach it to a VM.
5. Boot FlexOS and try the live desktop.
6. Open **Install FlexOS**.
7. In Calamares, choose language, keyboard, timezone, target disk/partitions and user credentials.
8. Review the partition summary carefully before confirming installation.
9. Reboot after Calamares finishes and remove the installation media.

The installer can modify or erase partitions. FlexOS cannot protect data that was not backed up before installation.
