#!/bin/bash

mkdir bld
cd bld

emcmake cmake .. -GNinja \\
      -Dtiff-tests=OFF \
      -Dtiff-tools=OFF \
      -Dtiff-docs=OFF \
      -DCMAKE_INSTALL_PREFIX=$PREFIX \
      -DCMAKE_PREFIX_PATH=$PREFIX \
      -DCMAKE_INSTALL_LIBDIR=lib \
      -DBUILD_SHARED_LIBS=OFF

ninja
ninja install
