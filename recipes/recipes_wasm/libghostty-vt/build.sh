#!/usr/bin/env bash
set -euxo pipefail

cd "$SRC_DIR"
export ZIG_GLOBAL_CACHE_DIR="${ZIG_GLOBAL_CACHE_DIR:-$SRC_DIR/zig-global-cache}"
zig_command=""
for candidate in "${ZIG:-}" "${CONDA_ZIG_BUILD:-}" zig; do
    if [[ -n "$candidate" ]] && command -v "$candidate" >/dev/null; then
        zig_command="$candidate"
        break
    fi
done
if [[ -z "$zig_command" ]]; then
    echo "Cannot find the build-platform Zig compiler" >&2
    exit 1
fi

"$zig_command" build \
    -Demit-lib-vt=true -Demit-xcframework=false \
    --prefix "$PREFIX" --system "$SRC_DIR/vt-deps" \
    -Dtarget=wasm32-emscripten -Dcpu=baseline -Doptimize=fast \
    -Dsimd=false -Dapp-runtime=none -Demit-exe=false \
    -Demit-docs=false -Demit-macos-app=false

# Link with emcc so Python/CFFI can dlopen the library in the host runtime.
read -r -a cflags <<< "${CFLAGS:-}"
emcc "${cflags[@]}" -O2 -sSIDE_MODULE=1 -shared \
    -Wl,--whole-archive "$PREFIX/lib/libghostty-vt.a" -Wl,--no-whole-archive \
    -o "$PREFIX/lib/libghostty-vt.so"
mkdir -p "$PREFIX/include/ghostty" "$PREFIX/lib/pkgconfig"
cp -R include/ghostty/. "$PREFIX/include/ghostty/"

for name in libghostty-vt libghostty-vt-static; do
    libs='-L${libdir} -lghostty-vt'
    includes='-I${includedir}'
    if [[ "$name" == libghostty-vt-static ]]; then
        libs='${libdir}/libghostty-vt.a'
        includes+=' -DGHOSTTY_STATIC'
    fi
    cat > "$PREFIX/lib/pkgconfig/$name.pc" <<EOF
prefix=$PREFIX
libdir=\${prefix}/lib
includedir=\${prefix}/include

Name: $name
Description: Ghostty VT parsing library
Version: $PKG_VERSION
Libs: $libs
Cflags: $includes
EOF
done
