
#!/bin/bash
set -ex

cat <<EOF > overwriteProp.cmake
set_property(GLOBAL PROPERTY TARGET_SUPPORTS_SHARED_LIBS TRUE)
set(CMAKE_SHARED_LIBRARY_CREATE_C_FLAGS "-s SIDE_MODULE=1")
set(CMAKE_SHARED_LIBRARY_CREATE_CXX_FLAGS "-s SIDE_MODULE=1")
EOF

emcmake cmake \
  -S $PWD \
  -B build \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="$PREFIX" \
  -DCMAKE_PREFIX_PATH="$PREFIX" \
  -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ON \
  -DCMAKE_C_FLAGS="" \
  -DCMAKE_CXX_FLAGS="" \
  -DCMAKE_EXE_LINKER_FLAGS="" \
  -DCMAKE_SHARED_LINKER_FLAGS="" \
  -DCMAKE_PROJECT_INCLUDE=$PWD/overwriteProp.cmake \
  -DCMAKE_SYSTEM_NAME=Emscripten

emmake make -C build install

# NOTE: Xeus-Haskell requires the following environment variables to be set
# export MHSDIR="$PREFIX/share/microhs";
# export MHS_LIBRARY_PATH="$PREFIX/usr/lib/haskell-packages/microhs";
# jupyter lite serve \
#   --XeusAddon.prefix="$PREFIX" \
#   --XeusAddon.mounts="$MHSDIR:/share/microhs" \
#   --XeusAddon.mounts="$PWD/src/XHaskell:/usr/lib/haskell-packages/microhs/XHaskell" \
#   --contents notebooks \
