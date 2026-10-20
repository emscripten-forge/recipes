#!/bin/bash
set -euo pipefail

echo "=========================================="
echo "Building tokenizers-cpp tests..."
echo "=========================================="

# Standalone executable flags (not side module)
export CFLAGS="${CFLAGS:-} ${EM_FORGE_CFLAGS_BASE:-}"
export CXXFLAGS="${CXXFLAGS:-} ${EM_FORGE_CFLAGS_BASE:-}"
export LDFLAGS="${LDFLAGS:-} ${EM_FORGE_LDFLAGS_BASE:-}"

# Download test models (same URLs as upstream build_and_run.sh)
# These will be embedded into the WASM binary via --preload-file
mkdir -p tests/dist
cd tests/dist
if [ ! -f tokenizer.model ]; then
    curl -sL -o tokenizer.model \
        https://huggingface.co/lmsys/vicuna-7b-v1.5/resolve/main/tokenizer.model
fi
if [ ! -f tokenizer.json ]; then
    curl -sL -o tokenizer.json \
        https://huggingface.co/togethercomputer/RedPajama-INCITE-Chat-3B-v1/resolve/main/tokenizer.json
fi
if [ ! -f vocab.json ]; then
    curl -sL -o vocab.json \
        https://huggingface.co/Qwen/Qwen2.5-3B-Instruct/resolve/main/vocab.json
fi
if [ ! -f merges.txt ]; then
    curl -sL -o merges.txt \
        https://huggingface.co/Qwen/Qwen2.5-3B-Instruct/resolve/main/merges.txt
fi
cd ../..

mkdir -p build_tests
cd build_tests

emcmake cmake ../tests \
    -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_PREFIX_PATH="${PREFIX}" \
    -DCMAKE_FIND_ROOT_PATH="${PREFIX}"

emmake ninja

echo "Running tokenizers-cpp tests..."
node test_tokenizers.js

echo "=========================================="
echo "All tokenizers-cpp tests passed!"
echo "=========================================="
