#!/bin/bash

set -euo pipefail

# SuiteSparse 5.x uses make-based build system
# Build the library components

# Build only the core libraries that work well with emscripten
emmake make library \
    CC=emcc \
    AR=emar \
    RANLIB=emranlib \
    CF="-O3 -fPIC -DNTIMER" \
    CHOLMOD_CONFIG="-DNPARTITION" \
    BLAS="-lblas -lcblas" \
    LAPACK="-llapack" \
    INSTALL_LIB="${PREFIX}/lib" \
    INSTALL_INCLUDE="${PREFIX}/include"

# Install the libraries and headers
emmake make install \
    INSTALL_LIB="${PREFIX}/lib" \
    INSTALL_INCLUDE="${PREFIX}/include"

# Create symlinks for expected header layout
mkdir -p ${PREFIX}/include/suitesparse
cp SuiteSparse_config/SuiteSparse_config.h ${PREFIX}/include/suitesparse/
for package in AMD BTF CAMD CCOLAMD COLAMD CHOLMOD UMFPACK KLU SPQR CXSparse; do
    if [ -d "${package}/Include" ]; then
        cp ${package}/Include/*.h ${PREFIX}/include/suitesparse/ || true
    fi
done

# Create a simple test to verify the installation
cat > ${PREFIX}/bin/suitesparse_test.c << 'EOF'
#include <stdio.h>
#include <suitesparse/umfpack.h>
#include <suitesparse/cholmod.h>
#include <suitesparse/SuiteSparse_config.h>

int main() {
    printf("SuiteSparse version: %d.%d.%d\n", 
           SUITESPARSE_MAIN_VERSION, 
           SUITESPARSE_SUB_VERSION, 
           SUITESPARSE_SUBSUB_VERSION);
    printf("UMFPACK version: %s\n", UMFPACK_VERSION);
    printf("CHOLMOD version: %s\n", CHOLMOD_VERSION);
    return 0;
}
EOF