#!/bin/bash

set -eux

# Requires glib-mkenums to generate some headers during the build process,
# so this executable must come from the build environment.
ln -s $BUILD_PREFIX/bin/glib-mkenums $PREFIX/bin/glib-mkenums

meson_config_args=(
    -Dintrospection=disabled # requires gobject-introspection as run-time dep
    -Dfontconfig=enabled
    -Dfreetype=enabled
    -Dcairo=enabled
    -Dlibthai=disabled
    -Dxft=disabled
    -Ddocumentation=false
    -Dbuild-examples=false
    -Dbuild-testsuite=false
)

meson setup builddir \
    "${meson_config_args[@]}" \
    --buildtype=release \
    --default-library=static \
    --prefer-static \
    --prefix=$PREFIX \
    -Dlibdir=lib \
    --wrap-mode=nofallback \
    --cross-file=$RECIPE_DIR/emscripten.meson.cross

ninja -v -C builddir -j ${CPU_COUNT}
ninja -C builddir install -j ${CPU_COUNT}

# Remove the symlink to glib-mkenums
rm $PREFIX/bin/glib-mkenums

# These worker files do not get installed by the meson install command
cp builddir/utils/*.worker.js $PREFIX/bin/