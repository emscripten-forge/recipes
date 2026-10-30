
#!/bin/bash
set -e

# ─────────────────────────────────────────────────────────────
# PATCH ABI: Fix LAPACK and CBLAS function signatures (void → int)
# ─────────────────────────────────────────────────────────────

# Refer : https://github.com/emscripten-forge/recipes/blob/main/recipes/recipes_emscripten/openblas/build.sh#L11-L20

# Fix Fortran-style LAPACK declarations (void followed by LAPACK_IMPL(...))
# Fix CBLAS-style declarations (void followed by cblas_foo(...))

SED_CMD="sed"
if [[ "$OSTYPE" == "darwin"* ]]; then
    if command -v gsed &> /dev/null; then
        SED_CMD="gsed"
    else
        echo "GNU sed (gsed) is not installed. Falling back to BSD sed with -E -i ''..."
        SED_CMD="sed"
        BSD_SED_FALLBACK=true
    fi
fi

if [[ "$BSD_SED_FALLBACK" == true ]]; then
    sed -E -i '' -e '/^[[:space:]]*void[[:space:]]*$/{
N
s@(^[[:space:]]*)void(\n[[:space:]]*LAPACK_IMPL\()@\1INTEGER\2@
}' include/xflens/cxxlapack/netlib/interface/lapack.in.h

    sed -E -i '' -e '/^[[:space:]]*void[[:space:]]*$/{
N
s@(^[[:space:]]*)void(\n[[:space:]]*cblas_[a-z0-9_]+\()@\1CBLAS_INT\2@
}' include/xflens/cxxblas/drivers/cblas.h
else
    $SED_CMD -ri '/^[[:space:]]*void[[:space:]]*$/{
N
s@(^[[:space:]]*)void(\n[[:space:]]*LAPACK_IMPL\()@\1INTEGER\2@
}' include/xflens/cxxlapack/netlib/interface/lapack.in.h

    $SED_CMD -ri '/^[[:space:]]*void[[:space:]]*$/{
N
s@(^[[:space:]]*)void(\n[[:space:]]*cblas_[a-z0-9_]+\()@\1CBLAS_INT\2@
}' include/xflens/cxxblas/drivers/cblas.h
fi

# Configure step
mkdir -p build
cd build

emcmake cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=$PREFIX \
    -DCMAKE_FIND_ROOT_PATH=$PREFIX \
    ..

# Build and Install step
emmake make -j8 install