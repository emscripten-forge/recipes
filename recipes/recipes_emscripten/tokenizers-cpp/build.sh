#!/bin/bash
set -euo pipefail

echo "=========================================="
echo "Building tokenizers-cpp for emscripten-wasm32"
echo "=========================================="

# Build plain static archives here. Downstream tests link these into a
# standalone executable under Node, so side-module linker settings corrupt
# the resulting wasm at runtime.
export CFLAGS="${CFLAGS:-} ${EM_FORGE_CFLAGS_BASE:-}"
export CXXFLAGS="${CXXFLAGS:-} ${EM_FORGE_CFLAGS_BASE:-}"
export LDFLAGS="${LDFLAGS:-} ${EM_FORGE_LDFLAGS_BASE:-}"

# ============================================================================
# Step 1: Build Rust tokenizers_c library
# ============================================================================
echo "Building Rust tokenizers_c library..."
rustup target add wasm32-unknown-emscripten

cd "${SRC_DIR}"

# Fix: BPE::new expects AHashMap (Vocab type) in tokenizers 0.21.x
# Upstream fix: https://github.com/mlc-ai/tokenizers-cpp/commit/e8964871dda750164787d8fba23e1451918677d4
# (version bump to 0.21.0 moved Vocab from std::HashMap to ahash::AHashMap)
python3 -c "
content = open('rust/src/lib.rs').read()
content = content.replace(
    'use std::{collections::HashMap, str::FromStr};',
    'use std::str::FromStr;\nuse std::collections::HashMap;'
)
content = content.replace(
    'use tokenizers::models::bpe::BPE;',
    'use tokenizers::models::bpe::BPE;\nuse tokenizers::models::bpe::Vocab as BPEVocab;'
)
content = content.replace(
    'let mut tokenizer = Tokenizer::new(BPE::new(vocab, merges));',
    'let bpe_vocab: BPEVocab = vocab.into_iter().collect();\n        let mut tokenizer = Tokenizer::new(BPE::new(bpe_vocab, merges));'
)
content = content.replace(
    '        let added_tokens_json: Value = serde_json::from_str(added_tokens).unwrap();',
    '        let added_tokens_json: Value = if added_tokens.trim().is_empty() { serde_json::json!({}) } else { serde_json::from_str(added_tokens).unwrap() };'
)
open('rust/src/lib.rs', 'w').write(content)
"

# Fix: raw pointer autoref `.len()` calls for newer Rust nightly
# Upstream fix: https://github.com/mlc-ai/tokenizers-cpp/commit/55d53aa38dc8df7d9c8bd9ed50907e82ae83ce66
# (Rust 2024+ warns on implicit autoref of raw pointers; uses &(*p).f pattern)
sed -i "s/(\\*handle)\\.decode_str\\.len()/(\\&(*handle).decode_str).len()/g" rust/src/lib.rs
sed -i "s/(\\*handle)\\.id_to_token_result\\.len()/(\\&(*handle).id_to_token_result).len()/g" rust/src/lib.rs

cargo build \
    --target wasm32-unknown-emscripten \
    --manifest-path rust/Cargo.toml \
    --release

RUST_LIB="${SRC_DIR}/rust/target/wasm32-unknown-emscripten/release/libtokenizers_c.a"
echo "Rust library built."

# ============================================================================
# Step 2: Build C++ tokenizers_cpp (direct compilation)
# ============================================================================
echo "Building C++ tokenizers_cpp library..."

mkdir -p "${SRC_DIR}/build_cpp"
cd "${SRC_DIR}/build_cpp"
cp "${RUST_LIB}" ./libtokenizers_c.a

CXX_FLAGS="-std=c++17 -O2 -DMLC_ENABLE_SENTENCEPIECE_TOKENIZER -DMSGPACK_NO_BOOST -I${SRC_DIR}/include -I${PREFIX}/include ${CXXFLAGS}"

echo "Compiling sources..."
em++ ${CXX_FLAGS} -c "${SRC_DIR}/src/sentencepiece_tokenizer.cc" -o sentencepiece_tokenizer.o
em++ ${CXX_FLAGS} -c "${SRC_DIR}/src/huggingface_tokenizer.cc" -o huggingface_tokenizer.o
em++ ${CXX_FLAGS} -c "${SRC_DIR}/src/rwkv_world_tokenizer.cc" -o rwkv_world_tokenizer.o

echo "Archiving into libtokenizers_cpp.a..."
emar rcs libtokenizers_cpp.a sentencepiece_tokenizer.o huggingface_tokenizer.o rwkv_world_tokenizer.o

# ============================================================================
# Step 3: Install
# ============================================================================

mkdir -p "${PREFIX}/lib"
cp libtokenizers_cpp.a "${PREFIX}/lib/"
cp libtokenizers_c.a "${PREFIX}/lib/"

mkdir -p "${PREFIX}/include"
cp "${SRC_DIR}/include/tokenizers_cpp.h" "${PREFIX}/include/"
cp "${SRC_DIR}/include/tokenizers_c.h" "${PREFIX}/include/"

# CMake config files
mkdir -p "${PREFIX}/lib/cmake/tokenizers-cpp"

cp "${RECIPE_DIR}/tokenizers-cppConfigVersion.cmake" "${PREFIX}/lib/cmake/tokenizers-cpp/"
sed -i "s/@PKG_VERSION@/${PKG_VERSION}/" "${PREFIX}/lib/cmake/tokenizers-cpp/tokenizers-cppConfigVersion.cmake"
cp "${RECIPE_DIR}/tokenizers-cppTargets.cmake" "${PREFIX}/lib/cmake/tokenizers-cpp/"
cp "${RECIPE_DIR}/tokenizers-cppConfig.cmake" "${PREFIX}/lib/cmake/tokenizers-cpp/"
