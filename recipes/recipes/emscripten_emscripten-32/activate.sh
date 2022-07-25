
if [ -z ${CONDA_FORGE_EMSCRIPTEN_ACTIVATED+x} ]; then
    export CONDA_FORGE_EMSCRIPTEN_ACTIVATED=1

    export EMSDK_PYTHON=${BUILD_PREFIX}/bin/python3
    export PYTHON=${BUILD_PREFIX}/bin/python3

    emsdk install  ${PKG_VERSION}
    emsdk activate ${PKG_VERSION}
    export CONDA_EMSDK_DIR=$BUILD_PREFIX/lib/python$($PYTHON -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")/site-packages/emsdk
    source $CONDA_EMSDK_DIR/emsdk_env.sh

    export PATH="$CONDA_EMSDK_DIR/upstream/emscripten/":$PATH

    export CMAKE_ARGS="$CMAKE_ARGS -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ON -DCMAKE_POSITION_INDEPENDENT_CODE:BOOL=true"

    cmake () {
        emcmake cmake "$@"
    }

    # usefull variables
    export PY_SIDE_LD_FLAGV

    # basics
    export EM_FORGE_OPTFLAGS="-O2"
    export EM_FORGE_DBGFLAGS="-g0"

    # basics ld
    export EM_FORGE_LDFLAGS_BASE="-s MODULARIZE=1 -s LINKABLE=1 -s EXPORT_ALL=1 -s WASM=1 -std=c++14 -s LZ4=1"
    export EM_FORGE_LDFLAGS_BASE="${EM_FORGE_OPTFLAGS} ${EM_FORGE_DBGFLAGS} ${EM_FORGE_LDFLAGS_BASE}"

    # basics cflags
    export EM_FORGE_CFLAGS_BASE="-fPIC"
    export EM_FORGE_CFLAGS_BASE="${EM_FORGE_OPTFLAGS} ${EM_FORGE_DBGFLAGS} ${EM_FORGE_CFLAGS_BASE}"

    # side module
    export EM_FORGE_SIDE_MODULE_LDFLAGS="${LDFLAGS_BASE} -s SIDE_MODULE=1"
    export EM_FORGE_SIDE_MODULE_CFLAGS="${EM_FORGE_CFLAGS_BASE} -I${PREFIX}/include"

fi


