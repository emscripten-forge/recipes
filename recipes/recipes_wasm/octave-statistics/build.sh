#!/bin/bash

export OCTAVE_HOME="$PREFIX"
export MKOCTFILE="$PREFIX/bin/$HOST-mkoctfile"
export CC=emcc
export CXX=em++

PKG_DIR="$PREFIX/share/octave/packages/statistics-${PKG_VERSION}"

mkdir -p "${PKG_DIR}/packinfo"
cp DESCRIPTION COPYING INDEX "${PKG_DIR}/packinfo/"
cp -r inst/* "${PKG_DIR}/"

make -C src MKOCTFILE="$MKOCTFILE" -j"${CPU_COUNT}"
cp src/*.oct "${PKG_DIR}/"
