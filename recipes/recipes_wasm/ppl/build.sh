#!/bin/bash

# Get an updated config.sub and config.guess
cp $BUILD_PREFIX/share/gnuconfig/config.* . || true

emconfigure ./configure \
    CFLAGS="$CFLAGS -fPIC -Wno-reserved-identifier -Wno-reserved-macro-identifier" \
    CXXFLAGS="$CXXFLAGS -fwasm-exceptions -std=c++11 -fPIC -Wno-reserved-identifier -Wno-zero-as-null-pointer-constant -Wno-double-promotion -Wno-unsafe-buffer-usage -Wno-extra-semi-stmt -Wno-shadow -Wno-implicit-fallthrough -Wno-deprecated-literal-operator -Wno-suggest-override -Wno-suggest-destructor-override -Wno-deprecated-copy-with-user-provided-dtor -Wno-deprecated-copy-with-user-provided-copy -Wno-unused-template -Wno-comma -Wno-unreachable-code-return -Wno-deprecated-declarations -Wno-unreachable-code-break -Wno-format-nonliteral -Wno-missing-variable-declarations -Wno-missing-prototypes -Wno-weak-vtables -Wno-old-style-cast -Wno-header-hygiene -Wno-undef" \
    LDFLAGS="$LDFLAGS -fwasm-exceptions -sSUPPORT_LONGJMP" \
    --prefix=$PREFIX \
    --with-gmp=$PREFIX \
    --enable-coefficients=mpz --disable-fpmath \
    --enable-interfaces=c,c++ \
    --disable-shared \
    --enable-shared=no

make -j${CPU_COUNT}
make install
