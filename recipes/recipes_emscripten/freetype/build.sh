mkdir build && cd build

# NOTE: freetype needs to be compiled with atomics/bulk-memory features
# for use cases like cairo, pango etc.
emcmake cmake .. ${CMAKE_ARGS} \
    -DCMAKE_INSTALL_PREFIX=${PREFIX} \
    -DFT_DYNAMIC_HARFBUZZ=OFF \
    -DCMAKE_C_FLAGS="-matomics -mbulk-memory"

make install -j${CPU_COUNT}