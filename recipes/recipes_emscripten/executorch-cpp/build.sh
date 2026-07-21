#!/bin/bash
set -euo pipefail

export CFLAGS="${CFLAGS:-} ${EM_FORGE_SIDE_MODULE_CFLAGS:-}"
export CXXFLAGS="${CXXFLAGS:-} ${EM_FORGE_SIDE_MODULE_CFLAGS:-}"
export LDFLAGS="${LDFLAGS:-} ${EM_FORGE_SIDE_MODULE_LDFLAGS:-}"

src_dir="$(dirname "$PWD")/executorch"
ln -sfn "$PWD" "$src_dir"
export PYTHONPATH="$(dirname "$src_dir"):${PYTHONPATH:-}"

rm -rf third-party/flatbuffers
mkdir -p third-party/flatbuffers
ln -sfn "${PREFIX}/include" third-party/flatbuffers/include

rm -rf third-party/gflags
mkdir -p third-party/gflags
cp "${RECIPE_DIR}/gflags.cmake" third-party/gflags/CMakeLists.txt

rm -rf backends/xnnpack/third-party/FXdiv
mkdir -p backends/xnnpack/third-party/FXdiv
ln -sfn "${PREFIX}/include" backends/xnnpack/third-party/FXdiv/include
cp "${RECIPE_DIR}/fxdiv.cmake" backends/xnnpack/third-party/FXdiv/CMakeLists.txt

emcmake cmake -S "$src_dir" -B build \
    -GNinja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_PREFIX_PATH="${PREFIX}" \
    -Dgflags_DIR="${PREFIX}/lib/cmake/gflags" \
    -Dnlohmann_json_DIR="${PREFIX}/share/cmake/nlohmann_json" \
    -DBUILD_TESTING=OFF \
    -DEXECUTORCH_BUILD_TESTS=OFF \
    -DEXECUTORCH_BUILD_DEVTOOLS=OFF \
    -DEXECUTORCH_BUILD_EXECUTOR_RUNNER=OFF \
    -DEXECUTORCH_BUILD_EXTENSION_DATA_LOADER=ON \
    -DEXECUTORCH_BUILD_EXTENSION_FLAT_TENSOR=ON \
    -DEXECUTORCH_BUILD_EXTENSION_MODULE=ON \
    -DEXECUTORCH_BUILD_EXTENSION_NAMED_DATA_MAP=ON \
    -DEXECUTORCH_BUILD_EXTENSION_TENSOR=ON \
    -DEXECUTORCH_BUILD_CPUINFO=OFF \
    -DEXECUTORCH_BUILD_PTHREADPOOL=OFF \
    -DEXECUTORCH_BUILD_WASM=ON \
    -DEXECUTORCH_BUILD_XNNPACK=OFF

emmake ninja -C build -j"${CPU_COUNT}"
emmake ninja -C build install

if [ -f build/lib/libextension_evalue_util.a ]; then
    install -Dm644 build/lib/libextension_evalue_util.a "${PREFIX}/lib/libextension_evalue_util.a"
    sed -i "s|\"$PWD/build/lib/libextension_evalue_util.a\"|\"\${_IMPORT_PREFIX}/lib/libextension_evalue_util.a\"|g" \
        "${PREFIX}/lib/cmake/ExecuTorch/ExecuTorchTargets-release.cmake"
fi