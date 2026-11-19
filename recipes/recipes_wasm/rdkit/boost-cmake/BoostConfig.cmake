# libboost-headers ships no CMake config; rdkit only needs the header-only
# Boost::boost target (serialization / iostreams / boost.python are disabled).
# Boost_INCLUDE_DIR is passed by build.sh.
if(NOT TARGET Boost::boost)
  add_library(Boost::boost INTERFACE IMPORTED)
  set_target_properties(Boost::boost PROPERTIES
    INTERFACE_INCLUDE_DIRECTORIES "${Boost_INCLUDE_DIR}")
endif()
set(Boost_FOUND TRUE)
set(Boost_INCLUDE_DIRS "${Boost_INCLUDE_DIR}")
