export FFLAGS="${FFLAGS} -g --target=wasm32-unknown-emscripten"
export FLIBS="-lFortranRuntime"

# LDFLAGS are passed to all compilers, but flang-new does not support emscripten flags
# We split them and set emscripten-specific flags in CPPFLAGS which are always passed along
# LDFLAGS to emscripten wrapped CC and CXX compilers.
LDFLAGS_LINES="$(echo "${LDFLAGS}" |  sed -E 's/-s +/-s/g' | tr ' ' '\n')"
export LDFLAGS="$(echo "${LDFLAGS_LINES}" | grep -v '^-s' | tr '\n' ' ')"

# --disable-threads does not seem to disable parallelism, so we ignore undefined symbols for now
EM_LDFLAGS="$(echo "${LDFLAGS_LINES}" | grep '^-s' | tr '\n' ' ')"
EM_LDFLAGS="${EM_LDFLAGS} -sERROR_ON_UNDEFINED_SYMBOLS=0"
export CPPFLAGS="${CPPFLAGS} ${EM_LDFLAGS}"

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
