cp $RECIPE_DIR/emscripten.meson.cross $SRC_DIR

# write out the cross file
sed "s|@(PYTHON)|${PYTHON}|g" $SRC_DIR/emscripten.meson.cross > $SRC_DIR/emscripten.meson.new
mv $SRC_DIR/emscripten.meson.new $SRC_DIR/emscripten.meson.cross

cat $SRC_DIR/emscripten.meson.cross

# Emscripten flags for Python extension modules:
# -fPIC is required for building shared libraries (.so files) for WebAssembly/emscripten
# targets. Without it, wasm-ld will fail with relocation errors.
# - WASM_BIGINT: Enable big integer support
# - SIDE_MODULE=1: Build as side module for WebAssembly
# - MODULARIZE=1, LINKABLE=1, EXPORT_ALL=1: Export Python module initialization functions
# - fexceptions: Enable exception handling
FLAGS="-DNDEBUG -fPIC -s SIDE_MODULE=1 -fexceptions"
export CXXFLAGS="${CXXFLAGS} ${FLAGS}"
export CFLAGS="${CFLAGS} ${FLAGS}"
export LDFLAGS="${LDFLAGS} -s MODULARIZE=1 -s LINKABLE=1 -s EXPORT_ALL=1 -s WASM_BIGINT -s WASM=1 -s SIDE_MODULE=1 -fexceptions -L$PREFIX/lib"

${PYTHON} -m pip install . -vvv --no-deps --no-build-isolation \
    -Csetup-args="--cross-file=$SRC_DIR/emscripten.meson.cross"

