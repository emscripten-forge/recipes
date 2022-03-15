echo "ACTIVATE EMSDK: CONDA_EMSDK_DIR===>" $CONDA_EMSDK_DIR 

unset PYTHON

pushd $CONDA_EMSDK_DIR
./emsdk install  3.1.2
./emsdk activate 3.1.2
source emsdk_env.sh
popd

export CMAKE_ARGS="$CMAKE_ARGS -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ON -DCMAKE_POSITION_INDEPENDENT_CODE:BOOL=true"


cmake () {
    emcmake cmake "$@"
}

# make () {
#     emmake make "$@"
# }

# configue () {
#     emconfigue configue "$@"
# }
