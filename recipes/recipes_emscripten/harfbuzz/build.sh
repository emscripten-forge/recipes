# These are the config options used by matplotlib when building harfbuzz
meson_config_args=(
    -Dbenchmark=disabled
    -Dcairo=disabled
    -Dchafa=disabled
    -Dcoretext=disabled
    -Ddirectwrite=disabled
    -Ddocs=disabled
    -Ddoc_tests=false
    -Dfontations=disabled
    -Dfreetype=enabled
    -Dgdi=disabled
    -Dglib=disabled
    -Dgobject=disabled
    -Dgpu=disabled
    -Dgpu_demo=disabled
    -Dharfrust=disabled
    -Dicu=disabled
    -Dintrospection=disabled
    -Dkbts=disabled
    -Dpng=disabled
    -Draster=disabled
    -Dsubset=disabled
    -Dtests=disabled
    -Dutilities=disabled
    -Dvector=disabled
    -Dwasm=disabled
    -Dzlib=disabled
)

meson setup builddir \
    "${meson_config_args[@]}" \
    --buildtype=release \
    --default-library=static \
    --prefer-static \
    --prefix=$PREFIX \
    --wrap-mode=nofallback \
    --cross-file=$RECIPE_DIR/emscripten.meson.cross

ninja -v -C builddir -j ${CPU_COUNT}
ninja -C builddir install -j ${CPU_COUNT}
