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
emcc "${filtered_args[@]}"
