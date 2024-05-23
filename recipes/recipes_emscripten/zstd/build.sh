#!/bin/bash

set -ex

cd build/meson

meson setup \
  -Dbin_programs=true \
  -Dbin_contrib=true \
  -Dmulti_thread=disabled \
  -Dzlib=disabled \
  -Dlzma=disabled \
  -Dlz4=disabled \
  -Ddefault_library=static \
  --prefix=$PREFIX \
  --wrap-mode=nofallback \
  --cross-file=$RECIPE_DIR/emscripten.meson.cross \
  builddir

cd builddir
ninja
ninja install

# Fix symbolic links
cd $PREFIX/bin
rm unzstd zstdcat
ln -s ./zstd.js unzstd
ln -s ./zstd.js zstdcat
ln -s ./zstd.js zstd
