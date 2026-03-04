#!/bin/bash
IMAGE_DIR=$(pwd)/image
SOURCE_DIR=$(pwd)/image/src

export OCTAVE_VER="10.3.0"

# atm we install the *oct files in the same dir
# as the *.m files, without any arch-specific subdir
M_FILE_INSTALL_DIR=$PREFIX/share/octave/packages/image-${PKG_VERSION}
OCT_INSTALL_DIR=$M_FILE_INSTALL_DIR/


# copy DESCRIPTION,COPYING,INDEX into the M_FILE_INSTALL_DIR/packinfo
mkdir -p "${M_FILE_INSTALL_DIR}/packinfo"
cp "$IMAGE_DIR"/{DESCRIPTION,COPYING,INDEX} "${M_FILE_INSTALL_DIR}/packinfo/"

# copy everything from $THIS_DIR/image/into the M_FILE_INSTALL_DIR
cp -r "$IMAGE_DIR"/inst/* "${M_FILE_INSTALL_DIR}/"



cd "$SOURCE_DIR"
chmod +x $RECIPE_DIR/fake_mkoctfile.sh
make -f Makefile.in MKOCTFILE="$RECIPE_DIR/fake_mkoctfile.sh" 

# copy the generated .oct files into the OCT_INSTALL_DIR
mkdir -p "$OCT_INSTALL_DIR"
cp *.oct "$OCT_INSTALL_DIR/"

# run "build_pkg_add.sh" to generate the PKG_ADD and PKG_DEL files based on the generated .oct files
bash "${RECIPE_DIR}/build_pkg_add.sh" "${OCT_INSTALL_DIR}" 
