$PYTHON -m pip install . $PIP_ARGS


# if PY_VERSION is not,set to 3.13
if [ -z "$PY_VERSION" ]; then
    export PY_VERSION=3.13
fi


cp $RECIPE_DIR/FindPythonLibsNew.cmake $PREFIX/lib/python$PY_VERSION/site-packages/pybind11/share/cmake/pybind11/FindPythonLibsNew.cmake