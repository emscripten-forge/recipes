#!/bin/bash

echo "Using wasm-ld wrapper..."

# Filter out the -R flags from the arguments
filtered_args=()
skip_next=false

for arg in "$@"; do
    if [ "$skip_next" = true ]; then
        skip_next=false
        continue
    fi

    case "$arg" in
        -R)
            skip_next=true
            ;;
        *)
            filtered_args+=("$arg")
            ;;
    esac
done

# Call the actual wasm-ld command with the filtered arguments
echo "call  $PREFIX/opt/emsdk/upstream/emscripten/emcc copy with args: ${filtered_args[@]}"


$BUILD_PREFIX/opt/emsdk/upstream/emscripten/emcc "${filtered_args[@]}"

exit $?