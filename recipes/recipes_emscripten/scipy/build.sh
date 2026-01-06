set -ex

# Install custom LLVM and flang which includes patch for common symbols.
# If building locally then you can replace $(pwd) with a fixed location such as $HOME
# to avoid re-downloading on each rebuild.
export LLVM_DIR="$(pwd)/llvm_dir"
LLVM_PKG="llvm_emscripten-wasm32-20.1.7-h2e33cc4_5.tar.bz2"
if [ ! -d "$LLVM_DIR" ]; then
    mkdir -p $LLVM_DIR
    wget --quiet https://github.com/IsabelParedes/llvm-project/releases/download/v20.1.7_emscripten-wasm32/$LLVM_PKG
    tar -xf $LLVM_PKG --directory $LLVM_DIR
fi

# Check install
$LLVM_DIR/bin/flang --version
$LLVM_DIR/bin/llvm-nm --version

# Remove whitespace after '-s' in LDFLAGS
export LDFLAGS="$(echo "${LDFLAGS}" | sed -E 's/-s +/-s/g')"

# Use local flang-new-wrapper that does some arg mangling.
cp $RECIPE_DIR/flang-new-wrapper $LLVM_DIR/bin/flang-new-wrapper

export FC=$LLVM_DIR/bin/flang-new-wrapper

${PYTHON} -m pip install . ${PIP_ARGS} --no-build-isolation \
    -Csetup-args="--cross-file=$RECIPE_DIR/emscripten.meson.cross" \
    -Csetup-args="-Dfortran_std=none" \
    -Csetup-args="-Duse-pythran=false" \
    -Cbuild-dir="_build" \
    -Ccompile-args="--verbose"
