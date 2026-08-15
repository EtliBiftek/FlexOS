# Known limitations — 0.1.0-alpha.1

- The source tree is validated, but the first public GitHub Actions ISO build has not run yet.
- BIOS and UEFI installation must still be boot-tested in VMs after the first ISO is produced.
- Secure Boot is a target, not a verified feature, until the generated media is tested on compatible hardware.
- Proprietary GPU drivers (including NVIDIA's proprietary driver) are not bundled. FlexOS starts with Debian's default kernel/graphics stack.
- FlexOS has no separate package repository in 0.1; system packages and security updates come from Debian repositories.
- The project is alpha software and should not be used as the only copy of important data.
