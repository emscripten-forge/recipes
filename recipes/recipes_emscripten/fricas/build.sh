#!/usr/bin/env bash
set -euxo pipefail

# FIX THE NATIVE COMPILER MISSING ISSUE
mkdir -p ${BUILD_PREFIX}/bin
ln -s $(which gcc) ${BUILD_PREFIX}/bin/x86_64-conda-linux-gnu-cc

BUILD_ARCH="${BUILD:-$(gcc -dumpmachine 2>/dev/null | sed 's/-gnux32$/-gnu/' || echo x86_64-pc-linux-gnu)}"

# NATIVE HOST BUILD
mkdir -p bld-native
pushd bld-native

env -u CFLAGS -u CXXFLAGS -u LDFLAGS -u CPPFLAGS \
../configure \
    --build="${BUILD_ARCH}" \
    --prefix="${PREFIX}" \
    --with-lisp=ecl

# Generate the required build directories first
make stamp-rootdirs

# Build the native C dependencies and Lisp compiler
env -u CFLAGS -u CXXFLAGS -u LDFLAGS -u CPPFLAGS make CC=gcc AR=ar RANLIB=ranlib -C src/lib
env -u CFLAGS -u CXXFLAGS -u LDFLAGS -u CPPFLAGS make CC=gcc AR=ar RANLIB=ranlib -C src/lisp

popd

# WEBASSEMBLY TARGET BUILD
export CPPFLAGS="-I${PREFIX}/include"
export LDFLAGS="-L${PREFIX}/lib -s ALLOW_MEMORY_GROWTH=1 -s MAXIMUM_MEMORY=4GB"
export CXXFLAGS="-std=c++17"

mkdir -p bld-wasm
pushd bld-wasm

emconfigure ../configure \
    --build="${BUILD_ARCH}" \
    --host=wasm32-unknown-emscripten \
    --prefix="${PREFIX}" \
    --with-lisp=ecl 

# Generate root directories
make stamp-rootdirs

# Copy the native lisp tool into the Wasm build tree.
cp ../bld-native/build/${BUILD_ARCH}/bin/lisp build/${BUILD_ARCH}/bin/lisp

# This dynamically rewrites the generated Lisp script so it executes 
# `(progn "$@" nil)` instead of `(make-program "$@" nil)`. 
sed -i 's/make-program/progn/g' src/lisp/Makefile

emmake make -j8
emmake make install

popd