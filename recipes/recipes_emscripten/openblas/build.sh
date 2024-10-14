chmod u+x c_check
chmod u+x f_check
chmod u+x exports/gensymbol

set -ex

# Using flang as a WASM cross-compiler
# https://github.com/serge-sans-paille/llvm-project/blob/feature/flang-wasm/README.wasm.md
# https://github.com/conda-forge/flang-feedstock/pull/69
micromamba install -p $BUILD_PREFIX \
    conda-forge/label/llvm_rc::libllvm19 \
    conda-forge/label/llvm_dev::flang=19.1.0.rc2 \
    -y --no-channel-priority
rm $BUILD_PREFIX/bin/clang # links to clang19
ln -s $BUILD_PREFIX/bin/clang-18 $BUILD_PREFIX/bin/clang # links to emsdk clang

export CC=emcc
export FC=flang-new
export FFLAGS="--target=wasm32-unknown-emscripten"

emmake make libs shared \
    TARGET=GENERIC \
    CC=$CC \
    FC=$FC \
    HOSTCC=gcc \
    USE_THREAD=0 \
    BINARY=64

emmake make install PREFIX=$PREFIX

mkdir -p $PREFIX/lib
cp libopenblas.a $PREFIX/lib

# $(which cmake) --build _build
# $(which cmake) --install _build

# PYODIDE_PACKED=$RECIPE_DIR/openblas-0.3.23.zip
# # unzip
# unzip $PYODIDE_PACKED
# # copy libopenblas.so to
# mkdir -p $PREFIX/lib
# cp libopenblas.a $PREFIX/lib
