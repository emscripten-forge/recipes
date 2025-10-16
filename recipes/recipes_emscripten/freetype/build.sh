mkdir build && cd build



export CFLAGS="${CFLAGS} -sRELOCATABLE=1 -fwasm-exceptions"
export LDFLAGS="${LDFLAGS} -sRELOCATABLE=1 -fwasm-exceptions"
export CXXFLAGS="${CXXFLAGS} -sRELOCATABLE=1 -fwasm-exceptions"

# NOTE: freetype needs to be compiled with atomics/bulk-memory features
# for use cases like cairo, pango etc.
emcmake cmake .. ${CMAKE_ARGS} \
    -DCMAKE_INSTALL_PREFIX=${PREFIX} \
<<<<<<< HEAD
    -DFT_DYNAMIC_HARFBUZZ=OFF \
=======
>>>>>>> 1359a2ea92ee4f32be658413ad70de426085b003
    -DCMAKE_C_FLAGS="-matomics -mbulk-memory -fwasm-exceptions" \
    -DCMAKE_CXX_FLAGS="-matomics -mbulk-memory -fwasm-exceptions" \
    -DCMAKE_EXE_LINKER_FLAGS="-matomics -mbulk-memory -fwasm-exceptions"

make install -j${CPU_COUNT}