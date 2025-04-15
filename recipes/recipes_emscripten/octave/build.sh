export FFLAGS="${FFLAGS} -g --target=wasm32-unknown-emscripten"
# --disable-threads does not seem to disable parallelism, so we ignore undefined symbols for now
export EMCC_LINK_FLAGS="${EMCC_LINK_FLAGS} -sERROR_ON_UNDEFINED_SYMBOLS=0"

export FLIBS="-lFortranRuntime"

# Forcing autotools to NOT rerun after patches
find . -exec touch -t $(date +%Y%m%d%H%M) {} \;

emconfigure ./configure \
   --prefix="${PREFIX}" \
   --build="x86_64-conda-linux-gnu" \
   --host="wasm32-unknown-emscripten" \
   --disable-dependency-tracking \
   --enable-fortran-calling-convention="f2c" \
   --enable-shared \
   --disable-dlopen \
   --disable-rpath \
   --disable-openmp \
   --disable-threads \
   --disable-fftw-threads \
   --disable-readline \
   --disable-docs \
   --disable-java \
   --with-blas \
   --with-lapack \
   --with-pcre2 \
   --with-pcre2-includedir="${PREFIX}/include" \
   --with-pcre2-libdir="${PREFIX}/lib" \
   --without-pcre \
   --without-qt \
   --without-qrupdate \
   --without-framework-carbon \

emmake make --jobs 1  # OOM

emmake make install
