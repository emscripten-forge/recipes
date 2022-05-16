#include "pybind11/pybind11.h"
#include "pybind11/numpy.h"

#include <iostream>
#include <numeric>

namespace py = pybind11;



namespace pybox2d {

    void def_build_config(py::module & m)
    {

        struct BuildConfiguration        {
            
        };


        py::class_<BuildConfiguration>(m, "BuildConfiguration",
        "This class show the compile/build configuration\n"
        "Of pybox2d\n"
        )
        .def_property_readonly_static("DEBUG", [](py::object /* self */) {
            #ifdef  NDEBUG
            return false;
            #else
            return true;
            #endif
        })
        .def_property_readonly_static("LIQUID_FUN", [](py::object /* self */) {
            #ifdef  PYBOX2D_LIQUID_FUN
            return true;
            #else
            return false;
            #endif
        })
        .def_property_readonly_static("OLD_BOX2D", [](py::object /* self */) {
            #ifdef  PYBOX2D_OLD_BOX2D
            return true;
            #else
            return false;
            #endif
        })

;



    }

}
