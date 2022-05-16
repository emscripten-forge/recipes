
#-------------------------------------------------------------------------------------------------------------------
# Setup python bindings
#-------------------------------------------------------------------------------------------------------------------
find_package(NUMPY 	           REQUIRED)
find_package(pybind11 CONFIG   REQUIRED)

set(PY_MOD_NAME b2d )
set(PY_MOD_LIB_NAME _${PY_MOD_NAME})




IF(NOT DEFINED PYTHON_MODULE_INSTALL_DIR OR PYTHON_MODULE_INSTALL_DIR MATCHES "")

    execute_process(
      COMMAND "${PYTHON_EXECUTABLE}" -c "from __future__ import print_function; from distutils.sysconfig import get_python_lib; print(get_python_lib())"
      OUTPUT_VARIABLE PYTHON_SITE
      OUTPUT_STRIP_TRAILING_WHITESPACE)
    SET(PYTHON_MODULE_INSTALL_DIR ${PYTHON_SITE})

endif()

SET(PYTHON_MODULE_INSTALL_DIR ${PYTHON_MODULE_INSTALL_DIR}
    CACHE PATH "where to install the Python package" FORCE)


# temporary python module dir

file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/python/module/${PY_MOD_NAME})


add_subdirectory(src)


file(COPY ${CMAKE_SOURCE_DIR}/python/module/${PY_MOD_NAME} DESTINATION ${CMAKE_BINARY_DIR}/python/module)


install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/module/
    DESTINATION ${PYTHON_MODULE_INSTALL_DIR})


