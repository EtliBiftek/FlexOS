# FlexOS

**FlexOS** is an open-source Debian 13 (Trixie) based desktop Linux distribution created by **Pifo**.
FlexOS uses **KDE Plasma 6 as its only supported desktop** and provides its own management, recovery,
update and first-run tools.

> Current development version: **0.9**. This is a development build, not a declared stable release.

## FlexOS identity

- Creator: Pifo
- Base: Debian 13 (Trixie)
- Desktop: KDE Plasma 6
- Installer: Calamares
- Architecture: amd64 / x86_64
- Kernel: FlexOS CachyOS-derived kernel
- Package manager: APT / dpkg
- FlexOS-authored component updates: `.deb` packages + `flex-self-update`
- Project / downloads / support: GitHub (`EtliBiftek/FlexOS`)

FlexOS is based on Debian but is not produced or endorsed by the Debian Project, KDE, or CachyOS.

## Download FlexOS 0.9

Development ISO files are published in the [`dev-latest`](https://github.com/EtliBiftek/FlexOS/releases/tag/dev-latest) release.

Because the ISO is larger than the per-file upload size used by the release pipeline, it is published in multiple parts:

```text
FlexOS-0.9-amd64.iso.part-00
FlexOS-0.9-amd64.iso.part-01
FlexOS-0.9-amd64.iso.sha256
```

Download **all ISO parts** into the same folder, then join them using the instructions below.
Do not rename individual parts before joining them.

### Windows

#### Command Prompt

Open Command Prompt in the folder containing both parts and run:

```bat
copy /b FlexOS-0.9-amd64.iso.part-00+FlexOS-0.9-amd64.iso.part-01 FlexOS-0.9-amd64.iso
```

You should now have:

```text
FlexOS-0.9-amd64.iso
```

#### PowerShell

You can also combine the files from PowerShell:

```powershell
$parts = @(
    "FlexOS-0.9-amd64.iso.part-00",
    "FlexOS-0.9-amd64.iso.part-01"
)

$out = [System.IO.File]::Create("FlexOS-0.9-amd64.iso")
try {
    foreach ($part in $parts) {
        $in = [System.IO.File]::OpenRead($part)
        try {
            $in.CopyTo($out)
        }
        finally {
            $in.Dispose()
        }
    }
}
finally {
    $out.Dispose()
}
```

To verify the finished ISO in PowerShell:

```powershell
Get-FileHash .\FlexOS-0.9-amd64.iso -Algorithm SHA256
Get-Content .\FlexOS-0.9-amd64.iso.sha256
```

The SHA-256 value printed by `Get-FileHash` must match the hash stored in
`FlexOS-0.9-amd64.iso.sha256`.

### Linux

Open a terminal in the directory containing both parts and run:

```bash
cat FlexOS-0.9-amd64.iso.part-00 \
    FlexOS-0.9-amd64.iso.part-01 \
    > FlexOS-0.9-amd64.iso
```

Verify the finished ISO:

```bash
sha256sum -c FlexOS-0.9-amd64.iso.sha256
```

A successful verification should report:

```text
FlexOS-0.9-amd64.iso: OK
```

After verification, the resulting `FlexOS-0.9-amd64.iso` can be written to a USB drive with a tool such as Rufus, Ventoy, KDE ISO Image Writer, GNOME Disks, or another raw ISO-writing tool.

## FlexOS System Suite

The 0.9 development tree includes:

- Flex Center
- Flex Welcome / OOBE
- Flex Profiles
- Flex Update Center
- Flex Driver Manager
- Flex Snapshot (Btrfs + Snapper)
- Flex Recovery, including GRUB recovery entries
- Flex Performance (power profiles, zRAM, swappiness)
- Flex Hardware Recommendations
- Flex App Installer (APT and optional Flatpak/Flathub)
- Flex Cleanup
- Flex Boot & Kernel Manager
- Flex Logs
- Flex Backup and local-folder Flex Sync
- Flex Privacy and Flex Security
- Flex System Report
- FlexOS component package/self-update pipeline

## Build

On Debian 13:

```bash
sudo apt update
sudo apt install -y live-build debootstrap squashfs-tools xorriso isolinux \
  syslinux-common grub-efi-amd64-bin grub-efi-amd64-signed shim-signed \
  grub-pc-bin dosfstools mtools memtest86+ ca-certificates
sudo ./build.sh
```

GitHub Actions is the primary reproducible build path for development releases.

## Beta release policy

The repository contains a machine-readable test matrix in `qa/test-matrix.json`.
A version tag is blocked by CI unless the required manual tests are marked as passed and all
automated checks succeed.

See:

- `docs/BETA_EXIT_CRITERIA.md`
- `docs/BETA_TEST_MATRIX.md`
- `docs/INSTALL.md`
- `docs/RECOVERY.md`
- `docs/UPDATES.md`
- `docs/KNOWN_ISSUES.md`

## Warning

FlexOS 0.9 development builds are for testing. Keep backups and do not use a development build as the
only copy of important data until its release gates are complete.
