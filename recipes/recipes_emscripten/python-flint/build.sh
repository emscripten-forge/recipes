#!/bin/bash

set -ex

export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:$PKG_CONFIG_PATH"
export CPPFLAGS="-I$PREFIX/include $CPPFLAGS"
export LDFLAGS="-L$PREFIX/lib $LDFLAGS"

# Build the package using pip with meson-python backend
$PYTHON -m pip install . -Csetup-args=-Dpkg_config_path="$PREFIX/lib/pkgconfig" -vvv