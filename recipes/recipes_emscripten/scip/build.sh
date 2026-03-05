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
    -DCMAKE_INSTALL_LIBDIR=lib                  \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON        \
    -DCMAKE_BUILD_TYPE=Release                  \
    -DSHARED=OFF                                \
    -DREADLINE=OFF                              \
    -DZLIB_LIBRARY="${PREFIX}/lib/libz.a"       \
    -DZLIB_INCLUDE_DIR="${PREFIX}/include"      \
    -DSTATIC_GMP=ON                             \
    -DGMP_DIR="${PREFIX}"                       \
    -DGMP_INCLUDE_DIRS="${PREFIX}/include"      \
    -DGMP_LIBRARY="${PREFIX}/lib/libgmp.a"      \
    -DMPFR_DIR="${PREFIX}"                      \
    -DMPFR_INCLUDE_DIRS="${PREFIX}/include"     \
    -DMPFR_LIBRARY="${PREFIX}/lib/libmpfr.a"    \
    -DPAPILO=OFF                                \
    -DZIMPL=OFF                                 \
    -DIPOPT=OFF

ninja install

# Copy wasm files also
cp bin/*.wasm $PREFIX/bin/
