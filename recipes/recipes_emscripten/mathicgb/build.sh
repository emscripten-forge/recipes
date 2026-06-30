#!/usr/bin/env bash
set -euxo pipefail

sed -i '/friend void mathic::PairQueueNamespace::constructPairData/{n;s/Index/mathic::PairQueueNamespace::Index/g;}' src/mathicgb/SPairs.hpp
sed -i '/friend void mathic::PairQueueNamespace::destructPairData/{n;s/Index/mathic::PairQueueNamespace::Index/g;}' src/mathicgb/SPairs.hpp
sed -i '466s/Coefficient coef/Coefficient coef_in/' src/mathicgb/MathicIO.hpp
sed -i '470a \      typename std::remove_const<Coefficient>::type coef = coef_in;' src/mathicgb/MathicIO.hpp
sed -i '1i #include <type_traits>' src/mathicgb/MathicIO.hpp

./autogen.sh

CPPFLAGS="-I${PREFIX}/include" \
LDFLAGS="-L${PREFIX}/lib" \
CXXFLAGS="-std=gnu++11 -fdelayed-template-parsing" \
emconfigure ./configure \
    --host=wasm32-unknown-emscripten \
    --with-tbb=no \
    --with-gtest=no \
    --disable-shared \
    --enable-static \
    --prefix="${PREFIX}" \
    MEMTAILOR_CFLAGS="-I${PREFIX}/include" \
    MEMTAILOR_LIBS="-L${PREFIX}/lib -lmemtailor" \
    MATHIC_CFLAGS="-I${PREFIX}/include" \
    MATHIC_LIBS="-L${PREFIX}/lib -lmathic"

emmake make -j8
emmake make install
