mkdir build && cd build



export CFLAGS="${CFLAGS} -sRELOCATABLE=1 -fwasm-exceptions"
export LDFLAGS="${LDFLAGS} -sRELOCATABLE=1 -fwasm-exceptions"
export CXXFLAGS="${CXXFLAGS} -sRELOCATABLE=1 -fwasm-exceptions"

# NOTE: freetype needs to be compiled with atomics/bulk-memory features
# for use cases like cairo, pango etc.
emcmake cmake .. ${CMAKE_ARGS} \
    -DCMAKE_INSTALL_PREFIX=${PREFIX} \
    -DFT_DYNAMIC_HARFBUZZ=OFF \
    -DCMAKE_C_FLAGS="-matomics -mbulk-memory -fwasm-exceptions" \
    -DCMAKE_CXX_FLAGS="-matomics -mbulk-memory -fwasm-exceptions" \
    -DCMAKE_EXE_LINKER_FLAGS="-matomics -mbulk-memory -fwasm-exceptions"

make install -j${CPU_COUNT}