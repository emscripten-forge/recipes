#!/bin/bash
set -e

SRC_ROOT="${HOST_PREFIX:-$PREFIX}"
SRC_DIR="${SRC_ROOT}/lib/clang"
DEST_DIR="${PREFIX}/lib/clang"

if [ ! -d "$SRC_DIR" ]; then
    echo "ERROR: $SRC_DIR does not exist"
    exit 1
fi

mkdir -p "$DEST_DIR"
cp -a "$SRC_DIR/." "$DEST_DIR/"
