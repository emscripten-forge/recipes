meson setup builddir \
    --default-library=static \
    --prefer-static \
    --prefix=$PREFIX \
    --cross-file=$MESON_CROSS_FILE

ninja -v -C builddir -j ${CPU_COUNT}
ninja -C builddir install -j ${CPU_COUNT}
