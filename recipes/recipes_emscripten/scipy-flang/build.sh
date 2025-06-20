set -ex

# https://github.com/mesonbuild/meson/blob/e542901af6e30865715d3c3c18f703910a096ec0/mesonbuild/backend/ninjabackend.py#L94
# Prevent from using response file. The response file that meson generates is not compatible to pyodide-build
export MESON_RSP_THRESHOLD=131072

export CFLAGS="-I$PREFIX/include/python3.13 $CFLAGS"
export CXXFLAGS="-I$PREFIX/include/python3.13 $CXXFLAGS"

# find . -name "meson.build" -type f -exec sed -i "s/link_language: 'fortran'/link_language: 'c'/g" {} +

cp $RECIPE_DIR/meson_linkers.py $BUILD_PREFIX/lib/python3.13/site-packages/mesonbuild/linkers/linkers.py

export LDFLAGS="$(echo "${LDFLAGS}" |  sed -E 's/-s +/-s/g')"

cp $RECIPE_DIR/flang-new-wrapper $BUILD_PREFIX/bin/flang-new-wrapper

export EM_LLVM_ROOT=$BUILD_PREFIX
export FC=$BUILD_PREFIX/bin/flang-new-wrapper
export FFLAGS="-g --target=wasm32-unknown-emscripten -fPIC"
export FCLIBS="-lFortranRuntime"

# export MESON_FORCE_BACKTRACE=1
${PYTHON} -m pip install . -vvv --no-deps --no-build-isolation \
    -Csetup-args="--cross-file=$RECIPE_DIR/emscripten.meson.cross" \
    -Csetup-args="-Dfortran_std=none" \
    -Csetup-args="-Duse-pythran=false" \
    -Cbuild-dir="_build" \
    -Ccompile-args="--verbose"