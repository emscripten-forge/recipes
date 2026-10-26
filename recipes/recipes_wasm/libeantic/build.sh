#!/usr/bin/env bash
set -euxo pipefail

# e-antic uses mp_bitcnt_t where FLINT now uses flint_bitcnt_t
find . -type f \( -name "*.c" -o -name "*.h" \) -exec sed -i.bak 's/mp_bitcnt_t/flint_bitcnt_t/g' {} +
find . -type f -name "*.bak" -delete

export CPPFLAGS="-I${PREFIX}/include"
export LDFLAGS="-L${PREFIX}/lib"
export CXXFLAGS="-fPIC -Wno-enum-constexpr-conversion"

emconfigure ./configure \
    --build=i686-pc-linux-gnu \
    --host=${HOST} \
    --disable-dependency-tracking \
    --disable-shared \
    --enable-static \
    --without-byexample \
    --without-doc \
    --without-benchmark \
    --without-pyeantic \
    --with-gmp="${PREFIX}" \
    --with-flint="${PREFIX}" \
    --prefix="${PREFIX}"

emmake make -j8
emmake make install