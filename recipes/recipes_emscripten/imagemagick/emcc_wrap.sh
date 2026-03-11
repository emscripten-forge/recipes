#!/bin/bash
# Wrapper for emcc compiler to remove unsupported flags

# Remove -force_load flag which is not supported by emscripten
args=()
skip_next=false

for arg in "$@"; do
    if [ "$skip_next" = true ]; then
        skip_next=false
        continue
    fi
    
    if [ "$arg" = "-force_load" ]; then
        skip_next=false
        continue
    fi
    
    args+=("$arg")
done

# Call emcc with filtered arguments with orginal emcc we backuped before
exec emcc_orig "${args[@]}"