#!/bin/bash
set -euxo pipefail

# matio as a static archive, with MAT 7.3 (HDF5) support from hdf5-static,
# in its own directories next to the matio package.
NAME="${PKG_NAME}"            # matio-static

emcmake cmake -S . -B _build -G "Unix Makefiles" \
    -DCMAKE_INSTALL_PREFIX="$PREFIX" \
    -DCMAKE_INSTALL_INCLUDEDIR="include/$NAME" \
    -DCMAKE_INSTALL_LIBDIR="lib/$NAME" \
    -DCMAKE_BUILD_TYPE=Release \
    -DMATIO_SHARED=OFF \
    -DMATIO_MAT73=ON -DMATIO_WITH_HDF5=ON -DMATIO_WITH_ZLIB=ON \
    -DMATIO_EXTENDED_SPARSE=ON \
    -DMATIO_BUILD_TESTING=OFF \
    -DHDF5_USE_STATIC_LIBRARIES=ON \
    -DHDF5_DIR="$PREFIX/lib/hdf5-static/cmake" \
    -DZLIB_INCLUDE_DIR="$PREFIX/include" \
    -DZLIB_LIBRARY="$PREFIX/lib/libz.a"
$(which cmake) --build _build -j"${CPU_COUNT:-2}"
$(which cmake) --install _build
# matio installs its CMake package files in $PREFIX/cmake whatever the
# install directories, where the matio package has its own: consumers of
# the archive use matio-static.pc
rm -f "$PREFIX"/cmake/matio*.cmake
rmdir "$PREFIX/cmake" 2>/dev/null || true

mkdir -p "$PREFIX/lib/pkgconfig" "$PREFIX/share/licenses/$NAME"
cat > "$PREFIX/lib/pkgconfig/$NAME.pc" <<EOF
prefix=$PREFIX
includedir=\${prefix}/include/$NAME
libdir=\${prefix}/lib/$NAME

Name: $NAME
Description: MATLAB MAT file I/O library, static, for emscripten-wasm32
Version: $PKG_VERSION
Requires.private: hdf5-static zlib
Libs: -L\${libdir} -lmatio
Cflags: -I\${includedir}
EOF
install -m 644 COPYING "$PREFIX/share/licenses/$NAME/COPYING"
