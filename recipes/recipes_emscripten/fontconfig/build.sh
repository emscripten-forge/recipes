#/bin/bash

meson_setup_args=(
    -Dtests=disabled
    -Ddefault_library=static
    -Dtools=disabled
)

meson setup builddir \
    ${meson_setup_args[@]} \
    --prefix=$PREFIX \
    --buildtype=release \
    --prefer-static \
    --cross-file=$RECIPE_DIR/emscripten.meson.cross

meson install -C builddir
