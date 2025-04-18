export FLIBS="-lFortranRuntime"
export FFLAGS="${FFLAGS} -target=wasm32-unknown-emscripten"
export CFLAGS="${CFLAGS} -target=wasm32-unknown-emscripten"
export CXXFLAGS="${CXXFLAGS} -target=wasm32-unknown-emscripten"

# flang-new does not support emscripten flags.
#
# Future solution when flang is more mature:
# export FFLAGS="${FFLAGS} -Wno-error=unused-command-line-argument -Qunused-arguments"
#
# Current wrapper to remove all -s CLI otions passed to flang-new
(
   echo '#!/usr/bin/env bash'
   echo 'args=()'
   echo 'for arg in "$@"; do'
   echo '  if [[ "${arg}" != -s* ]]; then'
   echo '    args+=("${arg}")'
   echo '  fi'
   echo 'done'
   echo 'exec' "\"${F77}\"" '"${args[@]}"'
) > flang-new-wrap
chmod +x flang-new-wrap
export F77="${PWD}/flang-new-wrap"

# Remove spaces in `-s OPTION` from emscripten to avoid confusion in flang
export LDFLAGS="$(echo "${LDFLAGS}" |  sed -E 's/-s +/-s/g')"

# Force disable pthread
sed -i 's/ax_pthread_ok=yes/ax_pthread_ok=no/' configure
export ac_cv_header_pthread_h=no
# Force shared libraries to build as static
sed -i 's/SH_LDFLAGS=.*/SH_LDFLAGS=/' configure

# Forcing autotools to NOT rerun after patches
find . -exec touch -t $(date +%Y%m%d%H%M) {} \;

BUILD="x86_64-unknown-linux-gnu"
# Pretend to build for linux because autotools does not know about emscripten
HOST="wasm32-unknown-linux-gnu"

emconfigure ./configure \
   --prefix="${PREFIX}" \
   --build="${BUILD}"\
   --host="${HOST}" \
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
   || cat config.log || exit 1

emmake make --jobs 1  # OOM

emmake make install
