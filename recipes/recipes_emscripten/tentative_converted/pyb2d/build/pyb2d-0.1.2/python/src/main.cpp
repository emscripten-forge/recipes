#include "pybind11/pybind11.h"

// #include "xtensor/xmath.hpp"
// #include "xtensor/xarray.hpp"

// #define FORCE_IMPORT_ARRAY
// #include "xtensor-python/pyarray.hpp"
// #include "xtensor-python/pyvectorize.hpp"

#include <iostream>
#include <numeric>
#include <string>
#include <sstream>

namespace py = pybind11;


namespace py = pybind11;
namespace pybox2d{
    void def_build_config(py::module &m);
}
void exportContact(py::module & );
void exportB2World(py::module & );
void exportB2Body(py::module & );
void exportB2Math(py::module & );
void exportB2Fixture(py::module & );
void exportB2Shape(py::module & );
void exportb2Joint(py::module & );
void exportb2JointDef(py::module & );
void exportB2WorldCallbacks(py::module & );
void exportB2Draw(py::module & );
void exportb2Collision(py::module & );
#ifdef PYBOX2D_LIQUID_FUN
void exportB2Particle(py::module & );
void exportB2ParticleSystem(py::module & );
void exportB2ParticleGroup(py::module & );
void exportEmitter(py::module &);
#endif



// Python Module and Docstrings
PYBIND11_MODULE(_b2d , pybox2dModule)
{
    //xt::import_numpy();

    pybox2dModule.doc() = R"pbdoc(
        _pybox2d  python bindings

        .. currentmodule:: _pybox2d 

        .. autosummary::
           :toctree: _generate

           BuildConfiguration
           MyClass
    )pbdoc";

    pybox2d::def_build_config(pybox2dModule);
    exportContact(pybox2dModule);
    exportB2World(pybox2dModule);
    exportB2Body(pybox2dModule);
    exportB2Math(pybox2dModule);
    exportB2Shape(pybox2dModule);
    exportB2Fixture(pybox2dModule);
    exportb2Joint(pybox2dModule);
    exportb2JointDef(pybox2dModule);
    exportB2WorldCallbacks(pybox2dModule);
    exportB2Draw(pybox2dModule);
    exportb2Collision(pybox2dModule);
    #ifdef PYBOX2D_LIQUID_FUN
    exportB2Particle(pybox2dModule);
    exportB2ParticleSystem(pybox2dModule);
    exportB2ParticleGroup(pybox2dModule);
    exportEmitter(pybox2dModule);
    #endif

    // // make version string
    // std::stringstream ss;
    // ss<<PYBOX2D_VERSION_MAJOR<<"."
    //   <<PYBOX2D_VERSION_MINOR<<"."
    //   <<PYBOX2D_VERSION_PATCH;
    // pybox2dModule.attr("__version__") = ss.str().c_str();
}