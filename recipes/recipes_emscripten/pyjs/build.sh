mkdir build
cd build


export CMAKE_PREFIX_PATH=$PREFIX 
export CMAKE_SYSTEM_PREFIX_PATH=$PREFIX 


if [[ $FEATURE_ENV_NODE == 1 ]]; then
    echo "FEATURE_ENV_NODE ENABLED"
else
    echo "FEATURE_ENV_NODE DISABLED"
fi

# Configure step
cmake ${CMAKE_ARGS} ..                          \
    -GNinja                                     \
    -DCMAKE_PROJECT_INCLUDE=overwriteProp.cmake \
    -DCMAKE_PREFIX_PATH=$PREFIX                 \
    -DCMAKE_INSTALL_PREFIX=$PREFIX              \
    -DCMAKE_BUILD_TYPE=Release      

# -DENV_NODE=$FEATURE_ENV_NODE                \

# Build step
ninja install
