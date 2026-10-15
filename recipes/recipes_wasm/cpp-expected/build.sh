#!/bin/bash

cmake ${CMAKE_ARGS} $SRC_DIR \
    -DCMAKE_INSTALL_PREFIX=$PREFIX \
    -DCMAKE_INSTALL_LIBDIR=lib
make install