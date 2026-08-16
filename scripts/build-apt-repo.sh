#!/usr/bin/env bash
set -Eeuo pipefail

PACKAGES_DIR="${1:-dist/packages}"
OUT="${2:-dist/aptrepo}"
SUITE="${FLEXOS_APT_SUITE:-beta}"

command -v dpkg-scanpackages >/dev/null || { echo "dpkg-scanpackages is required (dpkg-dev)." >&2; exit 1; }
command -v apt-ftparchive >/dev/null || { echo "apt-ftparchive is required (apt-utils)." >&2; exit 1; }

rm -rf "$OUT"
mkdir -p "$OUT/pool/main/f/flexos" "$OUT/dists/$SUITE/main/binary-amd64"

cp "$PACKAGES_DIR"/flexos-*.deb "$OUT/pool/main/f/flexos/"

(
  cd "$OUT"
  dpkg-scanpackages pool/main/f/flexos /dev/null > "dists/$SUITE/main/binary-amd64/Packages"
  gzip -9c "dists/$SUITE/main/binary-amd64/Packages" > "dists/$SUITE/main/binary-amd64/Packages.gz"

  apt-ftparchive \
    -o "APT::FTPArchive::Release::Origin=FlexOS" \
    -o "APT::FTPArchive::Release::Label=FlexOS" \
    -o "APT::FTPArchive::Release::Suite=$SUITE" \
    -o "APT::FTPArchive::Release::Codename=$SUITE" \
    -o "APT::FTPArchive::Release::Architectures=amd64 all" \
    -o "APT::FTPArchive::Release::Components=main" \
    -o "APT::FTPArchive::Release::Description=FlexOS authored package repository" \
    release "dists/$SUITE" > "dists/$SUITE/Release"
)

if [[ -n "${FLEXOS_APT_GPG_KEY_ID:-}" ]]; then
  gpg_extra=(--batch --yes)
  if [[ -n "${FLEXOS_APT_GPG_PASSPHRASE:-}" ]]; then
    gpg_extra+=(--pinentry-mode loopback --passphrase "$FLEXOS_APT_GPG_PASSPHRASE")
  fi
  gpg "${gpg_extra[@]}" --armor --detach-sign \
    --local-user "$FLEXOS_APT_GPG_KEY_ID" \
    -o "$OUT/dists/$SUITE/Release.gpg" "$OUT/dists/$SUITE/Release"
  gpg "${gpg_extra[@]}" --clearsign \
    --local-user "$FLEXOS_APT_GPG_KEY_ID" \
    -o "$OUT/dists/$SUITE/InRelease" "$OUT/dists/$SUITE/Release"
  gpg --batch --yes --armor --export "$FLEXOS_APT_GPG_KEY_ID" > "$OUT/flexos-archive-keyring.asc"
  echo "Signed FlexOS APT repository created."
else
  echo "Unsigned APT repository created. Do NOT enable it for users until it is signed." >&2
fi

cat > "$OUT/index.html" <<EOF
<!doctype html>
<meta charset="utf-8">
<title>FlexOS Package Repository</title>
<h1>FlexOS Package Repository</h1>
<p>Suite: $SUITE</p>
<p>This repository contains FlexOS-authored packages. Debian system packages continue to come from Debian.</p>
EOF
