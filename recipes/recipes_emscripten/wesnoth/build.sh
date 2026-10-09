#!/usr/bin/env bash
set -euxo pipefail
cmake ${CMAKE_ARGS:-} -S . -B build -GNinja   -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$PREFIX" -DCMAKE_PREFIX_PATH="$PREFIX"   -DENABLE_GAME=ON -DENABLE_SERVER=OFF -DENABLE_CAMPAIGN_SERVER=OFF -DENABLE_TESTS=OFF   -DENABLE_NLS=OFF -DENABLE_SYSTEM_LUA=ON -DLUA_DIR="$PREFIX" -DENABLE_NOTIFICATIONS=OFF   -DENABLE_DESKTOP_ENTRY=OFF -DENABLE_APPDATA_FILE=OFF -DENABLE_DISPLAY_REVISION=OFF   -DENABLE_LTO=OFF -DHARDEN=OFF -DWESNOTH_EMSCRIPTEN_PRELOAD_ASSETS=ON
cmake --build build --target wesnoth
install -d "$PREFIX/bin"
for f in build/wesnoth.js build/wesnoth.wasm build/wesnoth.data; do
  test -f "$f"
  install -m 0644 "$f" "$PREFIX/bin/$(basename "$f")"
done
