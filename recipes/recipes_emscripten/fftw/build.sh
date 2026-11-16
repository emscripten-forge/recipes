#!/bin/bash
set -euxo pipefail

# FFTW builds one precision per configure run: double (libfftw3) and single
# (libfftw3f). No threads or OpenMP, so the archives contain no atomics and
# link into programs with or without pthreads (the compiler package's
# EMCC_CFLAGS give -O2 -fPIC, so side modules can link them too). FFTW has
# no WebAssembly SIMD codelets.
cp "$BUILD_PREFIX"/share/gnuconfig/config.* .

for precision in double float; do
  extra=""
  if [ "$precision" = float ]; then
    extra="--enable-float"
  fi
  mkdir -p "_build_$precision"
  pushd "_build_$precision"
  emconfigure ../configure \
      --prefix="$PREFIX" \
      --host=wasm32-unknown-emscripten \
      --enable-static --disable-shared \
      --disable-fortran --disable-threads --disable-openmp --disable-doc \
      $extra
  emmake make -j"${CPU_COUNT:-2}"
  emmake make install
  popd
done

# tools that run FFTW programs (fftw-wisdom & co.) are of no use here
rm -f "$PREFIX"/bin/fftw*-wisdom "$PREFIX"/bin/fftw-wisdom-to-conf
rm -rf "$PREFIX"/share/man/man1/fftw*
