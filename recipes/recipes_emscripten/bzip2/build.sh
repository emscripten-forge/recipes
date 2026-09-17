cp $RECIPE_DIR/patches/CMakeLists.txt .

mkdir build
cd build

export CMAKE_PREFIX_PATH=$PREFIX 
export CMAKE_SYSTEM_PREFIX_PATH=$PREFIX 

# Configure step
cmake ${CMAKE_ARGS} ..              \
    -GNinja                         \
    -DCMAKE_BUILD_TYPE=Release      \
    -DCMAKE_PREFIX_PATH=$PREFIX     \
    -DCMAKE_INSTALL_PREFIX=$PREFIX  \
    -DBUILD_SHARED_LIBS=OFF \
    -DBZIP2_SKIP_TOOLS=OFF \
    -DWITH_NODE_TESTS=OFF


# Build step
ninja install

# pkg-config file. Without it, pkg-config consumers fall back to the host's
# /usr/lib/pkgconfig/bzip2.pc (the conda pkg-config wrapper always searches the
# system dirs) and leak -I/usr/include into emscripten builds.
mkdir -p "${PREFIX}/lib/pkgconfig"
cat > "${PREFIX}/lib/pkgconfig/bzip2.pc" <<EOF
prefix=${PREFIX}
libdir=\${prefix}/lib
includedir=\${prefix}/include

Name: bzip2
Description: Lossless, block-sorting data compression
Version: ${PKG_VERSION}
Libs: -L\${libdir} -lbz2
Cflags: -I\${includedir}
EOF
