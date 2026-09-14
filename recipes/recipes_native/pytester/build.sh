ls 

echo "Creating site-packages directory"
echo "Python version: $PY_VER"
mkdir -p $PREFIX/lib/python$PY_VER/site-packages

cp -r pytester $PREFIX/lib/python$PY_VER/site-packages

cp -r bin $PREFIX