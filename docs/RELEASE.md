# FlexOS Release Process

1. Update `VERSION`, `CHANGELOG.md` and `/etc/os-release` build metadata.
2. Run `./scripts/validate.sh`.
3. Push to `main`; let GitHub Actions build and smoke-test the ISO.
4. Test the workflow artifact in UEFI and BIOS VMs.
5. Create and push a tag such as `v0.1.0-alpha.1`.
6. The workflow creates the GitHub Release and uploads the ISO and SHA256 file.
7. Publish known issues in the GitHub Release and GitHub Issues.

## Large ISO handling

GitHub Release assets have a per-file size limit. `scripts/package-release.sh`
keeps every uploaded asset below that limit. If the ISO exceeds 1800 MiB, the
release contains numbered parts plus `REASSEMBLE.txt`, `SHA256SUMS`, and the
checksum of the original ISO.

The `dev-latest` prerelease is replaced on every successful `main` build. Stable
or milestone builds are published by pushing a version tag such as
`v0.1.0-alpha.1`.
