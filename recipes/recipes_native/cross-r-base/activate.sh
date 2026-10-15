#!/bin/bash

MAKECONF_FILE="${BUILD_PREFIX}/lib/R/etc/Makeconf"
echo "R_HOME=$PREFIX/lib/R" > $MAKECONF_FILE
echo "R_INCLUDE_DIR=$PREFIX/lib/R/include" >> $MAKECONF_FILE
echo "R_SHARE_DIR=$PREFIX/lib/R/share" >> $MAKECONF_FILE
cat "${PREFIX}/lib/R/etc/Makeconf" >> $MAKECONF_FILE

export R="${BUILD_PREFIX}/bin/R"
export R_ARGS="--no-byte-compile --no-test-load --library=$PREFIX/lib/R/library"

# Populate shared libraries to enable lazy loading
find ${BUILD_PREFIX}/lib/R/library -path "*/libs/*.so" | while read -r so_file; do
    relative_path="${so_file#${BUILD_PREFIX}/}"
    if [ -f "${PREFIX}/${relative_path}" ]; then
        cp --remove-destination ${so_file} ${PREFIX}/${relative_path}
    fi
done
