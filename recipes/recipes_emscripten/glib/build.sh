#!/bin/bash

meson_config_args=(
    -Dintrospection=disabled
    -Dselinux=disabled
    -Dlibmount=disabled
    -Dnls=disabled
    -Dxattr=false
    -Dtests=false
    -Dglib_assert=false
    -Dglib_checks=false
)

meson setup builddir \
    "${meson_config_args[@]}" \
    --prefix=$PREFIX \
    --cross-file=$RECIPE_DIR/emscripten.meson.cross \
    --default-library=static \
    --buildtype=release \
    --force-fallback-for=pcre2,gvdb

meson install -C builddir --tag devel
