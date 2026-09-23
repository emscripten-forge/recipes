mkdir build && cd build

export CFLAGS="${CFLAGS} -fwasm-exceptions"
export LDFLAGS="${LDFLAGS} -fwasm-exceptions"
export CXXFLAGS="${CXXFLAGS} -fwasm-exceptions"

# if pkg name is freetype, build shared,
# if its freetype-static build static
if [ "$PKG_NAME" = "freetype" ]; then
    BUILD_SHARED_LIBS=ON
    BUILD_STATIC_LIBS=OFF
elif [ "$PKG_NAME" = "freetype-static" ]; then
    BUILD_SHARED_LIBS=OFF
    BUILD_STATIC_LIBS=ON
else
    echo "Unknown package name: $PKG_NAME"
    exit 1
fi

# NOTE: freetype needs to be compiled with atomics/bulk-memory features
# for use cases like cairo, pango etc.
emcmake cmake .. ${CMAKE_ARGS} \
    -DCMAKE_INSTALL_PREFIX=${PREFIX} \
    -DFT_DYNAMIC_HARFBUZZ=OFF \
    -DCMAKE_C_FLAGS="-matomics -mbulk-memory -fwasm-exceptions" \
    -DCMAKE_CXX_FLAGS="-matomics -mbulk-memory -fwasm-exceptions" \
    -DBUILD_SHARED_LIBS=${BUILD_SHARED_LIBS} \
    -DBUILD_STATIC_LIBS=${BUILD_STATIC_LIBS} \
    -DCMAKE_EXE_LINKER_FLAGS="-matomics -mbulk-memory -fwasm-exceptions"

make install -j${CPU_COUNT}