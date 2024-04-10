#!/bin/bash
# Get an updated config.sub and config.guess
set -ex

export

export r_cv_header_zlib_h=yes
export r_cv_have_bzlib=yes
export r_cv_have_lzma=yes
export r_cv_have_pcre2utf=yes
export r_cv_have_pcre832=yes
export r_cv_have_curl722=yes
export r_cv_have_curl728=yes
export r_cv_have_curl_https=yes
export r_cv_size_max=yes
export r_cv_prog_fc_char_len_t=size_t
export r_cv_kern_usrstack=yes
export ac_cv_lib_icucore_ucol_open=yes
export ac_cv_func_mmap_fixed_mapped=yes
export r_cv_working_mktime=yes
export r_cv_func_ctanh_works=yes
export r_cv_prog_fc_cc_compat_complex=yes
export r_cv_zdotu_is_usable=yes


export CFLAGS=""
export CXXFLAGS=""
export CC=$CC_FOR_BUILD
export CXX=$CXX_FOR_BUILD
export AR=$($CC_FOR_BUILD -print-prog-name=ar)
export F77=${F77//$HOST/$BUILD}
export F90=${F90//$HOST/$BUILD}
export F95=${F95//$HOST/$BUILD}
export FC=${FC//$HOST/$BUILD}
export GFORTRAN=${FC//$HOST/$BUILD}
export LD=${LD//$HOST/$BUILD}
export FFLAGS=${FFLAGS//$PREFIX/$BUILD_PREFIX}
export FORTRANFLAGS=${FORTRANFLAGS//$PREFIX/$BUILD_PREFIX}
# Filter out -march=.* from F*FLAGS
re='\-march\=[^[:space:]]*(.*)'
if [[ "${FFLAGS}" =~ $re ]]; then
    export FFLAGS="${BASH_REMATCH[1]}${BASH_REMATCH[2]}"
fi
re='\-march\=[^[:space:]]*(.*)'
if [[ "${FORTRANFLAGS}" =~ $re ]]; then
    export FORTRANFLAGS="${BASH_REMATCH[1]}${BASH_REMATCH[2]}"
fi
# Filter out -mtune=.* from F*FLAGS
re='\-mtune\=[^[:space:]]*(.*)'
if [[ "${FFLAGS}" =~ $re ]]; then
    export FFLAGS="${BASH_REMATCH[1]}${BASH_REMATCH[2]}"
fi
re='\-mtune\=[^[:space:]]*(.*)'
if [[ "${FORTRANFLAGS}" =~ $re ]]; then
    export FORTRANFLAGS="${BASH_REMATCH[1]}${BASH_REMATCH[2]}"
fi
export LDFLAGS=${LDFLAGS//$PREFIX/$BUILD_PREFIX}
export CPPFLAGS=${CPPFLAGS//$PREFIX/$BUILD_PREFIX}
export NM=$($CC_FOR_BUILD -print-prog-name=nm)
export PKG_CONFIG_PATH=${BUILD_PREFIX}/lib/pkgconfig
export CONDA_BUILD_CROSS_COMPILATION=0
export HOST=$BUILD
export PREFIX=$BUILD_PREFIX
export IS_MINIMAL_R_BUILD=1



# Filter out -std=.* from CXXFLAGS as it disrupts checks for C++ language levels.
re='(.*[[:space:]])\-std\=[^[:space:]]*(.*)'
if [[ "${CXXFLAGS}" =~ $re ]]; then
  export CXXFLAGS="${BASH_REMATCH[1]}${BASH_REMATCH[2]}"
fi

re2='(.*[[:space:]])\-I.*[^[:space:]]*(.*)'
if [[ "${CPPFLAGS}" =~ $re2 ]]; then
  export CPPFLAGS="${BASH_REMATCH[1]}${BASH_REMATCH[2]}"
fi
# if [[ "${CFLAGS}" =~ $re2 ]]; then
#   export CFLAGS="${BASH_REMATCH[1]}${BASH_REMATCH[2]}"
# fi
re3='(.*[[:space:]])\-L.*[^[:space:]]*(.*)'
if [[ "${CPPFLAGS}" =~ $re3 ]]; then
  export CPPFLAGS="${BASH_REMATCH[1]}${BASH_REMATCH[2]}"
fi
# if [[ "${CFLAGS}" =~ $re3 ]]; then
#   export CFLAGS="${BASH_REMATCH[1]}${BASH_REMATCH[2]}"
# fi
# if [[ "${LDFLAGS}" =~ $re3 ]]; then
#   export LDFLAGS="${BASH_REMATCH[1]}${BASH_REMATCH[2]}"
# fi

# Without this, dependency scanning fails (but with it CDT libuuid / Xt fails to link
# which we hack around with config.site)
export CPPFLAGS="${CPPFLAGS} -I$PREFIX/include"

export TCL_CONFIG=${PREFIX}/lib/tclConfig.sh
export TK_CONFIG=${PREFIX}/lib/tkConfig.sh
export TCL_LIBRARY=${PREFIX}/lib/tcl8.6
export TK_LIBRARY=${PREFIX}/lib/tk8.6
# BUILD_PREFIX does not get considered for prefix replacement.
[[ -n ${AR} ]] && export AR=$(basename ${AR})
[[ -n ${CC} ]] && export CC=$(basename ${CC})
[[ -n ${GCC} ]] && export GCC=$(basename ${GCC})
[[ -n ${CXX} ]] && export CXX=$(basename ${CXX})
[[ -n ${F77} ]] && export F77=$(basename ${F77})
[[ -n ${FC} ]] && export FC=$(basename ${FC})
[[ -n ${LD} ]] && export LD=$(basename ${LD})
[[ -n ${RANLIB} ]] && export RANLIB=$(basename ${RANLIB})
[[ -n ${STRIP} ]] && export STRIP=$(basename ${STRIP})
export OBJC=${CC}
INSTALL_NAME_TOOL=${INSTALL_NAME_TOOL:-install_name_tool}


# If lib/R/etc/javaconf ends up with anything other than ~autodetect~
# for any value (except JAVA_HOME) then 'R CMD javareconf' will never
# change it, so we prevent configure from finding Java.  post-install
# and activate scripts now call 'R CMD javareconf'.
unset JAVA_HOME

export CPPFLAGS="${CPPFLAGS} -Wl,-rpath-link,${PREFIX}/lib"

# Make sure curl is found from PREFIX instead of BUILD_PREFIX
rm -f "${BUILD_PREFIX}/bin/curl-config"

mkdir -p ${PREFIX}/lib

echo "ac_cv_lib_Xt_XtToolkitInitialize=yes" > config.site
export CONFIG_SITE=${PWD}/config.site

CONFIGURE_ARGS="--with-x --with-blas=-lblas --with-lapack=-llapack"

./configure --prefix=${PREFIX}               \
            --host=${HOST}                   \
            --build=${BUILD}                 \
            --enable-shared                  \
            --enable-R-shlib                 \
            --disable-prebuilt-html          \
            --enable-memory-profiling        \
            --with-tk-config=${TK_CONFIG}    \
            --with-tcl-config=${TCL_CONFIG}  \
            --with-pic                       \
            --with-cairo                     \
            --with-readline                  \
            --with-recommended-packages=no   \
            --without-libintl-prefix         \
    ${CONFIGURE_ARGS}                \
    LIBnn=lib || (cat config.log; exit 1)

if cat src/include/config.h | grep "undef HAVE_PANGOCAIRO"; then
    echo "Did not find pangocairo, refusing to continue"
    cat config.log | grep pango
    exit 1
fi

make clean
make -j${CPU_COUNT} ${VERBOSE_AT}
# echo "Running make check-all, this will take some time ..."
# make check-all -j1 V=1 > $(uname)-make-check.log 2>&1 || make check-all -j1 V=1 > $(uname)-make-check.2.log 2>&1

make install

# fail if build did not use external BLAS/LAPACK
if [[ -e ${PREFIX}/lib/R/lib/libRblas.so || -e ${PREFIX}/lib/R/lib/libRlapack.so ]]; then
    echo "Test failed: Detected generic R BLAS/LAPACK"
    exit 1
fi

# Prevent C and C++ extensions from linking to libgfortran.
sed -i -r 's|(^LDFLAGS = .*)-lgfortran|\1|g' ${PREFIX}/lib/R/etc/Makeconf

pushd ${PREFIX}/lib/R/etc
    # See: https://github.com/conda/conda/issues/6701
    chmod g+w Makeconf ldpaths
popd

# Remove hard coded paths to these commands in the build machine
sed -i.bak 's/PAGER=.*/PAGER=${PAGER-less}/g' ${PREFIX}/lib/R/etc/Renviron
sed -i.bak 's/TAR=.*/TAR=${TAR-tar}/g' ${PREFIX}/lib/R/etc/Renviron
sed -i.bak 's/R_GZIPCMD=.*/R_GZIPCMD=${R_GZIPCMD-gzip}/g' ${PREFIX}/lib/R/etc/Renviron
rm ${PREFIX}/lib/R/etc/Renviron.bak




pushd $BUILD_PREFIX/lib/R
for f in $(find . -type f); do
    if [[ ! -f $PREFIX/lib/R/$f ]]; then
        mkdir -p $PREFIX/lib/R/$(dirname $f)
        cp $f $PREFIX/lib/R/$f
    fi
done

if [[ -f $PREFIX/lib/R/etc/Makeconf ]]; then
    mv $PREFIX/lib/R/etc/Makeconf .
    echo "R_HOME=$PREFIX/lib/R"   > $PREFIX/lib/R/etc/Makeconf
    cat Makeconf                 >> $PREFIX/lib/R/etc/Makeconf
fi
