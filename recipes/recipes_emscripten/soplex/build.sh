mkdir build
cd build
mkdir -p $PREFIX

export CPPFLAGS="$CPPFLAGS -I$PREFIX/include"
export LDFLAGS="$LDFLAGS -L$PREFIX/lib"

# Configure step
cmake ${CMAKE_ARGS} ..                          \
    -GNinja                                     \
    -DCMAKE_PREFIX_PATH:PATH=${PREFIX}          \
    -DCMAKE_INSTALL_PREFIX:PATH=${PREFIX}       \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON        \
    -DCMAKE_BUILD_TYPE=Release                  \
    -DZLIB_LIBRARY="${PREFIX}/lib/libz.a"       \
    -DZLIB_INCLUDE_DIR="${PREFIX}/include"      \
    -DGMP_INCLUDE_DIRS="${PREFIX}/include"      \
    -DGMP_LIBRARIES="${PREFIX}/lib/libgmp.a"    \
    -DMPFR_INCLUDE_DIRS="${PREFIX}/include"     \
    -DMPFR_LIBRARIES="${PREFIX}/lib/libmpfr.a"

ninja install

# Copy wasm files also
cp bin/*.wasm $PREFIX/bin/
