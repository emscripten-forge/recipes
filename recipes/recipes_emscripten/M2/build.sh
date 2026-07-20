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

# Patch e/CMakeLists.txt to explicitly link the absolute paths of the conda-forge math packages
sed -i "s|PUBLIC memtailor mathic mathicgb|PUBLIC $PREFIX/lib/libmemtailor.a $PREFIX/lib/libmathic.a $PREFIX/lib/libmathicgb.a|g" ../../Macaulay2/e/CMakeLists.txt
sed -i 's|mathicgb mathic memtailor||g' ../../Macaulay2/e/CMakeLists.txt

# Scrub the hardcoded 'quadmath' linking rule from the M2-interpreter CMake configuration
sed -i '/quadmath/d' ../../Macaulay2/d/CMakeLists.txt

# Remove Readline and History dependencies from the CMake configuration
sed -i '/find_package(Readline/d' ../../cmake/check-libraries.cmake
sed -i '/find_package(History/d' ../../cmake/check-libraries.cmake
sed -i 's/READLINE HISTORY //g' ../../cmake/check-libraries.cmake

# Patch M2lib.c to replace Readline with standard WebAssembly-compatible I/O
sed -i '/readline\/readline.h/d' ../../Macaulay2/d/M2lib.c
sed -i '/readline\/history.h/d' ../../Macaulay2/d/M2lib.c
sed -i '/Functions dealing with libreadline/,$d' ../../Macaulay2/d/M2lib.c

cat << 'EOF' >> ../../Macaulay2/d/M2lib.c
#include <stdio.h>
#include <string.h>

int system_readHistory(char *filename) { return 0; }
int system_appendHistory(int n, char *filename) { return 0; }
void system_addHistory(char *buf) { }
char *system_getHistory(const int n) { return NULL; }
int system_historyLength() { return 0; }
void system_initReadlineVariables(void) { }

int system_readline(M2_string buffer, int len, int offset, M2_string prompt) {
  char *p = M2_tocharstar(prompt);
  printf("%s", p);
  fflush(stdout);
  freemem(p);
  
  char *buf_ptr = (char *)buffer->array + offset;
  if (fgets(buf_ptr, len, stdin) == NULL) return 0;
  
  int r = strlen(buf_ptr);
  /* Optional: replace trailing newline with null terminator if strictly needed */
  return r;
}
EOF

# Patch version.dd to remove readline version queries
sed -i '/readline\/readline.h/d' ../../Macaulay2/d/version.dd
sed -i 's/"readline version" => Ccode(constcharstar,"stringize(RL_VERSION_MAJOR) \\".\\" stringize(RL_VERSION_MINOR)"),/"readline version" => "not present",/g' ../../Macaulay2/d/version.dd

# Patch FindNauty.cmake to prevent it from shadowing the CLI variables
sed -i '/set(NAUTY_INCLUDE_DIR NOTFOUND)/d' ../../cmake/FindNauty.cmake
sed -i '/set(NAUTY_LIBRARIES NOTFOUND)/d' ../../cmake/FindNauty.cmake
sed -i '/_NAUTY_check_version()/d' ../../cmake/FindNauty.cmake

# Forcefully append hidden dependencies to Find modules so they are guaranteed to link
echo "list(APPEND NORMALIZ_LIBRARIES \"$PREFIX/lib/libcocoa.a\")" >> ../../cmake/FindNormaliz.cmake
echo "list(APPEND FACTORY_LIBRARIES \"$PREFIX/lib/libomalloc.a\" \"$PREFIX/lib/libsingular_resources.a\")" >> ../../cmake/FindFactory.cmake

# Patch gc-include.h to stop it from forcing multithreading on Boehm GC
sed -i '/#define GC_THREADS 1/d' ../../include/M2/gc-include.h
sed -i '/#define GC_LINUX_THREADS/d' ../../include/M2/gc-include.h

# Force static linking of OpenBLAS by deleting the dynamic library from the build prefix
rm -f $PREFIX/lib/libopenblas.so*

# Create a dummy library to stub the unsupported pthread_kill signal
echo "int pthread_kill(long t, int s) { return 0; }" > dummy_pthread.c
emcc -c dummy_pthread.c -o dummy_pthread.o
emar rcs $PREFIX/lib/libdummy_pthread.a dummy_pthread.o

sed -i 's/if(LDD)/if(FALSE)/g' ../../Macaulay2/bin/CMakeLists.txt
sed -i 's/exec `/exec node --max-old-space-size=4096 `/g' ../../Macaulay2/bin/CMakeLists.txt

cat << 'EOF' >> ../../Macaulay2/bin/CMakeLists.txt

target_link_options(M2-binary PRIVATE
  "-sTOTAL_STACK=32mb"
  "-sINITIAL_MEMORY=2gb"
  "-sALLOW_MEMORY_GROWTH=1"
  "-sMAXIMUM_MEMORY=4gb"
  "-sFORCE_FILESYSTEM=1"
  "-sNODERAWFS=1"
)
EOF

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
      -DCMAKE_EXE_LINKER_FLAGS="-s ALLOW_MEMORY_GROWTH=1 -s NODERAWFS=1 -L$PREFIX/lib -ldummy_pthread -s TOTAL_STACK=32MB -s INITIAL_MEMORY=2GB -s MAXIMUM_MEMORY=4GB -s FORCE_FILESYSTEM=1" \
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
