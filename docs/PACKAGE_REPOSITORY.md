# FlexOS component updates and package repository

FlexOS 0.5 has two update paths:

1. Debian packages and security fixes continue to come from Debian APT repositories.
2. FlexOS-authored components are built as `.deb` packages:
   - flexos-base
   - flexos-branding
   - flexos-center
   - flexos-welcome
   - flexos-tools
   - flexos-calamares
   - flexos-plymouth

## Rolling component channel

GitHub Actions publishes a `packages-latest` prerelease containing the `.deb`
files, SHA256 checksums and `flexos-packages-manifest.json`.

Installed systems use:

```text
flex-self-update check
flex-self-update install
```

The updater verifies every package SHA256 before invoking the privileged
installer. This allows FlexOS tools to be fixed without rebuilding the ISO.

## Signed APT repository

`scripts/build-apt-repo.sh` creates a standard Debian repository.

For public use, configure these GitHub repository secrets:

- `FLEXOS_APT_GPG_PRIVATE_KEY` — armored private signing key
- `FLEXOS_APT_GPG_KEY_ID` — key fingerprint or signing key ID
- optional `FLEXOS_APT_GPG_PASSPHRASE`

The publishing workflow only publishes the APT branch when an `InRelease`
signature was created. Never commit the private key.

After GitHub Pages is configured to publish the `apt-repo` branch, users can
enable it through FlexOS tooling. The component-release updater remains a
fallback even if Pages is unavailable.
