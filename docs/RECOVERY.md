# FlexOS Recovery

FlexOS 0.5 beta-development provides two recovery paths.

## From a working desktop

Open **Flex Center → Recovery**.

Available operations include:

- finish interrupted `dpkg` configuration
- repair broken APT dependencies
- rebuild APT indexes
- rebuild all initramfs images
- regenerate GRUB
- restart NetworkManager
- reset selected KDE configuration files after making backups
- remove a problematic proprietary NVIDIA driver

## When the graphical desktop does not start

GRUB should contain:

- `FlexOS Recovery`
- `FlexOS Recovery (Safe Graphics)`

The Safe Graphics entry additionally boots with `nomodeset`.

The recovery target opens a text UI on tty1. It can run package repair, GRUB/initramfs repair,
network recovery, NVIDIA removal and Btrfs/Snapper rollback.

All recovery actions write to:

```text
/var/log/flexos-recovery.log
```

Disk encryption still applies. FlexOS recovery does not bypass an encrypted root filesystem.
