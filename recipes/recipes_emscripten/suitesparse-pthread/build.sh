#!/usr/bin/env bash
set -euxo pipefail

# KLU and UMFPACK and the libraries they use, compiled with -pthread like
# every other object of a shared-memory module, as static archives in their
# own directories next to the suitesparse packages. UMFPACK: no CHOLMOD, and
# -DNBLAS (UMFPACK's own dense kernels, so that no C code calls the Fortran
# BLAS without the hidden string lengths).
NAME="${PKG_NAME}"            # suitesparse-pthread

emcmake cmake -S . -B _build -G "Unix Makefiles" \
    -DCMAKE_INSTALL_PREFIX="$PREFIX" \
    -DCMAKE_INSTALL_LIBDIR="lib/$NAME" \
    -DCMAKE_INSTALL_INCLUDEDIR="include/$NAME" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_FLAGS="-pthread -DNBLAS" \
    -DCMAKE_EXE_LINKER_FLAGS="-pthread" \
    -DSUITESPARSE_ENABLE_PROJECTS="suitesparse_config;amd;camd;colamd;ccolamd;btf;klu;umfpack" \
    -DBUILD_SHARED_LIBS=OFF -DBUILD_STATIC_LIBS=ON \
    -DKLU_USE_CHOLMOD=OFF -DUMFPACK_USE_CHOLMOD=OFF \
    -DSUITESPARSE_USE_OPENMP=OFF -DSUITESPARSE_USE_CUDA=OFF \
    -DSUITESPARSE_USE_FORTRAN=OFF -DSUITESPARSE_USE_PYTHON=OFF \
    -DSUITESPARSE_DEMOS=OFF -DBUILD_TESTING=OFF \
    -DSUITESPARSE_USE_64BIT_BLAS=OFF \
    -DBLAS_FOUND=TRUE -DLAPACK_FOUND=TRUE -DBLA_VENDOR=Generic \
    -DBLAS_LIBRARIES="$PREFIX/lib/libblas.a" \
    -DLAPACK_LIBRARIES="$PREFIX/lib/liblapack.a"
$(which cmake) --build _build -j"${CPU_COUNT:-2}"
$(which cmake) --install _build

# SuiteSparse's own pkg-config and CMake files stay in lib/suitesparse-pthread;
# this pkg-config file, named after the package, lists them all
mkdir -p "$PREFIX/lib/pkgconfig" "$PREFIX/share/licenses/$NAME"
cat > "$PREFIX/lib/pkgconfig/$NAME.pc" <<EOF
prefix=$PREFIX
includedir=\${prefix}/include/$NAME
libdir=\${prefix}/lib/$NAME

Name: $NAME
Description: SuiteSparse KLU and UMFPACK, static, built with -pthread, for emscripten-wasm32
Version: $PKG_VERSION
Libs: -L\${libdir} -lumfpack -lklu -lbtf -lamd -lcamd -lcolamd -lccolamd -lsuitesparseconfig -pthread
Cflags: -I\${includedir}/suitesparse -pthread
EOF
# programs that link the archives in ship these notices
install -m 644 LICENSE.txt "$PREFIX/share/licenses/$NAME/LICENSE.txt"
for p in KLU UMFPACK AMD BTF CAMD COLAMD CCOLAMD; do
  install -m 644 "$p/Doc/License.txt" "$PREFIX/share/licenses/$NAME/$p-License.txt"
done
