#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  echo "Run with sudo: sudo ./clean.sh" >&2
  exit 1
fi
command -v lb >/dev/null 2>&1 && lb clean --purge || true
rm -rf .build-tmp release-assets
rm -rf config/binary config/bootstrap config/bootloaders config/chroot config/common config/source
rm -f FlexOS-*.iso FlexOS-*.iso.sha256 build.log
