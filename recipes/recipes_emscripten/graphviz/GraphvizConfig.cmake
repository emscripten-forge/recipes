include(CMakeFindDependencyMacro)

get_filename_component(_graphviz_prefix "${CMAKE_CURRENT_LIST_FILE}" PATH)
get_filename_component(_graphviz_prefix "${_graphviz_prefix}" PATH)
get_filename_component(_graphviz_prefix "${_graphviz_prefix}" PATH)
get_filename_component(_graphviz_prefix "${_graphviz_prefix}" PATH)

set(_graphviz_include_dir "${_graphviz_prefix}/include")
set(_graphviz_lib_dir "${_graphviz_prefix}/lib")

if(EXISTS "${_graphviz_lib_dir}/libz.a")
    set(_graphviz_zlib "${_graphviz_lib_dir}/libz.a")
else()
    set(_graphviz_zlib "${_graphviz_lib_dir}/libz.so")
endif()

set(_graphviz_expat "${_graphviz_lib_dir}/libexpat.a")

function(_graphviz_add_static_target _name _filename)
    if(NOT TARGET "Graphviz::${_name}")
        add_library("Graphviz::${_name}" STATIC IMPORTED)
        set_target_properties("Graphviz::${_name}" PROPERTIES
            IMPORTED_LOCATION "${_graphviz_lib_dir}/${_filename}"
            INTERFACE_INCLUDE_DIRECTORIES "${_graphviz_include_dir}"
        )
    endif()
endfunction()

_graphviz_add_static_target(cdt "libcdt.a")
_graphviz_add_static_target(cgraph "libcgraph.a")
_graphviz_add_static_target(common "libcommon.a")
_graphviz_add_static_target(pack "libpack.a")
_graphviz_add_static_target(util "libutil.a")
_graphviz_add_static_target(label "liblabel.a")
_graphviz_add_static_target(dotgen "libdotgen.a")
_graphviz_add_static_target(ortho "libortho.a")
_graphviz_add_static_target(pathplan "libpathplan.a")
_graphviz_add_static_target(xdot "libxdot.a")
_graphviz_add_static_target(gvc "libgvc.a")
_graphviz_add_static_target(gvplugin_core "libgvplugin_core.a")
_graphviz_add_static_target(gvplugin_dot_layout "libgvplugin_dot_layout.a")
if(EXISTS "${_graphviz_lib_dir}/libgvplugin_webp.a")
    _graphviz_add_static_target(gvplugin_webp "libgvplugin_webp.a")
endif()

set_target_properties(Graphviz::cgraph PROPERTIES
    INTERFACE_LINK_LIBRARIES "Graphviz::cdt"
)
set_target_properties(Graphviz::label PROPERTIES
    INTERFACE_LINK_LIBRARIES "Graphviz::cdt"
)
set_target_properties(Graphviz::pathplan PROPERTIES
    INTERFACE_LINK_LIBRARIES "Graphviz::util"
)
set_target_properties(Graphviz::ortho PROPERTIES
    INTERFACE_LINK_LIBRARIES "Graphviz::util"
)
set_target_properties(Graphviz::xdot PROPERTIES
    INTERFACE_LINK_LIBRARIES ""
)
set_target_properties(Graphviz::common PROPERTIES
    INTERFACE_LINK_LIBRARIES "Graphviz::cgraph;Graphviz::pathplan;Graphviz::label;Graphviz::xdot;Graphviz::util;${_graphviz_expat}"
)
set_target_properties(Graphviz::pack PROPERTIES
    INTERFACE_LINK_LIBRARIES "Graphviz::util"
)
set_target_properties(Graphviz::dotgen PROPERTIES
    INTERFACE_LINK_LIBRARIES "Graphviz::cgraph;Graphviz::util;Graphviz::ortho"
)
set_target_properties(Graphviz::gvc PROPERTIES
    INTERFACE_LINK_LIBRARIES "Graphviz::cdt;Graphviz::cgraph;Graphviz::common;Graphviz::pack;Graphviz::util;${_graphviz_zlib}"
)
set_target_properties(Graphviz::gvplugin_core PROPERTIES
    INTERFACE_LINK_LIBRARIES "Graphviz::cgraph;Graphviz::gvc;Graphviz::util;Graphviz::xdot"
)
set_target_properties(Graphviz::gvplugin_dot_layout PROPERTIES
    INTERFACE_LINK_LIBRARIES "Graphviz::dotgen;Graphviz::gvc"
)
if(TARGET Graphviz::gvplugin_webp)
    set(_graphviz_webp_link_libs "${_graphviz_lib_dir}/libwebp.a")
    if(EXISTS "${_graphviz_lib_dir}/libsharpyuv.a")
        string(APPEND _graphviz_webp_link_libs ";${_graphviz_lib_dir}/libsharpyuv.a")
    endif()
    set_target_properties(Graphviz::gvplugin_webp PROPERTIES
        INTERFACE_LINK_LIBRARIES "Graphviz::gvc;${_graphviz_webp_link_libs}"
    )
endif()

if(NOT TARGET Graphviz::graphviz)
    set(_graphviz_interface_libs
        "-Wl,--start-group;Graphviz::gvc;Graphviz::gvplugin_core;Graphviz::gvplugin_dot_layout"
    )
    if(TARGET Graphviz::gvplugin_webp)
        string(APPEND _graphviz_interface_libs ";Graphviz::gvplugin_webp")
    endif()
    string(APPEND _graphviz_interface_libs
        ";Graphviz::common;Graphviz::pack;Graphviz::dotgen;Graphviz::ortho;Graphviz::pathplan;Graphviz::xdot;Graphviz::label;Graphviz::util;Graphviz::cgraph;Graphviz::cdt;${_graphviz_expat};${_graphviz_zlib};-Wl,--end-group"
    )
    add_library(Graphviz::graphviz INTERFACE IMPORTED)
    set_target_properties(Graphviz::graphviz PROPERTIES
        INTERFACE_INCLUDE_DIRECTORIES "${_graphviz_include_dir}"
        INTERFACE_LINK_LIBRARIES "${_graphviz_interface_libs}"
    )
endif()

set(Graphviz_FOUND TRUE)
set(GRAPHVIZ_FOUND TRUE)
set(Graphviz_INCLUDE_DIRS "${_graphviz_include_dir}")
set(GRAPHVIZ_INCLUDE_DIRS "${_graphviz_include_dir}")
set(Graphviz_LIBRARIES Graphviz::graphviz)
set(GRAPHVIZ_LIBRARIES Graphviz::graphviz)
set(Graphviz_VERSION "15.1.0")
set(GRAPHVIZ_VERSION "15.1.0")

unset(_graphviz_include_dir)
unset(_graphviz_lib_dir)
unset(_graphviz_expat)
unset(_graphviz_interface_libs)
unset(_graphviz_webp_link_libs)
unset(_graphviz_zlib)
unset(_graphviz_prefix)
