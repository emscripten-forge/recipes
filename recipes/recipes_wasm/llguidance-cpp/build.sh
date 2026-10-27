#!/bin/bash
set -euxo pipefail

if [ "$target_platform" == "emscripten-wasm32" ]; then
    RUST_TARGET=wasm32-unknown-emscripten
elif [ "$target_platform" == "emscripten-wasm64" ]; then
    RUST_TARGET=wasm64-unknown-emscripten
fi

# Build the parser crate with WASM-appropriate features
# Disable rayon (threading not available in WASM)
# Disable wasm feature (uses instant crate which calls _emscripten_get_now,
#   not available in side modules; std::time::Instant works instead)
# Keep lark (grammar syntax) and referencing (JSON $ref support)
# Use cargo rustc with --crate-type staticlib to avoid cdylib build,
# which fails on emscripten when SIDE_MODULE=2 exports Rust-mangled symbols
# (e.g. serde_json::value::Index) that contain invalid export name characters.
cargo rustc \
    --target ${RUST_TARGET} \
    --release \
    --package llguidance \
    --no-default-features \
    --features "lark,referencing" \
    --crate-type staticlib

echo "Installing library and headers..."

# Install static library
mkdir -p $PREFIX/lib
cp target/${RUST_TARGET}/release/libllguidance.a $PREFIX/lib/

# Install C header (pre-generated, committed in repo)
mkdir -p $PREFIX/include
cp parser/llguidance.h $PREFIX/include/

# Install CMake config files
mkdir -p $PREFIX/lib/cmake/llguidance

# llguidanceConfigVersion.cmake
cat > $PREFIX/lib/cmake/llguidance/llguidanceConfigVersion.cmake << 'CMAKE_EOF'
set(PACKAGE_VERSION "LLG_VERSION_PLACEHOLDER")

if(PACKAGE_VERSION VERSION_LESS PACKAGE_FIND_VERSION)
    set(PACKAGE_VERSION_COMPATIBLE FALSE)
else()
    if(PACKAGE_VERSION MATCHES "^([0-9]+)\\.")
        set(CVF_VERSION_MAJOR "${CMAKE_MATCH_1}")
        if(NOT CVF_VERSION_MAJOR VERSION_EQUAL 0)
            string(REGEX REPLACE "^0+" "" CVF_VERSION_MAJOR "${CVF_VERSION_MAJOR}")
        endif()
    else()
        set(CVF_VERSION_MAJOR "${PACKAGE_VERSION}")
    endif()

    if(PACKAGE_FIND_VERSION_MAJOR STREQUAL CVF_VERSION_MAJOR)
        set(PACKAGE_VERSION_COMPATIBLE TRUE)
    else()
        set(PACKAGE_VERSION_COMPATIBLE FALSE)
    endif()

    if(PACKAGE_FIND_VERSION STREQUAL PACKAGE_VERSION)
        set(PACKAGE_VERSION_EXACT TRUE)
    endif()
endif()
CMAKE_EOF
sed -i.bak "s/LLG_VERSION_PLACEHOLDER/${PKG_VERSION}/" $PREFIX/lib/cmake/llguidance/llguidanceConfigVersion.cmake
rm $PREFIX/lib/cmake/llguidance/llguidanceConfigVersion.cmake.bak

# llguidanceConfig.cmake
cat > $PREFIX/lib/cmake/llguidance/llguidanceConfig.cmake << 'CMAKE_EOF'
include("${CMAKE_CURRENT_LIST_DIR}/llguidanceTargets.cmake")
CMAKE_EOF

# llguidanceTargets.cmake
cat > $PREFIX/lib/cmake/llguidance/llguidanceTargets.cmake << 'CMAKE_EOF'
if(NOT TARGET llguidance::llguidance)
    add_library(llguidance::llguidance STATIC IMPORTED)
    set_target_properties(llguidance::llguidance PROPERTIES
        IMPORTED_LOCATION "${CMAKE_CURRENT_LIST_DIR}/../../libllguidance.a"
        INTERFACE_INCLUDE_DIRECTORIES "${CMAKE_CURRENT_LIST_DIR}/../../../include"
    )
endif()
CMAKE_EOF

echo "=========================================="
echo "llguidance build complete"
echo "=========================================="
