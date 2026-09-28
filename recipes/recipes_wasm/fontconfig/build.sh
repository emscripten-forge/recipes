#!/bin/bash

set -ex

sed -i "s|@(PYTHON)|${PYTHON}|g" "${MESON_CROSS_FILE}"


meson_setup_args=(
    -Dtests=disabled
    -Dtools=disabled
)

meson setup builddir \
    ${meson_setup_args[@]} \
    --prefix=$PREFIX \
    --buildtype=release \
    --prefer-static \
    --default-library=static \
    --cross-file=$MESON_CROSS_FILE

meson install -C builddir
