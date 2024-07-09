#!/bin/bash

echo "Using wasm-ld wrapper..."

# Initialize an array to hold the modified arguments
modified_args=()

# Iterate over all the arguments passed to the script
for arg in "$@"; do
  # If the argument contains "-R$PREFIX/lib", remove that part
  if [[ "$arg" == *'-R$PREFIX/lib'* ]]; then
    arg="${arg//-R\$PREFIX\/lib/}"
  fi
  # Add the modified or unmodified argument to the array
  modified_args+=("$arg")
done

# Call the actual wasm-ld command with the filtered arguments
echo "call  $BUILD_PREFIX/opt/emsdk/upstream/emscripten/emcc copy with args: ${modified_args[@]}"


$BUILD_PREFIX/opt/emsdk/upstream/emscripten/emcc "${modified_args[@]}"

exit $?