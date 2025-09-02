#!/bin/bash

mkdir build
cd build

# Configure step using emcmake
emcmake cmake ${CMAKE_ARGS} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=$PREFIX \
    -DCOOLPROP_STATIC_LIBRARY=ON \
    -DCOOLPROP_SHARED_LIBRARY=OFF \
    -DCOOLPROP_OBJECT_LIBRARY=OFF \
    -DBUILD_TESTING=OFF \
    -DCOOLPROP_NO_EXAMPLES=ON \
    -DCOOLPROP_EES_MODULE=OFF \
    -DCOOLPROP_WINDOWS_PACKAGE=OFF \
    -DCOOLPROP_DEBUG=OFF \
    -DCOOLPROP_RELEASE=ON \
    ..

# Build step using emmake
emmake make install