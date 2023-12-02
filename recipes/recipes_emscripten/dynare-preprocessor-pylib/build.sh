#!/bin/bash

export BOOST_ROOT=$CONDA_PREFIX
meson setup --buildtype=release build_preproc -Dcpp_args='-pthread -w'  -Dcpp_link_args='-pthread -w' --cross-file="scripts/wasm32.ini"
meson compile -C build_preproc
meson install -C build_preproc #--destdir="../dist"
cp -r dist/usr/local/lib/ $PREFIX
# meson install -C build_preproc --libdir=$PREFIX
