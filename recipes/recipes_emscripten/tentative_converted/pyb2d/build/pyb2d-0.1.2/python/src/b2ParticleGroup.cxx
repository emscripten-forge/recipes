#include <pybind11/pybind11.h>

#include "box2d_wrapper.hpp"


namespace py = pybind11;


#include "holder.hxx"



void exportB2ParticleGroup(py::module & pybox2dModule){



    py::class_<b2ParticleGroupDef>(pybox2dModule, "ParticleGroupDef")
    .def(py::init<>())
        //.def("SetRadius",&b2ParticleSystem::SetRadius)
        //.def("SetDamping",&b2ParticleSystem::SetDamping)
        //
        //      


    .def_readwrite("flags",&b2ParticleGroupDef::flags)
    .def_readwrite("group_flags",&b2ParticleGroupDef::groupFlags)
    .def_readwrite("position",&b2ParticleGroupDef::position)
    .def_readwrite("angle",&b2ParticleGroupDef::angle)
    .def_readwrite("linear_velocity",&b2ParticleGroupDef::linearVelocity)
    .def_readwrite("angular_velocity",&b2ParticleGroupDef::angularVelocity)
    .def_readwrite("color",&b2ParticleGroupDef::color)
    .def_readwrite("strength",&b2ParticleGroupDef::strength)
    .def_readwrite("_shape",&b2ParticleGroupDef::shape)
    .def("_setShape",
        [](b2ParticleGroupDef & d, const b2Shape * s){
            d.shape = s;
        }, py::keep_alive<1,2>()
    )
    //.def_readwrite("shape",&b2ParticleGroupDef::shape)
    //.def_readwrite("shapes",&b2ParticleGroupDef::shapes)
    //.def_readwrite("shapeCount",&b2ParticleGroupDef::shapeCount)
    .def_readwrite("stride",&b2ParticleGroupDef::stride)
    .def_readwrite("particle_count",&b2ParticleGroupDef::particleCount)
    //.def_readwrite("positionData",&b2ParticleGroupDef::positionData)
    .def_readwrite("lifetime",&b2ParticleGroupDef::lifetime)
    //.def_readwrite("userData",&b2ParticleGroupDef::userData)
    .def_readwrite("_group",&b2ParticleGroupDef::group)
    .def("_set_group",
        [](b2ParticleGroupDef & d, b2ParticleGroup * g){
            d.group = g;
        }, py::keep_alive<1,2>()
    )

    ;


    py::class_<b2ParticleGroup, ParticleGroupHolder>(pybox2dModule, "b2ParticleGroup")
        //.def(py::init<>())
    ;

}


