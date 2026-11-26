#!/bin/bash
set -eux

emcmake cmake ${CMAKE_ARGS} -S . -B build -GNinja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_PREFIX_PATH=$PREFIX \
    -DCMAKE_INSTALL_PREFIX=$PREFIX

ninja -C build
ninja -C build install
