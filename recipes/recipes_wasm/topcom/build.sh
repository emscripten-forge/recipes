#!/usr/bin/env bash
set -euxo pipefail

# No threads: TOPCOM only starts threads with --parallelenumeration /
# --parallelsymmetries, but it compiles everything with -pthread, including
# the bundled (C++) cddlib that configure builds in external/. Objects built
# with -pthread use atomics and can't be linked without shared memory, so
# drop the flag before configure runs.
sed -i.bak -e 's/ -pthread//g' external/Makefile configure
# the bundled cddlib's configure builds a shared libcddgmp by default, so its
# demo programs get linked dynamically (needs a main module); TOPCOM only
# uses the static library
sed -i.bak -e "s|configure CC=\${CXX}|configure --disable-shared --host=${HOST} CC=\${CXX}|" external/Makefile
grep -n "disable-shared" external/Makefile

# only these flags: the inherited ones contain side-module flags, and TOPCOM
# (and its bundled cddlib) link programs
CPPFLAGS="-I${PREFIX}/include" \
LDFLAGS="-L${PREFIX}/lib" \
CXXFLAGS="-std=c++17" \
emconfigure ./configure \
    --build=${BUILD} \
    --host=${HOST} \
    --disable-shared \
    --enable-static \
    --prefix="${PREFIX}"

# anything configure still put into the Makefiles
find . -type f -name Makefile -exec sed -i.bak -e 's/ -pthread//g' -e 's/ -lpthread//g' {} +

emmake make -j${CPU_COUNT}
emmake make install

# make install only installs the .js launchers of the programs
cp src/*.wasm src-reg/*.wasm "${PREFIX}/bin/"
