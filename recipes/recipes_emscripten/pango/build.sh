#!/usr/bin/env bash
set -euxo pipefail
meson setup build   --prefix="$PREFIX"   --cross-file="$RECIPE_DIR/emscripten.meson.cross"   --buildtype=release   --default-library=static   --prefer-static   --wrap-mode=nofallback   -Dintrospection=disabled   -Ddocumentation=false   -Dbuild-examples=false   -Dbuild-tests=false   -Dfontconfig=enabled   -Dfreetype=enabled   -Dcairo=enabled   -Dxft=disabled   -Dlibthai=disabled   -Dsysprof=disabled
ninja -C build
ninja -C build install
