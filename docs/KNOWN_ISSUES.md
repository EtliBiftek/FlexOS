# Known limitations — 0.9 development

- `0.9` is the current FlexOS development version. Required QA is tracked in `qa/test-matrix.json`.
- Secure Boot status and MOK enrollment are checked before automated DKMS driver switching, but Secure Boot is not advertised as a guaranteed release feature until its QA entry is explicitly passed.
- Proprietary NVIDIA drivers are not bundled into the ISO; Flex Driver Manager installs them only when the user requests it.
- Btrfs snapshot rollback requires a Btrfs root filesystem and a working Snapper root configuration. ext4 installations intentionally do not expose rollback as available.
- FlexOS component self-update uses the public `packages-latest` GitHub release. Component packages are downloaded and SHA256-verified inside root-owned staging before installation. A separately signed APT repository requires repository signing secrets and GitHub Pages configuration.
- Flex Sync is a local/synced-folder backup mechanism, not a FlexOS-hosted cloud service.
- VM graphics warnings can depend on the selected virtual GPU. Safe Graphics recovery is available for boot troubleshooting.
- Real-hardware Wi-Fi, Bluetooth, suspend/resume and NVIDIA coverage must be recorded per ISO build before a release is promoted.
