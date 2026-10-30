#!/bin/bash
set -e

export CXXFLAGS="${CXXFLAGS:-} -fPIC"

echo "=========================================="
echo "Building test for onnxruntime-wasm..."
echo "=========================================="

mkdir -p build_ort
cd build_ort

MODEL_DIR="../tests"
MODEL_BASE_URL="https://huggingface.co/onnx-community/TinyStories-Instruct-1M-ONNX/resolve/main/onnx"

download_if_missing() {
    local file_name="$1"
    local target_path="${MODEL_DIR}/${file_name}"
    if [[ -f "${target_path}" ]]; then
        echo "Using existing ${target_path}"
        return
    fi
    echo "Downloading ${file_name}..."
    curl -fL "${MODEL_BASE_URL}/${file_name}" -o "${target_path}"
}

download_if_missing "model.onnx"
download_if_missing "model_fp16.onnx"

emcmake cmake ../tests \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_FIND_ROOT_PATH="${PREFIX}" \
    -DCMAKE_PREFIX_PATH="${PREFIX}"

emmake make

echo "Running test for onnxruntime-wasm..."
node test_ort.js

cd ..

echo "=========================================="
echo "All tests passed!"
echo "=========================================="
