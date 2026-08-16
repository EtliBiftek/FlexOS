# Known limitations — 0.5 beta development

- `0.5.0-beta.1-dev` is not the final 0.5 beta release. Required QA is tracked in `qa/test-matrix.json`.
- Secure Boot status is detected, but Secure Boot is not advertised as a guaranteed beta feature until its QA entry is explicitly passed.
- Proprietary NVIDIA drivers are not bundled into the ISO; Flex Driver Manager installs them only when the user requests it.
- Btrfs snapshot rollback requires a Btrfs root filesystem and a working Snapper root configuration. ext4 installations intentionally do not expose rollback as available.
- FlexOS component self-update uses the public `packages-latest` GitHub release. A separately signed APT repository requires repository signing secrets and GitHub Pages configuration.
- Flex Sync is a local/synced-folder backup mechanism, not a FlexOS-hosted cloud service.
- VM graphics warnings can depend on the selected virtual GPU. Safe Graphics recovery is available for boot troubleshooting.
- Real-hardware Wi-Fi, Bluetooth, suspend/resume and NVIDIA coverage must be recorded per ISO build before the 0.5 beta tag is allowed.
