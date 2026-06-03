#!/bin/bash
set -euo pipefail

# Build a standalone executable for the smoke test rather than a side module.
export CXXFLAGS="${CXXFLAGS:-} ${EM_FORGE_CFLAGS_BASE:-} -I${PREFIX}/include"
export LDFLAGS="${LDFLAGS:-} ${EM_FORGE_LDFLAGS_BASE:-}"

download_model() {
    local destination="$1"
    local url="$2"

    curl --fail --location --retry 3 --output "${destination}" "${url}"
}

emcmake cmake -S tests -B build_tests \
    -GNinja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_PREFIX_PATH="${PREFIX}" \
    -Dexecutorch_DIR="${PREFIX}/lib/cmake/ExecuTorch"

emmake ninja -C build_tests
node build_tests/test_executorch.js


smollm3_model_path="${EXECUTORCH_SMOLLM3_MODEL_PATH:-}"
smollm3_model_url="${EXECUTORCH_SMOLLM3_MODEL_URL:-https://huggingface.co/pytorch/SmolLM3-3B-INT8-INT4/resolve/main/model.pte}"

if [ -n "${smollm3_model_url}" ] && [ -z "${smollm3_model_path}" ]; then
    smollm3_cache_dir="${EXECUTORCH_SMOLLM3_CACHE_DIR:-$PWD/smollm3-cache}"
    smollm3_model_path="${smollm3_cache_dir}/SmolLM3-3B-INT8-INT4.pte"
    mkdir -p "${smollm3_cache_dir}"

    if [ ! -f "${smollm3_model_path}" ]; then
        download_model "${smollm3_model_path}" "${smollm3_model_url}"
    fi
fi

if [ -n "${smollm3_model_path}" ]; then
    node build_tests/test_model_metadata.js \
        "${smollm3_model_path}" \
        "${EXECUTORCH_SMOLLM3_EXPECTED_METHOD:-forward}" \
        "SmolLM3"
fi