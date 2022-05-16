#include <pybind11/pybind11.h>
#include "box2d_wrapper.hpp"


#include "debug_draw/pyb2Draw.hxx"
#include "debug_draw/batch_debug_draw_caller.hxx"

#include <iostream>
#include <initializer_list>


namespace py = pybind11;



void exportB2Draw(py::module & pybox2dModule){


    py::class_<b2Color>(pybox2dModule, "Color")
        .def_readwrite("r",&b2Color::r)
        .def_readwrite("g",&b2Color::g)
        .def_readwrite("b",&b2Color::b)
    ;


    py::class_<PyB2Draw>(pybox2dModule,"DrawCaller")
        .def(py::init<const py::object &, const bool >())

        .def_property("flags",
            [](PyB2Draw * draw){return draw->GetFlags();},
            [](PyB2Draw * draw,const int flag){draw->SetFlags(flag);}
        )
        .def("reset_bounding_box",&PyB2Draw::resetBoundingBox)
        .def_property_readonly("bounding_box", &PyB2Draw::getBoundingBox)
        .def("_append_flags_int",[](PyB2Draw * draw,const int flag){draw->AppendFlags(flag);})
        .def("_clear_flags_int",[](PyB2Draw * draw,const int flag){draw->ClearFlags(flag);})
        .def_readwrite("scale",&PyB2Draw::m_scale)
        .def_readwrite("translate",&PyB2Draw::m_translate)
        .def_readwrite("flip_y",&PyB2Draw::m_flip_y)
        .def("world_to_screen", &PyB2Draw::world_to_screen)
        .def("screen_to_world", &PyB2Draw::screen_to_world)
        .def("world_to_screen_scale", &PyB2Draw::world_to_screen_scale)
        .def("screen_to_world_scale", &PyB2Draw::screen_to_world_scale)
    ;

    py::class_<BatchDebugDrawCaller>(pybox2dModule, "BatchDebugDrawCaller")
        .def(py::init<const py::object &>())
        .def("_append_flags_int",[](BatchDebugDrawCaller * draw,const int flag){draw->AppendFlags(flag);})
        .def("_clear_flags_int",[](BatchDebugDrawCaller * draw,const int flag){draw->ClearFlags(flag);})
        .def_readwrite("scale",&BatchDebugDrawCaller::m_scale)
        .def_readwrite("translate",&BatchDebugDrawCaller::m_translate)
        .def_readwrite("flip_y",&BatchDebugDrawCaller::m_flip_y)
        .def("world_to_screen", &BatchDebugDrawCaller::world_to_screen)
        .def("screen_to_world", &BatchDebugDrawCaller::screen_to_world)
        .def("world_to_screen_scale", &BatchDebugDrawCaller::world_to_screen_scale)
        .def("screen_to_world_scale", &BatchDebugDrawCaller::screen_to_world_scale)
    ;
}


