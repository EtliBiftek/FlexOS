# Building FlexOS

## Supported builder

Debian 13 amd64 is the reference build environment. Root privileges are required because `live-build` uses chroots and mounts.

## Dependencies

```bash
sudo apt update
sudo apt install -y live-build debootstrap squashfs-tools xorriso isolinux syslinux-common grub-efi-amd64-bin grub-efi-amd64-signed shim-signed grub-pc-bin dosfstools mtools memtest86+
```

## Build

If the source came from an archive that did not preserve executable bits:

```bash
chmod +x build.sh clean.sh scripts/*.sh config/hooks/live/*.hook.chroot
chmod +x config/includes.chroot/usr/bin/flexos-* config/includes.chroot/usr/lib/flexos/flexos-first-login
```

Then build:

```bash
sudo ./build.sh
```

Run `sudo ./clean.sh` to discard generated live-build state.

## Windows development

Windows is fine for editing the repository. ISO assembly should run in GitHub Actions or a Linux VM because privileged mount/chroot operations are required.

## Validation

`./scripts/validate.sh` validates repository structure and syntax. On a Debian builder with package indexes enabled, `sudo ./scripts/check-package-list.sh` also verifies that every selected package exists and that APT can resolve the set without downloading it.
