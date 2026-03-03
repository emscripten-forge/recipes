#!/bin/bash
## Start of bash preamble
if [ -z ${CONDA_BUILD+x} ]; then
    source "/Users/thorstenbeier/src/recipes/output/bld/rattler-build_octave-image_1772446917/work/build_env.sh"
fi
## End of preamble

IMAGE_DIR=$(pwd)/image
SOURCE_DIR=$(pwd)/image/src
OCTAVE_VER="10.3.0"

PKG=image
VER=2.18.1


# atm we install the *oct files in the same dir
# as the *.m files, without any arch-specific subdir
M_FILE_INSTALL_DIR=$PREFIX/share/octave/packages/${PKG}-${VER}/
OCT_INSTALL_DIR=$M_FILE_INSTALL_DIR/



# copy DESCRIPTION,COPYING,INDEX into the M_FILE_INSTALL_DIR/packinfo
mkdir -p "${M_FILE_INSTALL_DIR}/packinfo"
cp "$IMAGE_DIR"/{DESCRIPTION,COPYING,INDEX} "${M_FILE_INSTALL_DIR}/packinfo/"

# copy everything from $THIS_DIR/image/into the M_FILE_INSTALL_DIR
cp -r "$IMAGE_DIR"/inst/* "${M_FILE_INSTALL_DIR}/"




# compile *.o object files first
for f in "$SOURCE_DIR"/*.cc; do
    base=$(basename "$f" .cc)
    # Check if there's a corresponding .h file
    if [ -f "$SOURCE_DIR/${base}.h" ]; then
        echo "Compiling object file for $base"
        emcc -c "$f" -o "$SOURCE_DIR/${base}.o" \
            -fPIC -O2 \
            -I "$PREFIX/include/octave-${OCTAVE_VER}"
    fi
done

# compile connectivity dependent .oct files
for oct in conndef.oct bwlabeln.oct imreconstruct.oct bwconncomp.oct watershed.oct; do
    base=$(basename "$oct" .oct)
    if [ -f "$SOURCE_DIR/${base}.cc" ]; then
        echo "Compiling $base (connectivity dependent)"
        emcc "$SOURCE_DIR/${base}.cc" "$SOURCE_DIR/connectivity.o" \
            -o "${OCT_INSTALL_DIR}/${oct}" \
            -sSIDE_MODULE=1 -sEXPORT_ALL=1 -sLINKABLE=1 \
            -fPIC -O2 \
            -I "$PREFIX/include/octave-${OCTAVE_VER}"
    fi
done

# compile strel dependent .oct files
for oct in imerode.oct; do
    base=$(basename "$oct" .oct)
    if [ -f "$SOURCE_DIR/${base}.cc" ]; then
        echo "Compiling $base (strel dependent)"
        emcc "$SOURCE_DIR/${base}.cc" "$SOURCE_DIR/strel.o" \
            -o "${OCT_INSTALL_DIR}/${oct}" \
            -sSIDE_MODULE=1 -sEXPORT_ALL=1 -sLINKABLE=1 \
            -fPIC -O2 \
            -I "$PREFIX/include/octave-${OCTAVE_VER}"
    fi
done

# compile remaining .oct files with no dependencies
for oct in __spatial_filtering__.oct __bilateral__.oct __eps__.oct \
           __custom_gaussian_smoothing__.oct __boundary__.oct \
           __graycomatrix__.oct __text_to_pixels__.oct bwfill.oct \
           rotate_scale.oct hough_line.oct graycomatrix_old.oct bwdist.oct \
           intlut.oct nonmax_suppress.oct; do
    base=$(basename "$oct" .oct)
    if [ -f "$SOURCE_DIR/${base}.cc" ]; then
        echo "Compiling $base"
        emcc "$SOURCE_DIR/${base}.cc" -o "${OCT_INSTALL_DIR}/${oct}" \
            -sSIDE_MODULE=1 -sEXPORT_ALL=1 -sLINKABLE=1 \
            -fPIC -O2 \
            -I "$PREFIX/include/octave-${OCTAVE_VER}"
    fi
done

# run "build_pkg_add.sh" to generate the PKG_ADD and PKG_DEL files based on the generated .oct files
bash "${RECIPE_DIR}/build_pkg_add.sh" "${OCT_INSTALL_DIR}" 
