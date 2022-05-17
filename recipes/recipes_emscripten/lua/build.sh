#!/usr/bin/env bash



if [[ $target_platform == "emscripten-32" ]]; then
    echo "EMSCRIPTEN!"

    mkdir build
    cd build


    # Configure step
    cmake ${CMAKE_ARGS} ..             \
        -GNinja                        \
        -DCMAKE_BUILD_TYPE=Release     \
        -DCMAKE_PREFIX_PATH=$PREFIX    \
        -DCMAKE_INSTALL_PREFIX=$PREFIX \
        -DLUA_USER_DEFAULT_PATH="bla bla"\
        -DCMAKE_C_FLAGS="-DLUA_USER_DEFAULT_PATH='\"$PREFIX/\"'" \

    # Build step
    ninja install

else
    # export USE_WASM=OFF

    sed -i "s#@LUA_PREFIX@#${PREFIX}#g" src/Makefile

    LUA_CFLAGS="-DLUA_USER_DEFAULT_PATH='\"$PREFIX/\"' -DLUA_USE_POSIX"

    echo "THEUNAME" `uname`

    if [ `uname` == Linux ]; then
        make INSTALL_TOP=$PREFIX \
             CC="${CC}" \
             MYCFLAGS="${CLFAGS} -fPIC -I$PREFIX/include -L$PREFIX/lib  -DLUA_USE_DLOPEN -DLUA_USE_LINUX -DLUA_USER_DEFAULT_PATH='\"$PREFIX/\"'" \
             MYLDFLAGS="$LDFLAGS -L$PREFIX/lib -Wl,-rpath=$PREFIX/lib" \
             linux-readline
    elif [ `uname` == Darwin ]; then
        make \
        CC="${CC}" \
        INSTALL_TOP="${PREFIX}" \
        MYCFLAGS="${CLFAGS} -fPIC -I$PREFIX/include -L$PREFIX/lib ${LUA_CFLAGS}" \
        MYLDFLAGS="-L$PREFIX/lib -Wl,-rpath,$PREFIX/lib" \
        LUA_SO="liblua${SHLIB_EXT}" \
        macosx
    else
        make \
            CC="${CC}" \
            INSTALL_TOP="${PREFIX}" \
            MYCFLAGS="${CLFAGS} -fPIC -I$PREFIX/include -L$PREFIX/lib ${LUA_CFLAGS}" \
            MYLDFLAGS="-L$PREFIX/lib -Wl,-rpath,$PREFIX/lib" \
            LUA_SO="liblua${SHLIB_EXT}" \
            generic
    fi

    if [[ "$CONDA_BUILD_CROSS_COMPILATION" != "1" ]]; then
        make \
            CC="${CC}" \
            LUA_SO="liblua${SHLIB_EXT}" \
            test
    fi

    # If that static library is ever needed, "liblua.a" needs to be added to TO_LIB
    if [ "$(uname)" == "Darwin" ]; then
        TO_LIB="liblua${SHLIB_EXT} liblua.${PKG_VERSION%.*}${SHLIB_EXT} liblua.${PKG_VERSION}${SHLIB_EXT}"
    else
        TO_LIB="liblua${SHLIB_EXT} liblua${SHLIB_EXT}.${PKG_VERSION%.*} liblua${SHLIB_EXT}.${PKG_VERSION}"
    fi

    make \
        INSTALL_TOP="$PREFIX" \
        LUA_SO="liblua${SHLIB_EXT}" \
        TO_LIB="${TO_LIB}" \
        install

    # Create the pkg-config file
    mkdir -p "${PREFIX}/lib/pkgconfig"
    (sed -e "s@PKG_VERSION@${PKG_VERSION}@g" -e "s@CONDA_PREFIX@${PREFIX}@g" | \
     sed -E "s@^(V=.+)\.[0-9]+@\1@g" \
     > "${PREFIX}/lib/pkgconfig/lua.pc") << "EOF"
    V=PKG_VERSION
    R=PKG_VERSION

    prefix=CONDA_PREFIX
    INSTALL_BIN=${prefix}/bin
    INSTALL_INC=${prefix}/include
    INSTALL_LIB=${prefix}/lib
    INSTALL_MAN=${prefix}/share/man/man1
    INSTALL_LMOD=${prefix}/share/lua/${V}
    INSTALL_CMOD=${prefix}/lib/lua/${V}
    exec_prefix=${prefix}
    libdir=${exec_prefix}/lib
    includedir=${prefix}/include

    Name: Lua
    Description: An Extensible Extension Language
    Version: ${R}
    Requires:
    Libs: -L${libdir} -llua -lm -ldl
    Cflags: -I${includedir}
EOF

fi
