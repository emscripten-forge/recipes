#!/usr/bin/env bash
set -euxo pipefail

recipe_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
cd "$work"
read -r -a cflags <<< "${CFLAGS:-}"

# Test static linking and the dlopen/dlsym path used by ABI-mode Python CFFI.
for mode in static dynamic; do
    options=("$PREFIX/lib/libghostty-vt.a")
    if [[ "$mode" == dynamic ]]; then
        options=(-DTEST_DYNAMIC -sMAIN_MODULE=1 --preload-file
            "$PREFIX/lib/libghostty-vt.so@/libghostty-vt.so")
    fi
    emcc "${cflags[@]}" -O2 -UNDEBUG -I"$PREFIX/include" \
        "$recipe_dir/test-lib.c" "${options[@]}" \
        -sEXIT_RUNTIME=1 -sALLOW_MEMORY_GROWTH=1 -o "test-$mode.js"
    output=$(timeout 120 node "test-$mode.js")
    printf '%s\n' "$output"
    # Preload failures can exit zero before the test's main() is called.
    [[ "$output" == *"libghostty-vt C API smoke test passed"* ]]
done
