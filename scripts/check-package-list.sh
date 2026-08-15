#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

pkgfile="config/package-lists/flexos.list.chroot"
mapfile -t packages < <(grep -Ev '^\s*(#|$)' "$pkgfile")

if ! command -v apt-cache >/dev/null 2>&1; then
  echo "ERROR: apt-cache is required." >&2
  exit 1
fi

missing=()
for pkg in "${packages[@]}"; do
  if ! apt-cache show --no-all-versions "$pkg" >/dev/null 2>&1; then
    missing+=("$pkg")
  fi
done

if (( ${#missing[@]} )); then
  printf 'ERROR: package(s) unavailable in configured Debian repositories:\n' >&2
  printf '  - %s\n' "${missing[@]}" >&2
  exit 1
fi

echo "All ${#packages[@]} FlexOS packages are present in the configured repositories."

if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
  # Dependency resolution only; this downloads/installs nothing.
  DEBIAN_FRONTEND=noninteractive apt-get -s --no-install-recommends install "${packages[@]}" >/tmp/flexos-apt-simulate.log
  echo "APT dependency simulation passed."
fi
