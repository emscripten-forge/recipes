#!/bin/bash

export OCTAVE_HOME="$PREFIX"
export MKOCTFILE="$PREFIX/bin/$HOST-mkoctfile"
export CC=emcc
export CXX=em++

PKG_DIR="$PREFIX/share/octave/packages/image-${PKG_VERSION}"

# Install .m files and packinfo (same tree for .oct files; no arch subdir).
mkdir -p "${PKG_DIR}/packinfo"
cp DESCRIPTION COPYING INDEX "${PKG_DIR}/packinfo/"
cp -r inst/* "${PKG_DIR}/"

cd src

./configure MKOCTFILE="$MKOCTFILE" CC="$CC" CXX="$CXX"
make MKOCTFILE="$MKOCTFILE" -j"${CPU_COUNT}"

cp *.oct "${PKG_DIR}/"

# Create empty files
: > "${PKG_DIR}/PKG_ADD"
: > "${PKG_DIR}/PKG_DEL"

# Collect PKG_ADD / PKG_DEL directives from sources (normally done by pkg install).
for f in *.cc ../inst/*.m; do
    [ -f "$f" ] || continue
    sed -n 's|^// PKG_ADD:[[:space:]]*||p; s|^## PKG_ADD:[[:space:]]*||p' "$f" >> "${PKG_DIR}/PKG_ADD"
    sed -n 's|^// PKG_DEL:[[:space:]]*||p; s|^## PKG_DEL:[[:space:]]*||p' "$f" >> "${PKG_DIR}/PKG_DEL"
done

