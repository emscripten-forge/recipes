#!/bin/bash
set -euo pipefail

if [ "$target_platform" == "emscripten-wasm32" ]; then
    RUST_TARGET=wasm32-unknown-emscripten
elif [ "$target_platform" == "emscripten-wasm64" ]; then
    RUST_TARGET=wasm64-unknown-emscripten
fi

echo "=========================================="
echo "Building tokenizers-cpp for ${target_platform}"
echo "=========================================="

# ============================================================================
# Step 1: Build Rust tokenizers_c library
# ============================================================================
echo "Building Rust tokenizers_c library..."

cd "${SRC_DIR}"

# Fix: BPE::new expects AHashMap (Vocab type) in tokenizers 0.21.x
# Upstream fix: https://github.com/mlc-ai/tokenizers-cpp/commit/e8964871dda750164787d8fba23e1451918677d4
# (version bump to 0.21.0 moved Vocab from std::HashMap to ahash::AHashMap)
# Fix: raw pointer autoref `.len()` calls for newer Rust nightly
# Upstream fix: https://github.com/mlc-ai/tokenizers-cpp/commit/55d53aa38dc8df7d9c8bd9ed50907e82ae83ce66
# (Rust 2024+ warns on implicit autoref of raw pointers; uses &(*p).f pattern)
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
content = content.replace('(*handle).decode_str.len()', '(&(*handle).decode_str).len()')
content = content.replace('(*handle).id_to_token_result.len()', '(&(*handle).id_to_token_result).len()')
open('rust/src/lib.rs', 'w').write(content)
"

cargo build \
    --target ${RUST_TARGET} \
    --manifest-path rust/Cargo.toml \
    --release

RUST_LIB="${SRC_DIR}/rust/target/${RUST_TARGET}/release/libtokenizers_c.a"
echo "Rust library built."

# ============================================================================
# Step 2: Build C++ tokenizers_cpp (direct compilation)
# ============================================================================
echo "Building C++ tokenizers_cpp library..."

mkdir -p "${SRC_DIR}/build_cpp"
cd "${SRC_DIR}/build_cpp"
cp "${RUST_LIB}" ./libtokenizers_c.a

CXX_FLAGS="-std=c++17 -O2 -DMLC_ENABLE_SENTENCEPIECE_TOKENIZER -DMSGPACK_NO_BOOST -I${SRC_DIR}/include -I${PREFIX}/include ${CXXFLAGS:-}"

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

python3 -c "
import sys
src, dst, ver = sys.argv[1:4]
open(dst, 'w').write(open(src).read().replace('@PKG_VERSION@', ver))
" "${RECIPE_DIR}/tokenizers-cppConfigVersion.cmake" \
  "${PREFIX}/lib/cmake/tokenizers-cpp/tokenizers-cppConfigVersion.cmake" \
  "${PKG_VERSION}"
cp "${RECIPE_DIR}/tokenizers-cppTargets.cmake" "${PREFIX}/lib/cmake/tokenizers-cpp/"
cp "${RECIPE_DIR}/tokenizers-cppConfig.cmake" "${PREFIX}/lib/cmake/tokenizers-cpp/"
