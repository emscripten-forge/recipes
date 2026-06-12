get_filename_component(_protobuf_prefix "${CMAKE_CURRENT_LIST_FILE}" PATH)
get_filename_component(_protobuf_prefix "${_protobuf_prefix}" PATH)
get_filename_component(_protobuf_prefix "${_protobuf_prefix}" PATH)
get_filename_component(_protobuf_prefix "${_protobuf_prefix}" PATH)

file(GLOB _protobuf_absl_libs LIST_DIRECTORIES FALSE "${_protobuf_prefix}/lib/libabsl_*.a")
set(_protobuf_extra_libs ${_protobuf_absl_libs})
if(EXISTS "${_protobuf_prefix}/lib/libutf8_validity.a")
    list(APPEND _protobuf_extra_libs "${_protobuf_prefix}/lib/libutf8_validity.a")
endif()
if(EXISTS "${_protobuf_prefix}/lib/libutf8_range.a")
    list(APPEND _protobuf_extra_libs "${_protobuf_prefix}/lib/libutf8_range.a")
endif()
if(EXISTS "${_protobuf_prefix}/lib/libz.a")
    list(APPEND _protobuf_extra_libs "${_protobuf_prefix}/lib/libz.a")
endif()

if(NOT TARGET protobuf::libprotobuf)
    add_library(protobuf::libprotobuf STATIC IMPORTED)
    set_target_properties(protobuf::libprotobuf PROPERTIES
        IMPORTED_LOCATION "${_protobuf_prefix}/lib/libprotobuf.a"
        INTERFACE_INCLUDE_DIRECTORIES "${_protobuf_prefix}/include"
        INTERFACE_LINK_LIBRARIES "${_protobuf_extra_libs}"
    )
endif()

if(NOT TARGET protobuf::libprotobuf-lite)
    add_library(protobuf::libprotobuf-lite STATIC IMPORTED)
    set_target_properties(protobuf::libprotobuf-lite PROPERTIES
        IMPORTED_LOCATION "${_protobuf_prefix}/lib/libprotobuf-lite.a"
        INTERFACE_INCLUDE_DIRECTORIES "${_protobuf_prefix}/include"
        INTERFACE_LINK_LIBRARIES "${_protobuf_extra_libs}"
    )
endif()

unset(_protobuf_extra_libs)
unset(_protobuf_absl_libs)
unset(_protobuf_prefix)
