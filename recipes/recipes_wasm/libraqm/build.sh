meson setup builddir \
    -Dtests=false \
    -Dsheenbidi=true \
    --buildtype=release \
    --default-library=static \
    --prefer-static \
    --prefix=$PREFIX \
    --wrap-mode=nofallback \
    --cross-file=$MESON_CROSS_FILE

ninja -v -C builddir -j ${CPU_COUNT}
ninja -C builddir install -j ${CPU_COUNT}
