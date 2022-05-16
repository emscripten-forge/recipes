mkdir build
cd build

# Configure step
cmake ${CMAKE_ARGS} ..              \
    -GNinja                         \
    -DCMAKE_PREFIX_PATH:PATH=${PREFIX} \
    -DCMAKE_INSTALL_PREFIX:PATH=${PREFIX} \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=FALSE \
    -DFMT_TEST=OFF \
    -DFMT_DOC=OFF \
    -DFMT_INSTALL=ON \
    
# Build step
ninja install
