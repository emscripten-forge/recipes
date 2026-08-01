#!/bin/bash
set -e

SRC_ROOT="${HOST_PREFIX:-$PREFIX}"
SRC_DIR="${SRC_ROOT}/lib/clang"
DEST_DIR="${PREFIX}/lib/clang"
STAGING_DIR="${PWD}/staging"

if [ ! -d "$SRC_DIR" ]; then
    echo "ERROR: $SRC_DIR does not exist"
    exit 1
fi

mkdir -p "$STAGING_DIR/clang"
cp -a "$SRC_DIR/." "$STAGING_DIR/clang/"

# Start from an empty prefix so the restored headers are packaged as new content.
find "$PREFIX" -mindepth 1 -maxdepth 1 -exec rm -rf {} +

mkdir -p "$DEST_DIR"
cp -a "$STAGING_DIR/clang/." "$DEST_DIR/"
