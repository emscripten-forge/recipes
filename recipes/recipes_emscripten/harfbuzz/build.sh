#!/bin/bash

set -ex

# Unicode callbacks (you want at least one):
# 	Builtin			true
# 	Glib:			${have_glib}
# 	ICU:			${have_icu}

# Font callbacks (the more the merrier):
# 	FreeType:		${have_freetype}

# Tools used for command-line utilities:
# 	Cairo:			${have_cairo}
# 	Chafa:			${have_chafa}

# Additional shapers:
# 	Graphite2:		${have_graphite2}

# Platform shapers (not normally needed):
# 	CoreText:		${have_coretext}
# 	DirectWrite:		${have_directwrite}
# 	GDI:			${have_gdi}
# 	Uniscribe:		${have_uniscribe}
# 	WebAssembly:		${have_wasm}

# Other features:
# 	Documentation:		${enable_gtk_doc}
# 	GObject bindings:	${have_gobject}
# 	Introspection:		${have_introspection}

meson_config_args=(
    -Dglib=enabled
    -Dicu=enabled
    -Dfreetype=enabled
    -Dcairo=disabled
    -Dchafa=disabled
    -Dgraphite=enabled
    -Dintrospection=disabled
    -Dtests=disabled
    -Dutilities=disabled
)




# if [[ "$CONDA_BUILD_CROSS_COMPILATION" == "1" ]]; then
#   unset _CONDA_PYTHON_SYSCONFIGDATA_NAME
#   (
#     mkdir -p native-build

#     export CC=$CC_FOR_BUILD
#     export CXX=$CXX_FOR_BUILD
#     export OBJC=$OBJC_FOR_BUILD
#     export AR="$($CC_FOR_BUILD -print-prog-name=ar)"
#     export NM="$($CC_FOR_BUILD -print-prog-name=nm)"
#     export LDFLAGS=${LDFLAGS//$PREFIX/$BUILD_PREFIX}
#     export PKG_CONFIG_PATH=${BUILD_PREFIX}/lib/pkgconfig

#     # Unset them as we're ok with builds that are either slow or non-portable
#     unset CFLAGS
#     unset CPPFLAGS
#     export host_alias=$build_alias

#     meson setup native-build \
#         "${meson_config_args[@]}" \
#         --buildtype=release \
#         --prefix=$BUILD_PREFIX \
#         -Dlibdir=lib \
#         --wrap-mode=nofallback

#     # This script would generate the functions.txt and dump.xml and save them
#     # This is loaded in the native build. We assume that the functions exported
#     # by the package are the same for the native and cross builds
#     export GI_CROSS_LAUNCHER=$BUILD_PREFIX/libexec/gi-cross-launcher-save.sh
#     ninja -v -C native-build -j ${CPU_COUNT}
#     ninja -C native-build install -j ${CPU_COUNT}
#   )
#   export GI_CROSS_LAUNCHER=$BUILD_PREFIX/libexec/gi-cross-launcher-load.sh
# fi

meson setup builddir \
    ${MESON_ARGS} \
    "${meson_config_args[@]}" \
    --buildtype=release \
    --default-library=static \
    --prefix=$PREFIX \
    -Dlibdir=lib \
    --wrap-mode=nofallback \
    --cross-file=$RECIPE_DIR/emscripten.meson.cross
ninja -v -C builddir -j ${CPU_COUNT}
ninja -C builddir install -j ${CPU_COUNT}


# pushd $PREFIX
# # rm -rf share/gtk-doc
# popd