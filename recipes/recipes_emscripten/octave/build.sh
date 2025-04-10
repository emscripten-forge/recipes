export FFLAGS="${FFLAGS} -g --target=wasm32-unknown-emscripten"

export FLIBS="-lFortranRuntime"

# Forcing autotools to NOT rerun after patches
find . -exec touch -t $(date +%Y%m%d%H%M) {} \;

emconfigure ./configure \
   --prefix="${PREFIX}" \
   --build="x86_64-conda-linux-gnu" \
   --host="wasm32-unknown-emscripten" \
   --disable-dependency-tracking \
   --enable-fortran-calling-convention="f2c" \
   --enable-shared=yes \
   --disable-rpath \
   --with-blas="yes" \
   --with-lapack="yes" \
   --without-pcre \
   --with-pcre2 \
   --with-pcre2-includedir="${PREFIX}/include" \
   --with-pcre2-libdir="-lpcre2-8" \
   --disable-openmp \
   --disable-readline \

emmake make --jobs 1  # OOM

emmake make install
