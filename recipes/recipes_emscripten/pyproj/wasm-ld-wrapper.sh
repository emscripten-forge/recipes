#!/bin/bash

echo "Using wasm-ld wrapper..."

# Initialize an array to hold the modified arguments
modified_args=()

# Define the pattern to remove, with proper escaping for $PREFIX
pattern='-Wl,-R$PREFIX/lib'

# Iterate over all the arguments passed to the script
for arg in "$@"; do
  # If the argument contains the pattern, remove that part
  while [[ "$arg" == *"$pattern"* ]]; do
    arg="${arg//-Wl,-R\$PREFIX\/lib/}"
  done
  # Add the modified or unmodified argument to the array
  modified_args+=("$arg")
done


# Call the actual wasm-ld command with the filtered arguments
echo "call  $BUILD_PREFIX/opt/emsdk/upstream/emscripten/emcc copy with args: ${modified_args[@]}"


$BUILD_PREFIX/opt/emsdk/upstream/emscripten/emcc "${modified_args[@]}"

exit $?