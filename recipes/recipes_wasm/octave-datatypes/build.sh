#!/bin/bash

export OCTAVE_HOME="$PREFIX"
export MKOCTFILE="$PREFIX/bin/$HOST-mkoctfile"
export CC=emcc
export CXX=em++

PKG_DIR="$PREFIX/share/octave/packages/datatypes-${PKG_VERSION}"

mkdir -p "${PKG_DIR}/packinfo"
cp DESCRIPTION COPYING INDEX "${PKG_DIR}/packinfo/"
cp -r inst/* "${PKG_DIR}/"

make -C src MKOCTFILE="$MKOCTFILE" TZFLAGS="-DHAS_REMOTE_API=0 -DINSTALL=." -j"${CPU_COUNT}"
cp src/*.oct "${PKG_DIR}/"
