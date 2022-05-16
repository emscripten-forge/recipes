
#include <pybind11/pybind11.h>
#include <pybind11/stl.h>
#include <pybind11/operators.h>
#include "box2d_wrapper.hpp"

#include "holder.hxx"


#include <vector>

namespace py = pybind11;




void exportb2Collision(py::module & pybox2dModule){



    py::class_<b2AABB>(pybox2dModule,"b2AABB")
        .def(py::init<>())
        .def_readwrite("lower_bound",&b2AABB::lowerBound)
        .def_readwrite("upper_bound",&b2AABB::upperBound)
    ;

    py::class_<b2ManifoldPoint>(pybox2dModule,"b2ManifoldPoint")
        .def_readonly("local_point",         &b2ManifoldPoint::localPoint)
        .def_readonly("normal_impulse",      &b2ManifoldPoint::normalImpulse)
        .def_readonly("tangent_impulse",     &b2ManifoldPoint::tangentImpulse)
        .def_readonly("id",                 &b2ManifoldPoint::id)
    ;
    


    auto b2ManifoldCls = py::class_<b2Manifold, ManifoldHolder>(pybox2dModule,"b2Manifold");
    b2ManifoldCls
        .def(py::init<>())

        .def_property_readonly("points",[](const b2Manifold * self){
            std::vector<b2ManifoldPoint> p(self->pointCount);
            for(int i=0; i<self->pointCount; ++i)
                p[i] = self->points[i];
            return p;
        })
        .def_readonly("local_normal",   &b2Manifold::localNormal)
        .def_readonly("local_point",    &b2Manifold::localPoint)
        .def_readonly("type",          &b2Manifold::type)
        .def_readonly("point_count",    &b2Manifold::pointCount)

    ;


    py::enum_<b2Manifold::Type>(b2ManifoldCls, "b2ManifoldType")
        .value("circles", b2Manifold::Type::e_circles)
        .value("face_a",   b2Manifold::Type::e_faceA)
        .value("face_b",   b2Manifold::Type::e_faceB)
    ;


    py::class_<b2WorldManifold, WorldManifoldHolder >(pybox2dModule,"b2WorldManifold")
        .def(py::init<>())

        .def_property_readonly("points",[](const b2Manifold * self){
            std::vector<b2ManifoldPoint> p(self->pointCount);
            for(int i=0; i<self->pointCount; ++i)
                p[i] = self->points[i];
            return p;
        })
        .def_property_readonly("local_normal", [](const b2Manifold * self){
            return self->localNormal;
        })
        .def_property_readonly("local_point",  [](const b2Manifold * self){
            return self->localPoint;
        })
        .def_property_readonly("type",        [](const b2Manifold * self){
            return self->type;
        })
        .def_property_readonly("point_count",  [](const b2Manifold * self){
            return self->pointCount;
        })

    ;
}
