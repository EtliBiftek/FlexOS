# Verifying a FlexOS download

Every release includes a checksum for the original ISO. After reconstructing a split release, verify it before booting.

## Linux

```bash
sha256sum -c FlexOS-*.iso.sha256
```

## Windows PowerShell

```powershell
Get-FileHash .\FlexOS-*.iso -Algorithm SHA256
```

Compare the displayed hash with the first value in the matching `.iso.sha256` file from the release.
