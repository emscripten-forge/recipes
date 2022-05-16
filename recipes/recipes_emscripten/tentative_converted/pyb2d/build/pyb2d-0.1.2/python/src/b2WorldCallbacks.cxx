#include <pybind11/pybind11.h>

#include "box2d_wrapper.hpp"

#include "pyb2WorldCallbacks.hxx"
namespace py = pybind11;




#include "holder.hxx"


void exportB2WorldCallbacks(py::module & pybox2dModule){


    py::class_<b2ContactImpulse, ContactImpulseHolder>(pybox2dModule,"ContactImpulse")
        .def_readonly("normal_impulses",&b2ContactImpulse::normalImpulses)
        .def_readonly("tangent_impulses",&b2ContactImpulse::tangentImpulses)
        .def_readonly("count",&b2ContactImpulse::count)
    ;


    py::class_<PyB2QueryCallbackCaller>(pybox2dModule,"QueryCallbackCaller")
        .def(py::init<const py::object &>(),py::arg("query_callback")
        )
    ;

    py::class_<PyB2RayCastCallbackCaller>(pybox2dModule,"RayCastCallbackCaller")
        .def(py::init<const py::object &>(),py::arg("ray_cast_callback")
        )
    ;

    py::class_<PyB2DestructionListenerCaller>(pybox2dModule,"DestructionListenerCaller")
        .def(py::init<const py::object &>(),py::arg("destruction_listener")
        )
    ;
  
    py::class_<PyB2ContactListenerCaller>(pybox2dModule,"ContactListenerCaller")
        .def(py::init<const py::object &>(),py::arg("contact_listener")
        )
    ;
   
    py::class_<PyB2ContactFilterCaller>(pybox2dModule,"ContactFilterCaller")
        .def(py::init<const py::object &>(),py::arg("contact_filter")
        )
    ;
 


   

}


