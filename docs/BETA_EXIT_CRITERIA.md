# FlexOS 0.5 Beta exit criteria

`0.5.0-beta.1` must not be tagged until every required item in
`qa/test-matrix.json` is marked `pass`.

Required release gates:

- Source validation and FlexOS package build pass.
- ISO structural smoke test passes.
- CI live-kernel boot reaches `multi-user.target`.
- KDE-only installer completes repeatedly on clean VMs.
- UEFI and legacy BIOS installation are both verified.
- ext4 and Btrfs installations are verified.
- Reboot and shutdown loops are stable.
- Installed system has no live-user autologin.
- Flex Welcome and Flex Center start successfully.
- Flex Update and FlexOS component self-update are verified.
- Flex Recovery is reachable from GRUB / recovery mode.
- Btrfs snapshot creation and rollback are verified.
- NVIDIA install and NVIDIA removal/recovery are verified on NVIDIA hardware.
- Wi-Fi, Bluetooth and audio have at least one real-hardware pass.
- No open critical boot, data-loss, installer or update bug is accepted for beta.

The tag workflow runs `scripts/beta-gate.py --strict`.
A development build may be created with pending manual QA; a beta tag may not.
