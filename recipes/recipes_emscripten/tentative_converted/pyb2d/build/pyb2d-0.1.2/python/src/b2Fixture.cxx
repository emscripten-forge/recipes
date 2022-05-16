#include <pybind11/pybind11.h>

#include "box2d_wrapper.hpp"
#include "apis/user_data_api.hxx"
#include "apis/get_next_api.hxx"
#include "holder.hxx"


namespace py = pybind11;


inline void setShape(PyDefExtender<b2FixtureDef> & f, b2Shape * s){
            f.shape = s;
}



void exportB2Fixture(py::module & pybox2dModule){


    py::class_<b2Filter>(pybox2dModule,"Filter")
        .def(py::init<>())
        .def_readwrite("category_bits", &b2Filter::categoryBits)
        .def_readwrite("mask_bits", &b2Filter::maskBits)
        .def_readwrite("group_index", &b2Filter::groupIndex)
    ;


    typedef PyDefExtender<b2FixtureDef> PyFixtureDef;
    py::class_<PyFixtureDef> b2FixtureDefCls(pybox2dModule,"FixtureDef");
    add_user_data_to_def_api<PyFixtureDef>(b2FixtureDefCls);

    b2FixtureDefCls
        .def(py::init<>())
        .def("_set_shape",  //[](PyFixtureDef & f, b2Shape * s){f.shape = s;}, 
                &setShape,
            py::keep_alive<1,2>()
        )
        .def_readonly("_shape", &PyFixtureDef::shape)
        //.def_readwrite("userData", &PyFixtureDef::userData)
        .def_readwrite("friction", &PyFixtureDef::friction)
        .def_readwrite("restitution", &PyFixtureDef::restitution)
        .def_readwrite("density", &PyFixtureDef::density)
        .def_readwrite("is_sensor", &PyFixtureDef::isSensor)
        .def_readwrite("filter", &PyFixtureDef::filter)
    ;

    py::class_<b2Fixture, FixtureHolder> b2FixtureCls(pybox2dModule,"Fixture");
    add_user_data_api<b2Fixture>(b2FixtureCls);
    add_get_next_api<b2Fixture>(b2FixtureCls);
    b2FixtureCls
        .def_property_readonly("type", &b2Fixture::GetType)
        .def("_getShape", [](b2Fixture & f) {return ShapeHolder(f.GetShape());})
        .def("set_Sensor", &b2Fixture::SetSensor,py::arg("sensor`"))
        .def_property_readonly("is_sensor", &b2Fixture::IsSensor)

        .def_property_readonly("body", [](b2Fixture & f) {return f.GetBody();},
            py::return_value_policy::reference_internal
        )
        .def("test_point",&b2Fixture::TestPoint)

        .def_property_readonly("type",&b2Fixture::GetType)
    ;

}