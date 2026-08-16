# FlexOS updates

FlexOS separates upstream system packages from FlexOS-authored components.

## Debian system updates

Flex Center uses normal Debian APT sources for the kernel, KDE, libraries, firmware and other Debian packages.

## FlexOS component updates

FlexOS-authored files are packaged into:

- flexos-base
- flexos-branding
- flexos-center
- flexos-welcome
- flexos-tools
- flexos-calamares
- flexos-plymouth

The rolling component channel is published as the GitHub prerelease `packages-latest`.

Check:

```text
flex components check
```

Install:

```text
flex components install
```

Downloads are SHA256 verified before the `.deb` files are passed to the privileged updater.

## Update safety

When the root filesystem is Btrfs and Snapper is configured, FlexOS attempts to create a
snapshot before:

- full system updates
- FlexOS component updates
- NVIDIA driver installation/removal
- backports kernel installation
- system cleanup that removes packages

For ext4, the same operations work without snapshot rollback.
