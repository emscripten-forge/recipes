echo "ACTIVATE ALIASES FRESH!!!"

unset PYTHON

pushd $EMSDK_DIR
./emsdk install  3.1.2
./emsdk activate 3.1.2
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
