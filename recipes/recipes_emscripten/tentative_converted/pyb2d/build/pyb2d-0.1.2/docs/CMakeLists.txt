file(COPY ${CMAKE_SOURCE_DIR}/docs DESTINATION ${CMAKE_BINARY_DIR}/docs_bld)


set(PY_MOD_NAME b2d )
set(PY_MOD_LIB_NAME _${PY_MOD_NAME})
set(PYTHON_TMP_MODULE_DIR ${CMAKE_BINARY_DIR}/python/module)
set(INCLUDE_PATH ${CMAKE_SOURCE_DIR}/include)

configure_file(
    ${CMAKE_SOURCE_DIR}/docs/source/cmake_path.py.in
    ${CMAKE_BINARY_DIR}/docs_bld/docs/source/cmake_path.py
)

find_package(Sphinx REQUIRED)

if(NOT DEFINED SPHINX_THEME)
    set(SPHINX_THEME default)
endif()
 
if(NOT DEFINED SPHINX_THEME_DIR)
    set(SPHINX_THEME_DIR)
endif()



# configured documentation tools and intermediate build results
set(BINARY_BUILD_DIR "${CMAKE_BINARY_DIR}/docs_bld/docs/source")
 
# Sphinx cache with pickled ReST documents
set(SPHINX_CACHE_DIR "${CMAKE_BINARY_DIR}/docs_bld/docs/_doctrees")
 
# HTML output directory
set(SPHINX_HTML_DIR "${CMAKE_BINARY_DIR}/docs_bld/html")
  
add_custom_target(docs 
    ${SPHINX_EXECUTABLE}
        -q -b html
        -c "${BINARY_BUILD_DIR}"
        -d "${SPHINX_CACHE_DIR}"
        "${CMAKE_BINARY_DIR}/docs_bld/docs/source"
        "${SPHINX_HTML_DIR}"
    COMMENT "Building HTML documentation with Sphinx")

add_dependencies(docs  ${PY_MOD_LIB_NAME})