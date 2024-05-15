#!/usr/bin/env 

CONDA_EMSDK_DIR_CONFIG_FILE=$HOME/.emsdkdir
if test -f "$CONDA_EMSDK_DIR_CONFIG_FILE"; then
    echo "Found config file $CONDA_EMSDK_DIR_CONFIG_FILE"
else
    # return an error
    echo "Config file $CONDA_EMSDK_DIR_CONFIG_FILE not found"
    return 1
fi

export EMSDK_DIR=$(<$CONDA_EMSDK_DIR_CONFIG_FILE)
