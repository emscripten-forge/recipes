#!/usr/bin/env bash
set -euxo pipefail

PKG=image
VER=2.18.1
OCTVER=10.3.0

SRC_DIR=image
PKG_ROOT="$PREFIX/lib/octave/packages/${PKG}-${VER}"

mkdir -p "$PKG_ROOT"

test -d "$SRC_DIR/inst"

cp -r "$SRC_DIR/inst" "$PKG_ROOT/"

for f in DESCRIPTION PKG_ADD PKG_DEL; do
  [ -f "$SRC_DIR/$f" ] && cp "$SRC_DIR/$f" "$PKG_ROOT/"
done

[ -d "$SRC_DIR/doc" ] && cp -r "$SRC_DIR/doc" "$PKG_ROOT/" || true
