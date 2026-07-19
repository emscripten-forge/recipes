#!/usr/bin/env bash
set -euxo pipefail

cd M2/BUILD/build

mkdir install_prefix

# Strip the CMP0167 line
sed -i '/CMP0167/d' ../../cmake/check-libraries.cmake

# Excise the missing submodules from CMake targets
sed -i '/add_subdirectory(memtailor)/d' ../../Macaulay2/e/CMakeLists.txt
sed -i '/add_subdirectory(mathic)/d' ../../Macaulay2/e/CMakeLists.txt
sed -i '/add_subdirectory(mathicgb)/d' ../../Macaulay2/e/CMakeLists.txt
sed -i '/target_compile_options(mathicgb/,/)/d' ../../Macaulay2/e/CMakeLists.txt
sed -i '/export(TARGETS.*mathicgb/,/)/d' ../../Macaulay2/CMakeLists.txt

# Patch e/CMakeLists.txt using the EXACT text from your unmodified source file
sed -i "s|PUBLIC memtailor mathic mathicgb|PUBLIC $PREFIX/lib/libmemtailor.a $PREFIX/lib/libmathic.a $PREFIX/lib/libmathicgb.a|g" ../../Macaulay2/e/CMakeLists.txt
sed -i 's|mathicgb mathic memtailor||g' ../../Macaulay2/e/CMakeLists.txt

# Patch FindNauty.cmake to prevent it from shadowing the CLI variables
sed -i '/set(NAUTY_INCLUDE_DIR NOTFOUND)/d' ../../cmake/FindNauty.cmake
sed -i '/set(NAUTY_LIBRARIES NOTFOUND)/d' ../../cmake/FindNauty.cmake
sed -i '/_NAUTY_check_version()/d' ../../cmake/FindNauty.cmake

# Patch gc-include.h to stop it from forcing multithreading on Boehm GC
sed -i '/#define GC_THREADS 1/d' ../../include/M2/gc-include.h
sed -i '/#define GC_LINUX_THREADS/d' ../../include/M2/gc-include.h

# Force static linking of OpenBLAS by deleting the dynamic library from the build prefix
rm -f $PREFIX/lib/libopenblas.so*

# Create active dummy executables that return a clean exit 0
mkdir -p $PREFIX/bin

echo '#!/bin/sh' > $PREFIX/bin/normaliz
echo 'exit 0' >> $PREFIX/bin/normaliz
chmod +x $PREFIX/bin/normaliz

echo '#!/bin/sh' > $PREFIX/bin/dreadnaut
echo 'exit 0' >> $PREFIX/bin/dreadnaut
chmod +x $PREFIX/bin/dreadnaut

emcmake cmake -S ../.. -B . \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=install_prefix \
      -DCMAKE_PREFIX_PATH=$PREFIX \
      -DCMAKE_FIND_ROOT_PATH=$PREFIX \
      -DBLA_VENDOR=OpenBLAS \
      -DBLAS_LIBRARIES=$PREFIX/lib/libopenblas.a \
      -DLAPACK_LIBRARIES=$PREFIX/lib/libopenblas.a \
      -DBoost_NO_BOOST_CMAKE=ON \
      -DWITH_OMP=OFF \
      -DCMAKE_C_FLAGS="-DGC_NO_THREAD_REDIRECTS -DGC_NO_THREADS=2" \
      -DCMAKE_CXX_FLAGS="-DGC_NO_THREAD_REDIRECTS -DGC_NO_THREADS=2" \
      -DCMAKE_EXE_LINKER_FLAGS="-s ALLOW_MEMORY_GROWTH=1 -s NODERAWFS=1" \
      -DREADLINE_INCLUDE_DIR=$PREFIX/include \
      -DREADLINE_LIBRARY=$PREFIX/lib/libreadline.a \
      -DHISTORY_INCLUDE_DIR=$PREFIX/include \
      -DHISTORY_LIBRARY=$PREFIX/lib/libhistory.a \
      -DWITH_PYTHON=OFF \
      -DCMAKE_DISABLE_FIND_PACKAGE_LATEX=ON \
      -DCHECK_LIBRARY_COMPATIBILITY=OFF \
      -DNAUTY_EXECUTABLE=$PREFIX/bin/dreadnaut \
      -DNAUTY_INCLUDE_DIR=$PREFIX/include \
      -DNAUTY_LIBRARIES=$PREFIX/lib/libnauty.a \
      -DNAUTY_VERSION_OK=ON \
      -DNORMALIZ_EXECUTABLE=$PREFIX/bin/normaliz \
      -DNORMALIZ_INCLUDE_DIR=$PREFIX/include \
      -DNORMALIZ_LIBRARIES=$PREFIX/lib/libnormaliz.a \
      -DBUILD_NATIVE=OFF

emmake make build-libraries
emmake make M2-binary M2-core
emmake make build-programs
emmake install-packages