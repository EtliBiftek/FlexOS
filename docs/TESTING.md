# Testing FlexOS

For every release candidate:

1. Verify the SHA256 checksum.
2. Boot the ISO in a UEFI VM with at least 4 GiB RAM and 30 GiB virtual disk.
3. Verify Plasma starts, wallpaper/theme apply, networking and audio controls are present.
4. Open `Install FlexOS` and test erase-disk installation.
5. Boot the installed system, log in, update with `sudo apt update && sudo apt full-upgrade`.
6. Repeat installation with manual partitioning before calling a release stable.
7. Test a BIOS/legacy VM separately.
8. Only after VM success, test non-critical real hardware with backups.

The workflow also runs `scripts/smoke-test-iso.sh` to inspect the ISO boot structure.
