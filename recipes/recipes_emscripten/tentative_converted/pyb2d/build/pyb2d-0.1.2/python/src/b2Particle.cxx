#include <pybind11/pybind11.h>

#include "box2d_wrapper.hpp"

#include <vector>

#include "holder.hxx"
#include "apis/user_data_api.hxx"

namespace py = pybind11;


void exportB2Particle(py::module & pybox2dModule){


    py::class_<b2ParticleColor>(pybox2dModule, "ParticleColor")
        .def(py::init([](py::tuple t) { 
            if(py::len(t) != 4)
            {
                throw std::runtime_error("tuple has wrong length");
            }
            return new b2ParticleColor(
                    t[0].cast<uint8_t>(), 
                    t[1].cast<uint8_t>(),
                    t[2].cast<uint8_t>(),
                    t[3].cast<uint8_t>()
                ); 
            }
        )) 

        .def(py::init<uint8,uint8,uint8,uint8>(),
            py::arg("r"),py::arg("g"),py::arg("b"),py::arg("a")
        );
    ;
    py::implicitly_convertible<py::tuple, b2ParticleColor>();

    typedef PyDefExtender<b2ParticleDef> PyParticleDef;

    py::class_<PyParticleDef> py_particle_def(pybox2dModule, "ParticleDef");
    add_user_data_to_def_api<PyParticleDef>(py_particle_def);

    py_particle_def
        .def(py::init<>())
        .def_readwrite("flags",&PyParticleDef::flags)
        .def_readwrite("position",&PyParticleDef::position)
        .def_readwrite("velocity",&PyParticleDef::velocity)
        .def_readwrite("color",&PyParticleDef::color)
        .def_readwrite("lifetime",&PyParticleDef::lifetime)
        .def_readwrite("group",&PyParticleDef::group)
    ;
}


