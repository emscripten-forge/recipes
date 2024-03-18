
mkdir build
cd build


# sdl2
if true; then
    $EMSCRIPTEN_FORGE_EMSDK_DIR/upstream/emscripten/embuilder build sdl2 --pic
fi

# Configure step
emcmake cmake  ${CMAKE_ARGS} .. \
    -GNinja \
    -DBUILD_SHARED_LIBS:BOOL=OFF \
    -DCMAKE_BUILD_TYPE:STRING=Release \
    -DVTK_ENABLE_LOGGING:BOOL=OFF \
    -DVTK_ENABLE_WRAPPING:BOOL=OFF \
    -DVTK_ENABLE_WEBGPU:BOOL=OFF \
    -DVTK_MODULE_ENABLE_VTK_hdf5:STRING=NO \
    -DVTK_MODULE_ENABLE_VTK_RenderingContextOpenGL2:STRING=DONT_WANT \
    -DVTK_MODULE_ENABLE_VTK_RenderingLICOpenGL2:STRING=DONT_WANT \
    -DVTK_MODULE_ENABLE_VTK_RenderingCellGrid:STRING=NO \
    -DVTK_MODULE_ENABLE_VTK_sqlite:STRING=NO \
    -DCMAKE_INSTALL_PREFIX=$PREFIX  

# Build step
ninja install
