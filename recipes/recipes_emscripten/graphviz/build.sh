#!/bin/bash
set -exuo pipefail

# Set default values for potentially unset variables
EM_FORGE_SIDE_MODULE_CFLAGS="${EM_FORGE_SIDE_MODULE_CFLAGS:-}"
CFLAGS="${CFLAGS:-}"
CXXFLAGS="${CXXFLAGS:-}"
LDFLAGS="${LDFLAGS:-}"

export CFLAGS="$CFLAGS $EM_FORGE_SIDE_MODULE_CFLAGS"
export CXXFLAGS="$CXXFLAGS $EM_FORGE_SIDE_MODULE_CFLAGS"
export LDFLAGS="$LDFLAGS -L${PREFIX}/lib"

# Upstream creates non-suffixed alias symlinks for dot (circo, fdp, ...),
# but Emscripten installs executables with a .js suffix. Make the alias names
# include the executable suffix so `ninja install` can find circo.js, etc.
sed -i '/create_symlink \$<TARGET_FILE_NAME:dot>/{n;s/${cmd_alias}/${cmd_alias}${CMAKE_EXECUTABLE_SUFFIX}/;}' \
    "${SRC_DIR}/cmd/dot/CMakeLists.txt"
sed -i '/create_symlink \$<TARGET_FILE_NAME:gxl2gv>/{n;s/${cmd_alias}/${cmd_alias}${CMAKE_EXECUTABLE_SUFFIX}/;}' \
    "${SRC_DIR}/cmd/tools/CMakeLists.txt"

mkdir -p build
cd build

emcmake cmake -GNinja \
    ${CMAKE_ARGS} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_PREFIX_PATH="${PREFIX}" \
    -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=BOTH \
    -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=BOTH \
    -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=BOTH \
    -DBUILD_SHARED_LIBS=OFF \
    -DGRAPHVIZ_CLI=ON \
    -Dwith_cxx_api=ON \
    -DENABLE_LTDL=OFF \
    -DENABLE_SWIG=OFF \
    -DENABLE_PYTHON=OFF \
    -DWITH_EXPAT=ON \
    -DWITH_WEBP=ON \
    -DWITH_ZLIB=ON \
    -DZLIB_LIBRARY="${PREFIX}/lib/libz.a" \
    -DWITH_GDK=OFF \
    -DWITH_GHOSTSCRIPT=OFF \
    -DWITH_GTK=OFF \
    -DWITH_POPPLER=OFF \
    -DWITH_QUARTZ=OFF \
    -DWITH_RSVG=OFF \
    -DWITH_X=OFF \
    -DWITH_GVEDIT=OFF \
    -DWITH_SMYRNA=OFF \
    -DENABLE_TCL=OFF \
    -DENABLE_SHARP=OFF \
    -DENABLE_D=OFF \
    -DENABLE_GO=OFF \
    -DENABLE_GUILE=OFF \
    -DENABLE_JAVA=OFF \
    -DENABLE_JAVASCRIPT=OFF \
    -DENABLE_LUA=OFF \
    -DENABLE_PERL=OFF \
    -DENABLE_PHP=OFF \
    -DENABLE_R=OFF \
    -DENABLE_RUBY=OFF \
    -DCMAKE_DISABLE_FIND_PACKAGE_PANGOCAIRO=ON \
    -DCMAKE_DISABLE_FIND_PACKAGE_ANN=ON \
    -DCMAKE_DISABLE_FIND_PACKAGE_CAIRO=ON \
    -DCMAKE_DISABLE_FIND_PACKAGE_GD=ON \
    -DCMAKE_DISABLE_FIND_PACKAGE_GTS=ON \
    -DCMAKE_DISABLE_FIND_PACKAGE_GLUT=ON \
    -DCMAKE_DISABLE_FIND_PACKAGE_GS=ON \
    -DCMAKE_DISABLE_FIND_PACKAGE_GTK2=ON \
    -DMATH_LIB= \
    "${SRC_DIR}"

# The zlib recipe exposes libz.so as well, but wasm-ld requires the static
# archive. Force any generated CMake metadata to use libz.a.
find . -type f -name '*.cmake' -exec sed -i 's|libz\.so|libz.a|g' {} + 2>/dev/null || true

ninja install

# Upstream only installs a subset of the static archives. The remaining
# support libraries and built-in plugins are still required to consume libgvc
# from a static Emscripten package, so stage them into $PREFIX/lib as well.
for archive in \
    lib/common/libcommon.a \
    lib/pack/libpack.a \
    lib/util/libutil.a \
    lib/label/liblabel.a \
    lib/dotgen/libdotgen.a \
    lib/ortho/libortho.a \
    plugin/core/libgvplugin_core.a \
    plugin/dot_layout/libgvplugin_dot_layout.a \
    plugin/webp/libgvplugin_webp.a
do
    if [ -f "${archive}" ]; then
        install -Dm644 "${archive}" "${PREFIX}/lib/$(basename "${archive}")"
    fi
done

if [ -f "${PWD}/cmd/dot/dot.js" ]; then
    install -Dm755 "${PWD}/cmd/dot/dot.js" "${PREFIX}/bin/dot.js"
fi
if [ -f "${PWD}/cmd/dot/dot.wasm" ]; then
    install -Dm644 "${PWD}/cmd/dot/dot.wasm" "${PREFIX}/bin/dot.wasm"
fi

mkdir -p "${PREFIX}/lib/cmake/Graphviz"
install -Dm644 "${RECIPE_DIR}/GraphvizConfig.cmake" \
    "${PREFIX}/lib/cmake/Graphviz/GraphvizConfig.cmake"

# Remove .la files if any
find "${PREFIX}" -name '*.la' -delete 2>/dev/null || true
