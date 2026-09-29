#!/bin/bash

export CFLAGS="${CFLAGS} -fwasm-exceptions"
export CXXFLAGS="${CXXFLAGS} -fwasm-exceptions"
export LDFLAGS="${LDFLAGS} -fwasm-exceptions"

CMAKE_COMMON_ARGS=(
    ${CMAKE_ARGS}
    -DCMAKE_BUILD_TYPE=Release
    -DCMAKE_PREFIX_PATH=$PREFIX
    -DCMAKE_INSTALL_PREFIX=$PREFIX
    -DLIBXML2_WITH_PYTHON=OFF
    -DLIBXML2_WITH_THREADS=OFF
    -DLIBXML2_WITH_TESTS=OFF
    # Programs (xmllint, xmlcatalog) link against the just-built libxml2.so
    # in the shared pass, whose NEEDED libz.so isn't on emcc's default
    # library path. They aren't part of what we ship anyway.
    -DLIBXML2_WITH_PROGRAMS=OFF
    -DLIBXML2_WITH_ZLIB=ON
    -DZLIB_INCLUDE_DIR=$PREFIX/include
    # Disable libiconv integration: cmake would otherwise auto-detect
    # the sysroot's iconv and produce a libxml2.so that imports
    # env.iconv_open / env.iconv_close / env.iconv. libxml2's built-in
    # encoders cover UTF-8, UTF-16, and the ISO-8859-* series, which is
    # what our downstream Python bindings need.
    -DLIBXML2_WITH_ICONV=OFF
)

# ---- static pass ----
# Links against libz.a (bakes zlib into libxml2.a) so downstreams that
# consume libxml2-static don't need a separate zlib .a at link time.
mkdir _build_static && cd _build_static
emcmake cmake .. \
    "${CMAKE_COMMON_ARGS[@]}" \
    -DBUILD_SHARED_LIBS=OFF \
    -DZLIB_LIBRARY=$PREFIX/lib/libz.a
emmake make -j${CPU_COUNT:-3}
emmake make install
cd ..

# ---- shared pass ----
# Links against libz.so so libxml2.so gets NEEDED libz.so in dylink.0;
# downstream shared consumers share one loaded copy of zlib at runtime.
# Runs second so libxml2's cmake config points at the shared target.
mkdir _build_shared && cd _build_shared
emcmake cmake .. \
    "${CMAKE_COMMON_ARGS[@]}" \
    -DBUILD_SHARED_LIBS=ON \
    -DZLIB_LIBRARY=$PREFIX/lib/libz.so
emmake make -j${CPU_COUNT:-3}
emmake make install
cd ..
