#!/bin/bash
set -e

SRC_DIR="${BUILD_PREFIX}/lib/clang"
DEST_DIR="${PREFIX}/lib/clang"

if [ ! -d "$SRC_DIR" ]; then
    echo " ERROR: $SRC_DIR does not exist. Ensure LLVM is installed in the build environment."
    exit 1
fi

mkdir -p "$DEST_DIR"
cp -r "$SRC_DIR"/* "$DEST_DIR"

echo "Copied everything from $SRC_DIR to $DEST_DIR"