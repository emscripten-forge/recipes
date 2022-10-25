export CXXFLAGS="${CXXFLAGS} -fexceptions -fPIC -DBOOST_SP_DISABLE_THREADS=1 -02"
export LDFLAGS="${LDFLAGS} -fexceptions"

# _h_env_placehold_placehold_...
export HOST_DIR=${PREFIX} 
export INSTALL_DIR=${HOST_DIR}
export PYTHON_INCLUDE=${HOST_DIR}/include/python${PY_VER}/

echo "set_property(GLOBAL PROPERTY TARGET_SUPPORTS_SHARED_LIBS FALSE)" > ForceStaticLib.cmake
emcmake cmake -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} -DBUILD_PYTHON=ON \
-DCMAKE_PROJECT_INCLUDE=ForceStaticLib.cmake \
-DNUMPY_INCLUDE_DIR=$HOST_DIR/lib/python$PY_VER/site-packages/numpy/core/include/ \
-DPYTHON_INCLUDE_DIR=$PYTHON_INCLUDE -DPYTHON_EXECUTABLE=python$PY_VER \
-DCMAKE_CXX_FLAGS="-fPIC -fexceptions -DBOOST_AP_DISABLE_THREADS=1 -O2 -DBOOST_BIND_GLOBAL_PLACEHOLDERS=1 -Wno-enum-constexpr-conversion" \
-DBOOST_INCLUDEDIR=$HOST_DIR/include -DBOOST_LIBRARYDIR=$HOST_DIR/lib \
-DBoost_DATE_TIME_LIBRARY_RELEASE=$HOST_DIR/lib/libboost_date_time.bc \
-DBoost_DATE_TIME_LIBRARY_DEBUG=$HOST_DIR/lib/libboost_date_time.bc \
-DBoost_FILESYSTEM_LIBRARY_RELEASE=$HOST_DIR/lib/libboost_filesystem.bc \
-DBoost_FILESYSTEM_LIBRARY_DEBUG=$HOST_DIR/lib/libboost_filesystem.bc \
-DBoost_SYSTEM_LIBRARY_RELEASE=$HOST_DIR/lib/libboost_system.bc \
-DBoost_SYSTEM_LIBRARY_DEBUG=$HOST_DIR/lib/libboost_system.bc \
-DBoost_REGEX_LIBRARY_RELEASE=$HOST_DIR/lib/libboost_regex.bc \
-DBoost_SYSTEM_LIBRARY_DEBUG=$HOST_DIR/lib/libboost_regex.bc \
-DBoost_CHRONO_LIBRARY_RELEASE=$HOST_DIR/lib/libboost_chrono.bc \
-DBoost_CHRONO_LIBRARY_DEBUG=$HOST_DIR/lib/libboost_crono.bc \
-DBoost_RANDOM_LIBRARY_RELEASE=$HOST_DIR/lib/libboost_random.bc \
-DBoost_RANDOM_LIBRARY_DEBUG=$HOST_DIR/lib/libboost_random.bc \
-DBoost_PROGRAM_OPTIONS_LIBRARY_RELEASE=$HOST_DIR/lib/libboost_program_options.bc \
-DBoost_PROGRAM_OPTIONS_LIBRARY_DEBUG=$HOST_DIR/lib/libboost_program_options.bc \
-DUSE_PREGENERATED_SOURCE=ON \
    .
emmake make -j ${CPU_COUNT:-3}
emcc ${SIDE_MODULE_LDFLAGS} -fexceptions out/lib/libRobotRaconteurCore.a \
    out/Python/RobotRaconteur/_RobotRaconteurPython.a \
    $HOST_DIR/lib/libboost_chrono.bc \
    $HOST_DIR/lib/libboost_date_time.bc \
    $HOST_DIR/lib/libboost_filesystem.bc \
    $HOST_DIR/lib/libboost_program_options.bc \
    $HOST_DIR/lib/libboost_random.bc \
    $HOST_DIR/lib/libboost_regex.bc \
    $HOST_DIR/lib/libboost_system.bc \
    -o out/Python/RobotRaconteur/_RobotRaconteurPython.so
    