set -ex


LLVM_PKG_URL="https://github.com/IsabelParedes/llvm-project/releases/download/v20.1.7_emscripten-wasm32/llvm_emscripten-wasm32-20.1.7-h2e33cc4_5.tar.bz2"
LLVM_PKG="llvm.tar.bz2"
export LLVM_DIR=$PWD/llvm

wget -O "$LLVM_PKG" "$LLVM_PKG_URL"
mkdir -p $LLVM_DIR
tar -xjvf $LLVM_PKG -C $LLVM_DIR --exclude='info/*' --exclude='share/*' --exclude='libexec/*'

export EM_LLVM_ROOT=$LLVM_DIR

echo "LLVM installation complete."

# https://github.com/mesonbuild/meson/blob/e542901af6e30865715d3c3c18f703910a096ec0/mesonbuild/backend/ninjabackend.py#L94
# Prevent from using response file. The response file that meson generates is not compatible to pyodide-build
export MESON_RSP_THRESHOLD=131072

export CFLAGS="-I$PREFIX/include/python3.13 $CFLAGS"
export CXXFLAGS="-I$PREFIX/include/python3.13 $CXXFLAGS"

cp $RECIPE_DIR/meson_linkers.py $BUILD_PREFIX/lib/python3.13/site-packages/mesonbuild/linkers/linkers.py

export LDFLAGS="$(echo "${LDFLAGS}" |  sed -E 's/-s +/-s/g')"

cp $RECIPE_DIR/flang-new-wrapper $LLVM_DIR/bin/flang-new-wrapper

export FC=$LLVM_DIR/bin/flang-new-wrapper
export FFLAGS="-g --target=wasm32-unknown-emscripten -fPIC"
export FCLIBS="-lFortranRuntime"



cp $RECIPE_DIR/_generate_pyx.py  scipy/linalg/_generate_pyx.py



# sed -i 's/void/int/g' scipy/linalg/cython_blas_signatures.txt
# sed -i 's/void/int/g' scipy/linalg/cython_lapack_signatures.txt



# 

cp $RECIPE_DIR/cython_lapack_signatures.txt scipy/linalg/cython_lapack_signatures.txt





# export MESON_FORCE_BACKTRACE=1
${PYTHON} -m pip install . ${PIP_ARGS} --no-build-isolation \
    -Csetup-args="--cross-file=$RECIPE_DIR/emscripten.meson.cross" \
    -Csetup-args="-Dfortran_std=none" \
    -Csetup-args="-Duse-pythran=false" \
    -Cbuild-dir="_build" \
    -Ccompile-args="--verbose"