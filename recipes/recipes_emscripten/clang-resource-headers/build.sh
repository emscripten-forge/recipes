#!/bin/bash
set -euo pipefail

STAGING_DIR="$PWD/staging"
SRC_DIR="${PREFIX}/lib/clang"
DEST_DIR="${PREFIX}/lib/clang"

LICENSE_SRC="${PREFIX}/info/licenses/LICENSE.TXT"
LICENSE_STAGED="${STAGING_DIR}/LICENSE.TXT"
LICENSE_DEST="${PREFIX}/info/licenses/LICENSE.TXT"

if [ ! -d "$SRC_DIR" ]; then
  echo "ERROR: $SRC_DIR does not exist"
  exit 1
fi

if [ ! -f "$LICENSE_SRC" ]; then
  echo "ERROR: $LICENSE_SRC not found"
  exit 1
fi

mkdir -p "$STAGING_DIR"
cp -r "$SRC_DIR" "$STAGING_DIR/clang"
cp -v "$LICENSE_SRC" "$LICENSE_STAGED"

rm -rf "${PREFIX:?}"/*

mkdir -p "$DEST_DIR"
cp -r "$STAGING_DIR/clang/"* "$DEST_DIR"

mkdir -p "$(dirname "$LICENSE_DEST")"
cp -v "$LICENSE_STAGED" "$LICENSE_DEST"
