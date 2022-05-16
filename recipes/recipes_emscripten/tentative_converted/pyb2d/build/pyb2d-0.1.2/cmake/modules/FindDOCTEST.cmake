find_path(DOCTEST_INCLUDE_DIR doctest.h)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(DOCTEST DEFAULT_MSG   DOCTEST_INCLUDE_DIR)

if(DOCTEST_FOUND)
    set(DOCTEST_INCLUDE_DIRS ${DOCTEST_INCLUDE_DIR})
endif(DOCTEST_FOUND)

mark_as_advanced( DOCTEST_INCLUDE_DIR)
