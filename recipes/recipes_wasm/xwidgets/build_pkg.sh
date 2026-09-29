
mkdir build
cd build

# check if PKG_NAME is xwidgets or xwidgets-static
if [ "$PKG_NAME" = "xwidgets-static" ]; then
  BUILD_SHARED_LIBS=OFF
  BUILD_STATIC_LIBS=ON
elif [ "$PKG_NAME" = "xwidgets" ]; then
  BUILD_SHARED_LIBS=ON
  BUILD_STATIC_LIBS=OFF
else
    # error: unknown package name
    echo "Unknown package name: $PKG_NAME"
    exit 1
fi

# Configure step
emcmake cmake   $CMAKE_ARGS \
  -DCMAKE_BUILD_TYPE=Release     \
  -DCMAKE_PREFIX_PATH=$PREFIX   \
  -DCMAKE_INSTALL_PREFIX=$PREFIX \
  -DXWIDGETS_BUILD_SHARED_LIBS=$BUILD_SHARED_LIBS \
  -DXWIDGETS_BUILD_STATIC_LIBS=$BUILD_STATIC_LIBS \
  -DCMAKE_FIND_ROOT_PATH=$PREFIX \
  ..



emmake make -j$(getconf _NPROCESSORS_ONLN) install


