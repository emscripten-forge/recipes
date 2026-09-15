#!/usr/bin/env bash
set -euxo pipefail

# FLINT COMPATIBILITY PATCH ---
find . -type f \( -name "*.c" -o -name "*.h" \) -exec sed -i 's/mp_bitcnt_t/flint_bitcnt_t/g' {} +
for func in fmpz_poly_num_real_roots_0_1 fmpz_poly_num_real_roots_vca fmpz_poly_num_real_roots_0_1_vca fmpz_poly_has_real_root fmpz_poly_num_real_roots_upper_bound fmpz_poly_num_real_roots_0_1_sturm; do
    find . -type f \( -name "*.c" -o -name "*.h" \) -exec sed -i -E "s/${func}\([[:space:]]*fmpz_poly_t/${func}(const fmpz_poly_t/g" {} +
done
for func in _fmpz_poly_has_real_root _fmpz_poly_descartes_bound_0_1; do
    find . -type f \( -name "*.c" -o -name "*.h" \) -exec sed -i -E "s/${func}\([[:space:]]*fmpz[[:space:]]*\*/${func}(const fmpz \*/g" {} +
done
find . -type f \( -name "*.c" -o -name "*.h" \) -exec sed -i -E 's/fmpz_poly_squarefree_part\([[:space:]]*fmpz_poly_t[[:space:]]+res[[:space:]]*,[[:space:]]*fmpz_poly_t/fmpz_poly_squarefree_part(fmpz_poly_t res, const fmpz_poly_t/g' {} +

sed -i -E 's/n_intervals, fmpz \* pol/n_intervals, const fmpz * pol/g' libeantic/e-antic/fmpz_poly_extra.h
sed -i -E 's/n_interval, fmpz_poly_t pol/n_interval, const fmpz_poly_t pol/g' libeantic/e-antic/fmpz_poly_extra.h
sed -i -E 's/n_interval, fmpz_poly_t pol/n_interval, const fmpz_poly_t pol/g' libeantic/src/fmpz_poly_extra/isolate_real_roots.c
sed -i -E 's/^[[:space:]]*fmpz \* pol, slong len\)/        const fmpz * pol, slong len)/g' libeantic/src/fmpz_poly_extra/isolate_real_roots.c

export CPPFLAGS="-I${PREFIX}/include"
export LDFLAGS="-L${PREFIX}/lib"
export CXXFLAGS="-fPIC -Wno-enum-constexpr-conversion"

emconfigure ./configure \
    --build=i686-pc-linux-gnu \
    --host=wasm32-unknown-emscripten \
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