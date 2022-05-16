

#include <pybind11/pybind11.h>

#include "box2d_wrapper.hpp"
#include "holder.hxx"
#include "extensions/b2Emitter.h"



namespace py = pybind11;






void exportEmitter(py::module & pybox2dModule){




    py::class_<b2EmitterDefBase> emitterDefBaseCls(pybox2dModule, "EmitterDefBase");
    emitterDefBaseCls
        .def(py::init<>())
        .def_readwrite("transform", &b2LinearEmitterDef::transform)
        .def_property("body", 
            [](const b2EmitterDefBase * self){
                return BodyHolder(self->body);
            }, 
            [](b2EmitterDefBase * self, b2Body * body){
                self->body = body;
            }
        )
        .def_readwrite("emite_rate", &b2LinearEmitterDef::emitRate)
        .def_readwrite("lifetime", &b2LinearEmitterDef::lifetime)
    ;


    py::class_<b2LinearEmitterDef> lineEmitterDefCls(pybox2dModule, "LinearEmitterDef", emitterDefBaseCls);
    lineEmitterDefCls
        .def(py::init<>())
        .def_readwrite("size", &b2LinearEmitterDef::size)
        .def_readwrite("velocity", &b2LinearEmitterDef::velocity)

    ;

    py::class_<b2RadialEmitterDef> radialEmitterDefCls(pybox2dModule, "RadialEmitterDef", emitterDefBaseCls);
    radialEmitterDefCls
        .def(py::init<>())
        .def_readwrite("inner_radius", &b2RadialEmitterDef::innerRadius)
        .def_readwrite("outer_radius", &b2RadialEmitterDef::outerRadius)
        .def_readwrite("velocity_magnitude", &b2RadialEmitterDef::velocityMagnitude)
        .def_readwrite("start_angle", &b2RadialEmitterDef::startAngle)
        .def_readwrite("stop_angle", &b2RadialEmitterDef::stopAngle)
    ;

    py::class_<b2EmitterBase> emitterBaseCls(pybox2dModule, "EmitterBase");
    emitterBaseCls
        .def(py::init<b2ParticleSystem *, const b2EmitterDefBase&>())
        .def_property("position", &b2EmitterBase::GetPosition, &b2EmitterBase::SetPosition)
        .def_property("angle", &b2EmitterBase::GetAngle, &b2EmitterBase::SetAngle)
        .def_property("transform", &b2EmitterBase::GetTransform, &b2EmitterBase::SetTransform)
    ;



    py::class_<b2LinearEmitter> lineEmitterCls(pybox2dModule, "LinearEmitter", emitterBaseCls);
    lineEmitterCls
        .def(py::init<b2ParticleSystem *, const b2LinearEmitterDef&>())
        .def("step", &b2LinearEmitter::Step)
    ;

    py::class_<b2RadialEmitter> radialEmitterCls(pybox2dModule, "RadialEmitter", emitterBaseCls);
    radialEmitterCls
        .def(py::init<b2ParticleSystem *, const b2RadialEmitterDef&>())
        .def("step", &b2RadialEmitter::Step)
    ;


}


