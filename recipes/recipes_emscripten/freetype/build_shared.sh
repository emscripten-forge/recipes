mkdir build && cd build

export CFLAGS="${CFLAGS} -sRELOCATABLE=1 -fwasm-exceptions"
export LDFLAGS="${LDFLAGS} -sRELOCATABLE=1 -fwasm-exceptions"
export CXXFLAGS="${CXXFLAGS} -sRELOCATABLE=1 -fwasm-exceptions"

emcmake cmake .. ${CMAKE_ARGS} \
    -GNinja \
    -DCMAKE_INSTALL_PREFIX=${PREFIX} \
    -DCMAKE_BUILD_TYPE=Release \
    -DFT_DYNAMIC_HARFBUZZ=OFF \
    -DBUILD_SHARED_LIBS=ON \
    -DCMAKE_PROJECT_INCLUDE=${RECIPE_DIR}/overwriteProp.cmake \
    -DCMAKE_C_FLAGS="-matomics -mbulk-memory -fwasm-exceptions" \
    -DCMAKE_CXX_FLAGS="-matomics -mbulk-memory -fwasm-exceptions" \
    -DCMAKE_EXE_LINKER_FLAGS="-matomics -mbulk-memory -fwasm-exceptions"

ninja install -j${CPU_COUNT}
