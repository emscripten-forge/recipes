#!/bin/bash
set -e

STAGING_DIR="$PWD/staging"
SRC_DIR="${PREFIX}/lib/clang"
DEST_DIR="${PREFIX}/lib/clang"

if [ ! -d "$SRC_DIR" ]; then
    echo "ERROR: $SRC_DIR does not exist"
    exit 1
fi

mkdir -p "$STAGING_DIR"
cp -r "$SRC_DIR" "$STAGING_DIR/clang"

rm -rf "$PREFIX"/*

mkdir -p "$DEST_DIR"
cp -r "$STAGING_DIR/clang/"* "$DEST_DIR"
