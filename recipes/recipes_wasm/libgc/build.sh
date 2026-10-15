#!/usr/bin/env bash
set -euxo pipefail

mkdir -p build
cd build

emcmake cmake .. \
    -D CMAKE_BUILD_TYPE=Release \
    -D CMAKE_INSTALL_PREFIX="${PREFIX}" \
    -D BUILD_SHARED_LIBS=OFF \
    -D GC_BUILD_SHARED_LIBS=OFF \
    -D enable_threads=OFF \
    -D enable_emscripten_asyncify=OFF \
    -D enable_cplusplus=ON \
    -D BUILD_TESTING=ON \
    -D build_tests=ON





emmake make -j8

# show all built files
ls



# iterate over all *.js files in a for loop
for js_file in $(find . -name "*.js"); do
    echo "Running $js_file"
    node "$js_file"
    # get return code
    ret=$?
    if [ $ret -ne 0 ]; then
        echo "Test $js_file failed with return code $ret"
        exit $ret
    fi
done

# note from DerThorsten
# tests seem to fail...


emmake make install