# cp $RECIPE_DIR/patches/CMakeLists.txt .

# mkdir build
# cd build

# export CMAKE_PREFIX_PATH=$PREFIX 
# export CMAKE_SYSTEM_PREFIX_PATH=$PREFIX 

# # Configure step
# cmake ${CMAKE_ARGS} ..              \
#     -GNinja                         \
#     -DCMAKE_BUILD_TYPE=Release      \
#     -DCMAKE_PREFIX_PATH=$PREFIX     \
#     -DCMAKE_INSTALL_PREFIX=$PREFIX  \
#     -DBUILD_SHARED_LIBS=OFF \
#     -DBZIP2_SKIP_TOOLS=OFF \
#     -DWITH_NODE_TESTS=OFF


# # Build step
# ninja install
#!/bin/bash
set -ex

emmake make \
    CC="${CC}" \
    AR="${AR}" \
    RANLIB="${RANLIB}" \
    CFLAGS="${CFLAGS}" \
    LDFLAGS="${LDFLAGS}" \
    PREFIX="${PREFIX}" \
    libbz2.a

mkdir -p "${PREFIX}/lib" "${PREFIX}/include"

cp libbz2.a "${PREFIX}/lib/"
cp bzlib.h "${PREFIX}/include/"