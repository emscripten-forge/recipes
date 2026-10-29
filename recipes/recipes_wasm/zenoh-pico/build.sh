#!/bin/bash
set -e

# Websocket transport only (the emscripten system layer has no TCP/UDP),
# and no multi-threading: the read/lease tasks are driven by the caller
emcmake cmake ${CMAKE_ARGS} -S . -B build \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=${PREFIX} \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_C_STANDARD=11 \
    -DBUILD_EXAMPLES=OFF \
    -DBUILD_TESTING=OFF \
    -DBUILD_INTEGRATION=OFF \
    -DBUILD_TOOLS=OFF \
    -DZ_FEATURE_MULTI_THREAD=0 \
    -DZ_FEATURE_LINK_WS=1 \
    -DZ_FEATURE_LINK_TCP=0 \
    -DZ_FEATURE_LINK_UDP_MULTICAST=0 \
    -DZ_FEATURE_LINK_UDP_UNICAST=0 \
    -DZ_FEATURE_SCOUTING_UDP=0

emmake make -C build install -j${CPU_COUNT}
