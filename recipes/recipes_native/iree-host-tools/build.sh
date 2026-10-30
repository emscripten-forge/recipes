#!/bin/bash
set -euxo pipefail

cmake ${CMAKE_ARGS} -S . -B build -G "Unix Makefiles" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
    -DCMAKE_PREFIX_PATH="${PREFIX}" \
    -DIREE_BUILD_BUNDLED_LLVM=OFF \
    -DIREE_BUILD_COMPILER=ON \
    -DIREE_BUILD_TESTS=OFF \
    -DIREE_BUILD_SAMPLES=OFF \
    -DIREE_BUILD_BENCHMARKS=OFF \
    -DIREE_BUILD_PYTHON_BINDINGS=OFF \
    -DIREE_ENABLE_LIBBACKTRACE=OFF \
    -DIREE_ENABLE_WERROR_FLAG=OFF \
    -DIREE_ERROR_ON_MISSING_SUBMODULES=OFF \
    -DIREE_TARGET_BACKEND_DEFAULTS=OFF \
    -DIREE_TARGET_BACKEND_VMVX=OFF \
    -DIREE_HAL_DRIVER_DEFAULTS=OFF \
    -DIREE_INPUT_STABLEHLO=ON \
    -DSTABLEHLO_ENABLE_TESTS=OFF \
    -DIREE_INPUT_TORCH=OFF \
    -DIREE_INPUT_TOSA=OFF

make -C build -j"${CPU_COUNT:-2}" \
    iree-tblgen iree-flatcc-cli mlir_builder_tblgen iree-c-embed-data

mkdir -p "${PREFIX}/bin"
cp build/tools/iree-tblgen build/tools/iree-flatcc-cli \
    build/tools/iree-c-embed-data \
    build/llvm-external-projects/stablehlo/stablehlo/integrations/cpp/builder/mlir_builder_tblgen \
    "${PREFIX}/bin/"
