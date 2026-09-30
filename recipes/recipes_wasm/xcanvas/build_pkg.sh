mkdir build
cd build


if [ "$PKG_NAME" = "xcanvas-static" ]; then
  BUILD_SHARED_LIBS=OFF
  BUILD_STATIC_LIBS=ON
elif [ "$PKG_NAME" = "xcanvas" ]; then
  BUILD_SHARED_LIBS=ON
  BUILD_STATIC_LIBS=OFF
else
    # error: unknown package name
    echo "Unknown package name: $PKG_NAME"
    exit 1
fi


# Configure step
emcmake cmake  $CMAKE_ARGS \
  -DCMAKE_BUILD_TYPE=Release     \
  -DCMAKE_PREFIX_PATH=$PREFIX   \
  -DCMAKE_INSTALL_PREFIX=$PREFIX \
  -DXCANVAS_BUILD_SHARED_LIBS=$BUILD_SHARED_LIBS \
  -DXCANVAS_BUILD_STATIC_LIBS=$BUILD_STATIC_LIBS \
  -DCMAKE_FIND_ROOT_PATH=$PREFIX \
  ..


# Install step
emmake make -j2 install
