#!/usr/bin/env bash
set -euxo pipefail

PKG=image
VER=2.18.1
OCTVER=10.3.0

SITE_OCT="$PREFIX/lib/octave/$OCTVER/site/oct/$PKG"
PKG_DIR="$PREFIX/lib/octave/packages/$PKG-$VER"

mkdir -p "$SITE_OCT"
mkdir -p "$PKG_DIR"

# Package metadata + m-files
cp DESCRIPTION "$PKG_DIR/"
cp -r inst "$PKG_DIR/"

[ -f PKG_ADD ] && cp PKG_ADD "$PKG_DIR/" || true
[ -f PKG_DEL ] && cp PKG_DEL "$PKG_DIR/" || true
[ -d doc ] && cp -r doc "$PKG_DIR/" || true

# Build oct-files
cd src

for src in *.cc; do
  mkoctfile \
    -O2 \
    -fPIC \
    -DEMCC \
    -DSIDE_MODULE=1 \
    "$src"
done

cp *.oct "$SITE_OCT"
