#!/bin/bash

echo "R_HOME=${BUILD_PREFIX}/lib/R" > "${BUILD_PREFIX}/lib/R/etc/Makeconf"
cat "${PREFIX}/lib/R/etc/Makeconf" >> "${BUILD_PREFIX}/lib/R/etc/Makeconf"

export R="${BUILD_PREFIX}/bin/R"
export R_ARGS="--no-byte-compile --no-test-load --library=$PREFIX/lib/R/library"

# Populate shared libraries to enable lazy loading
find ${BUILD_PREFIX}/lib/R/library -path "*/libs/*.so" | while read -r so_file; do
    relative_path="${so_file#${BUILD_PREFIX}/}"
    if [ -f "${PREFIX}/${relative_path}" ]; then
        cp ${so_file} ${PREFIX}/${relative_path}
    fi
done
