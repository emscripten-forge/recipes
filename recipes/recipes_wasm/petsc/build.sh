#!/bin/bash
set -eux

export PYTHON=${PYTHON:-$(command -v python3)}
export PETSC_DIR=$SRC_DIR
export PETSC_ARCH=arch-emscripten

# 1. Build PETSc's C BLAS/LAPACK (second source, extracted to
#    $SRC_DIR/f2cblaslapack with its own top dir flattened).  Its makefile pulls
#    PETSc's *build-time* conf, which does not exist yet; drop that include and
#    drive the compilers directly.
cd "$SRC_DIR/f2cblaslapack"
sed -i '/^include \${PETSC_DIR}/d' makefile
make -j"${CPU_COUNT}" CC=emcc AR=emar RANLIB=emranlib COPTFLAGS="-O2" \
     blas_lib lapack_lib
mkdir -p "$PREFIX/lib"
cp libf2cblas.a libf2clapack.a "$PREFIX/lib/"

# 2. Configure PETSc in batch (cross-compile) mode against those archives.
cd "$PETSC_DIR"
"$PYTHON" ./configure \
  --with-cc=emcc \
  --with-cxx=0 \
  --with-fc=0 \
  --with-ar=emar \
  --with-ranlib=emranlib \
  --with-batch \
  --with-mpi=0 \
  --with-x=0 \
  --with-shared-libraries=0 \
  --with-debugging=0 \
  COPTFLAGS="-O2" \
  --with-blas-lib="[$PREFIX/lib/libf2cblas.a]" \
  --with-lapack-lib="[$PREFIX/lib/libf2clapack.a]" \
  --prefix="$PREFIX"

# 3. Batch mode probes headers with the preprocessor only, so it "finds"
#    <sys/procfs.h>, which exists in emscripten's sysroot but is unusable
#    (undeclared elf_gregset_t) and breaks src/sys/memory/mem.c.
sed -i '/PETSC_HAVE_SYS_PROCFS_H/d' "$PETSC_ARCH/include/petscconf.h"

# 4. Build and install (install-lib skips ~60 MB of examples/data).
make -j"${CPU_COUNT}" all
make install-lib

# 5. Strip build-env tool paths; keep the tool names so they resolve on PATH.
for f in $(grep -rl "$BUILD_PREFIX/bin/" "$PREFIX/lib/petsc" 2>/dev/null); do
  sed -i "s|$BUILD_PREFIX/bin/||g" "$f"
done

# 6. PETSc's .pc files expand ${PETSC_DIR} without defining it; strict
#    pkg-config (0.29.2, as opposed to 3.x) then rejects the file outright.
for pc in "$PREFIX"/lib/pkgconfig/petsc.pc "$PREFIX"/lib/pkgconfig/PETSc.pc; do
  sed -i '/^prefix=/a PETSC_DIR=${prefix}' "$pc"
done

# 7. Drop build-only leftovers.
rm -f "$PREFIX"/lib/petsc/conf/configure-hash \
      "$PREFIX"/lib/petsc/conf/pkg.conf.f2cblaslapack
rm -rf "$PREFIX"/share/petsc/examples/src
find "$PREFIX" -name '*.pyc' -delete
