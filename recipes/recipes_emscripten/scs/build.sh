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
# - fexceptions: Enable exception handling
FLAGS="-DNDEBUG -fPIC -sWASM_BIGINT -s SIDE_MODULE=1 -fexceptions"
export CXXFLAGS="${CXXFLAGS} ${FLAGS}"
export CFLAGS="${CFLAGS} ${FLAGS}"
export LDFLAGS="${LDFLAGS} -sWASM_BIGINT -s SIDE_MODULE=1 -fexceptions -L$PREFIX/lib"

${PYTHON} -m pip install . -vvv --no-deps --no-build-isolation \
    -Csetup-args="--cross-file=$SRC_DIR/emscripten.meson.cross"

