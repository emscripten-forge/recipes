#!/bin/bash
# This script moves some libraries from the linux build directory to the wasm
# build directory. This is required in order to use the build platform's R
# executables when cross-compiling.

set -u

TARGET_PATH=$2

libraries=("tools" "grDevices" "graphics" "utils" "stats" "methods") # "lapack"

setup() {
    for lib in "${libraries[@]}"; do
    if [ -d "${TARGET_PATH}/library/$lib/libs/" ]; then
        if [ ! -f "${TARGET_PATH}/library/$lib/libs/$lib.so.bak" ]; then
            echo "Backing up $lib.so"
            mv "${TARGET_PATH}/library/$lib/libs/$lib.so" "${TARGET_PATH}/library/$lib/libs/$lib.so.bak"
        fi
        if [ -f "${TARGET_PATH}/library/$lib/libs/$lib.so.bak" ]; then
            cp ${LINUX_BUILD_DIR}/library/${lib}/libs/${lib}.so ${TARGET_PATH}/library/$lib/libs/
        fi
    fi
    done

    if [ ! -f "${TARGET_PATH}/modules/lapack.so.bak" ]; then
        mv "${TARGET_PATH}/modules/lapack.so" "${TARGET_PATH}/modules/lapack.so.bak"
    fi
    if [ -f "${TARGET_PATH}/modules/lapack.so.bak" ]; then
        cp ${LINUX_BUILD_DIR}/modules/lapack.so "${TARGET_PATH}/modules/lapack.so"
    fi
}

restore() {
    echo "Restoring libraries"
    for lib in "${libraries[@]}"; do
        rm $TARGET_PATH/library/$lib/libs/$lib.so
        mv $TARGET_PATH/library/$lib/libs/$lib.so.bak $TARGET_PATH/library/$lib/libs/$lib.so
    done

    rm $TARGET_PATH/modules/lapack.so
    mv $TARGET_PATH/modules/lapack.so.bak $TARGET_PATH/modules/lapack.so
}

if [ "$1" == "--setup" ]; then
    setup
elif [ "$1" == "--restore" ]; then
    restore
else
    echo "Invalid arguments. Use '--setup <path>' or '--restore <path>'"
    exit 1
fi
