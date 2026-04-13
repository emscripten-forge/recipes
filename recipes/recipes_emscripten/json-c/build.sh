#!/bin/bash
# Get an updated config.sub and config.guess
# cp $BUILD_PREFIX/share/gnuconfig/config.* .

# https://github.com/json-c/json-c/issues/406
export CPPFLAGS="${CPPFLAGS/-DNDEBUG/}"



# # Enable or disable features. By default, all features are turned off.
# option(DISABLE_BSYMBOLIC              "Avoid linking with -Bsymbolic-function."               OFF)
# option(DISABLE_THREAD_LOCAL_STORAGE   "Disable using Thread-Local Storage (HAVE___THREAD)."   OFF)
# option(DISABLE_WERROR                 "Avoid treating compiler warnings as fatal errors."     OFF)
# option(ENABLE_RDRAND                  "Enable RDRAND Hardware RNG Hash Seed."                 OFF)
# option(ENABLE_THREADING               "Enable partial threading support."                     OFF)
# option(OVERRIDE_GET_RANDOM_SEED       "Override json_c_get_random_seed() with custom code."   OFF)
# option(DISABLE_EXTRA_LIBS             "Avoid linking against extra libraries, such as libbsd." OFF)
# option(DISABLE_JSON_POINTER           "Disable JSON pointer (RFC6901) and JSON patch support." OFF)
# option(DISABLE_JSON_PATCH             "Disable JSON patch (RFC6902) support."                 OFF)
# option(NEWLOCALE_NEEDS_FREELOCALE     "Work around newlocale bugs in old FreeBSD and macOS by calling freelocale"  OFF)
# option(BUILD_APPS                     "Default to building apps" ON)




mkdir build
cd build
emcmake cmake $CMAKE_ARGS \
    -DCMAKE_PROJECT_INCLUDE=${RECIPE_DIR}/overwriteProp.cmake \
    -DISABLE_BSYMBOLIC=ON \
    -DISABLE_THREAD_LOCAL_STORAGE=ON \
    -DISABLE_WERROR=ON \
    -DENABLE_RDRAND=OFF \
    -DENABLE_THREADING=OFF \
    -DOVERRIDE_GET_RANDOM_SEED=OFF \
    -DDISABLE_EXTRA_LIBS=ON \
    -DBUILD_APPS=OFF \
    -DBUILD_TESTING=OFF \
    .. 

emmake make ${VERBOSE_AT}
emmake make install

# We can remove this when we start using the new conda-build.
find $PREFIX -name '*.la' -delete