#!/bin/bash

autoreconf -vfi

export LDFLAGS="${LDFLAGS} -L${PREFIX}/lib"
export CFLAGS="${CFLAGS} -I${PREFIX}/include"

# if [[ $(uname) == Darwin ]]; then
#   export LDFLAGS="${LDFLAGS} -Wl,-rpath,${PREFIX}/lib"
# fi

emconfigure ./configure --prefix=${PREFIX}  \
            --enable-static     \
            --disable-shared

make -j${CPU_COUNT} ${VERBOSE_AT}

if [[ "${CONDA_BUILD_CROSS_COMPILATION:-0}" != "1" ]]; then
    make check
fi

make install

# if [[ $(uname) == Darwin ]]; then
#     cp ${RECIPE_DIR}/patchbinary.py ${PREFIX}/
#     echo ${PREFIX} > ${PREFIX}/build_prefix.a
# fi

# Make sure ENV variables and set
# ACTIVATE_DIR=$PREFIX/etc/conda/activate.d
# DEACTIVATE_DIR=$PREFIX/etc/conda/deactivate.d
# mkdir -p $ACTIVATE_DIR
# mkdir -p $DEACTIVATE_DIR

# for EXT in sh csh fish
# do
#   cp $RECIPE_DIR/scripts/activate.$EXT $ACTIVATE_DIR/udunits2-activate.$EXT
#   cp $RECIPE_DIR/scripts/deactivate.$EXT $DEACTIVATE_DIR/udunits2-deactivate.$EXT
# done

# We can remove this when we start using the new conda-build.
# find $PREFIX -name '*.la' -delete