
# make some directories
mkdir -p $PREFIX/include
mkdir -p $PREFIX/lib
mkdir -p $PREFIX/bin
mkdir -p $PREFIX/etc/conda
mkdir -p cpython/build


# overwrite $RECIPEDIR/pyodide_env.sh with am empty file
# since we do not want to use the pyodide_env.sh from pyodide
echo "" > $RECIPE_DIR/pyodide_env.sh


# create a symlink from $BUILD_PREFIX/emsdk directory to this dir emsdk.
# This allows us to overwrite the emsdk from pyodide
rm -rf emsdk
mkdir -p emsdk
cd emsdk
ln -s $CONDA_EMSDK_DIR emsdk
cd ..


mkdir -p cpython/build/Python-3.11.3/Include

#replace "all: $(INSTALL)/lib/$(LIB) $(INSTALL)/lib/libffi.a" with "$(INSTALL)/lib/libffi.a"

sed -i 's/all: $(INSTALL)\/lib\/$(LIB) $(INSTALL)\/lib\/libffi.a/all: $(INSTALL)\/lib\/libffi.a/g' cpython/Makefile

#################################################################
#  THE ACTUAL BUILD
make -C cpython
################################################################


# install libffi
cp -r cpython/build/libffi/target/ $PREFIX/