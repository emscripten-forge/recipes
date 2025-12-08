#!/bin/bash

set -xeo pipefail

mkdir build
cd build

cmake_args=(
      ${CMAKE_ARGS}
      -DCMAKE_BUILD_TYPE=Release
      -DCMAKE_INSTALL_LIBDIR=lib
      -DCMAKE_INSTALL_PREFIX="$PREFIX"
      -DBUILD_SHARED_LIBS=OFF
      -DBUILD_STATIC_LIBS=ON
      -DIMATH_LIB_SUFFIX=
)

if [[ $(uname) == "Linux" ]]; then
      # Avoid issue with PRIx64 macro (cf https://stackoverflow.com/questions/52715250)
      CXXFLAGS="$CXXFLAGS -D__STDC_FORMAT_MACROS"

      # This helps a test program link.
      cmake_args+=(
            -DCMAKE_EXE_LINKER_FLAGS="$LDFLAGS -Wl,-lrt"
      )
fi

cmake "${cmake_args[@]}" ..
make -j${CPU_COUNT}
make install