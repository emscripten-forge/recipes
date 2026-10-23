#!/bin/bash
set -euo pipefail

emcmake cmake ${CMAKE_ARGS} -S . -B build -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX:PATH="${PREFIX}" \
    -DBUILD_TESTING=OFF \
    -DEIGEN_BUILD_TESTING=OFF \
    -DEIGEN_BUILD_BLAS=OFF \
    -DEIGEN_BUILD_LAPACK=OFF \
    -DEIGEN_BUILD_BTL=OFF \
    -DEIGEN_BUILD_SPBENCH=OFF \
    -DEIGEN_BUILD_DOC=OFF \
    -DEIGEN_BUILD_DEMOS=OFF

emmake ninja -C build install
