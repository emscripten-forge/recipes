#!/bin/bash

echo "INITAL " $PYTHON
OLD_PYTHON=$PYTHON
unset PYTHON
MYPYTHON=${BUILD_PREFIX}/bin/python3
pushd $CONDA_EMSDK_DIR
./emsdk install  3.1.2
./emsdk activate 3.1.2
source emsdk_env.sh
export PATH="$CONDA_EMSDK_DIR/upstream/emscripten/":$PATH
popd

echo "PY_VER" $PY_VER

if [[ "${CONDA_BUILD:-0}" == "1" && "${CONDA_BUILD_STATE}" != "TEST" ]]; then
  echo "Setting up cross-python"
  PY_VER=$($BUILD_PREFIX/bin/python -c "import sys; print('{}.{}'.format(*sys.version_info[:2]))")
  if [ -d "$PREFIX/lib_pypy" ]; then
    sysconfigdata_fn=$(find "$PREFIX/lib_pypy/" -name "_sysconfigdata_*.py" -type f)
  elif [ -d "$PREFIX/lib/pypy$PY_VER" ]; then
    sysconfigdata_fn=$(find "$PREFIX/lib/pypy$PY_VER/" -name "_sysconfigdata_*.py" -type f)
  else
    # find "$PREFIX/lib/" -name "_sysconfigdata*.py" -not -name ${_CONDA_PYTHON_SYSCONFIGDATA_NAME}.py -type f -exec rm -f {} +
    sysconfigdata_fn="$PREFIX/lib/python3.10/_sysconfigdata__emscripten_.py"
    # sysconfigdata_fn="$PREFIX/lib/python/${_CONDA_PYTHON_SYSCONFIGDATA_NAME}.py"
  fi
  # decho "build_time_vars['LDFLAGS'] = build_time_vars['LDSHARED'] " >> $sysconfigdata_fn 

  sed -i 's/-lffi/ /g' $sysconfigdata_fn
  sed -i 's/-lz/ /g' $sysconfigdata_fn
  sed -i 's/-fdiagnostics-color=always/ /g' $sysconfigdata_fn

  tail -3 $sysconfigdata_fn
  unset _CONDA_PYTHON_SYSCONFIGDATA_NAME
  if [[ ! -d $BUILD_PREFIX/venv ]]; then
    $BUILD_PREFIX/bin/python -m crossenv $PREFIX/bin/python3 \
        --sysroot $PREFIX \
        --without-pip $BUILD_PREFIX/venv \
        --sysconfigdata-file "$sysconfigdata_fn" \
        --cc emcc \
        --cxx emcc
    # CONDA_BUILD_SYSROOT

    # Undo cross-python's changes
    # See https://github.com/conda-forge/h5py-feedstock/pull/104
    rm -rf $BUILD_PREFIX/venv/lib/$(basename $sysconfigdata_fn)
    cp $sysconfigdata_fn $BUILD_PREFIX/venv/lib/$(basename $sysconfigdata_fn)

    # For recipes using {{ PYTHON }}
    cp $BUILD_PREFIX/venv/cross/bin/python $PREFIX/bin/python

    echo "1)"

    # don't set LIBRARY_PATH
    # See https://github.com/conda-forge/matplotlib-feedstock/pull/309#issuecomment-972213735
    sed -i 's/extra_envs = .*/extra_envs = []/g' $PREFIX/bin/python        || true
    sed -i 's/extra_envs = .*/extra_envs = []/g' $PREFIX/bin/python$PY_VER || true

    echo "2)"
    # undo symlink
    rm $BUILD_PREFIX/venv/build/bin/python
    cp $BUILD_PREFIX/bin/python $BUILD_PREFIX/venv/build/bin/python

    echo "3)"
    # For recipes looking at python on PATH
    rm $BUILD_PREFIX/bin/python
    echo "#!/bin/bash" > $BUILD_PREFIX/bin/python
    echo "exec $PREFIX/bin/python \"\$@\"" >> $BUILD_PREFIX/bin/python
    chmod +x $BUILD_PREFIX/bin/python

    if [[ -f "$PREFIX/bin/pypy" ]]; then
      rm -rf $BUILD_PREFIX/venv/lib/pypy$PY_VER
      mkdir -p $BUILD_PREFIX/venv/lib/python$PY_VER
      ln -s $BUILD_PREFIX/venv/lib/python$PY_VER $BUILD_PREFIX/venv/lib/pypy$PY_VER
    fi
    echo "4)"
    rm -rf $BUILD_PREFIX/venv/cross
    if [[ -d "$PREFIX/lib/python$PY_VER/site-packages/" ]]; then
      find $PREFIX/lib/python$PY_VER/site-packages/ -name "*.so" -exec rm {} \;
      find $PREFIX/lib/python$PY_VER/site-packages/ -name "*.dylib" -exec rm {} \;
      rsync -a -I $PREFIX/lib/python$PY_VER/site-packages/ $BUILD_PREFIX/lib/python$PY_VER/site-packages/
      rm -rf $PREFIX/lib/python$PY_VER/site-packages
      mkdir $PREFIX/lib/python$PY_VER/site-packages
    fi
    echo "5)" $PYTHON
    rm -rf $BUILD_PREFIX/venv/lib/python$PY_VER/site-packages
    ln -s $BUILD_PREFIX/lib/python$PY_VER/site-packages $BUILD_PREFIX/venv/lib/python$PY_VER/site-packages
    sed -i.bak "s@$BUILD_PREFIX/venv/lib@$BUILD_PREFIX/venv/lib', '$BUILD_PREFIX/venv/lib/python$PY_VER/site-packages@g" $OLD_PYTHON
    rm -f $PYTHON.bak

    if [[ "${PYTHONPATH}" != "" ]]; then
      _CONDA_BACKUP_PYTHONPATH=${PYTHONPATH}
    fi
  fi
  unset sysconfigdata_fn
  export PYTHONPATH=$BUILD_PREFIX/venv/lib/python$PY_VER/site-packages
  echo "Finished setting up cross-python"
fi
