#!/bin/bash
set -e

# Install our custom CMake config file to make it easier to find and use thrift
mkdir -p $PREFIX/lib/cmake/thrift-emscripten

# Copy our custom config file
cp $RECIPE_DIR/thrift-config.cmake $PREFIX/lib/cmake/thrift-emscripten/thrift-config.cmake

# Create a config version file
cat > $PREFIX/lib/cmake/thrift-emscripten/thrift-config-version.cmake << 'EOF'
# thrift-config-version.cmake
set(PACKAGE_VERSION "0.22.0")

if(PACKAGE_VERSION VERSION_LESS PACKAGE_FIND_VERSION)
    set(PACKAGE_VERSION_COMPATIBLE FALSE)
else()
    set(PACKAGE_VERSION_COMPATIBLE TRUE)
    if(PACKAGE_FIND_VERSION STREQUAL PACKAGE_VERSION)
        set(PACKAGE_VERSION_EXACT TRUE)
    endif()
endif()
EOF

# Create lowercase wrapper in the main thrift cmake directory
# to fix case-sensitivity issue (CMake looks for thriftConfig.cmake, but upstream installs ThriftConfig.cmake)
cat > $PREFIX/lib/cmake/thrift/thrift-config.cmake << 'EOF'
# Wrapper to uppercase config file for case-sensitive compatibility
include("${CMAKE_CURRENT_LIST_DIR}/ThriftConfig.cmake")
EOF

echo "Custom CMake config files installed to $PREFIX/lib/cmake/thrift-emscripten/"
