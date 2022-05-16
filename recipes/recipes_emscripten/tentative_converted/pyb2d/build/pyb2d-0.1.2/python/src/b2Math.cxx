#include <pybind11/pybind11.h>
#include <pybind11/operators.h>
#include "box2d_wrapper.hpp"

namespace py = pybind11;



b2Vec2 operator+ (const b2Vec2 & lhs, const py::tuple & rhs)
{
    return b2Vec2(
        lhs.x + rhs[0].cast<float>()  ,
        lhs.y + rhs[1].cast<float>()  
    );
}
b2Vec2 operator+ (const py::tuple & lhs, const b2Vec2 & rhs)
{
    return b2Vec2(
         lhs[0].cast<float>() + rhs.x   ,
         lhs[1].cast<float>() + rhs.y   
    );
}

// b2Vec2 operator+ (const b2Vec2 & lhs, const b2Vec2 & rhs)
// {
//     return b2Vec2(
//          lhs.x + rhs.x   ,
//          lhs.y + rhs.y   
//     );
// }

#ifndef PYBOX2D_OLD_BOX2D
b2Vec2 operator/ (const b2Vec2 & lhs, float rhs)
{
    return b2Vec2(
         lhs.x / rhs  ,
         lhs.y / rhs    
    );
}
b2Vec2 operator* (const b2Vec2 & lhs, float rhs)
{
    return b2Vec2(
         lhs.x * rhs  ,
         lhs.y * rhs    
    );
}
#endif

void exportB2Math(py::module & pybox2dModule){

    pybox2dModule.def("b2IsValid",&b2IsValid, py::arg("x"));
    //pybox2dModule.def("b2InvSqrt",&b2InvSqrt, py::arg("x"));
    pybox2dModule.def("b2Sqrt",&sqrtf, py::arg("x"));
    pybox2dModule.def("b2Atan2",&atan2f, py::arg("x"),py::arg("y"));


    py::class_<b2Vec2>(pybox2dModule,"Vec2")

       .def(py::init([](py::tuple t) { 
            if(py::len(t) != 2)
            {
                throw std::runtime_error("tuple has wrong length");
            }
            return new b2Vec2(t[0].cast<float>(), t[1].cast<float>()); }
        )) 
       .def(py::init([](py::list t) { 
            if(py::len(t) != 2)
            {
                throw std::runtime_error("list has wrong length");
            }
            return new b2Vec2(t[0].cast<float>(), t[1].cast<float>()); }
        )) 
       .def(py::init<>())
       .def(py::init<float,float>(),py::arg("x"),py::arg("y"))
       .def_readwrite("x", &b2Vec2::x)
       .def_readwrite("y", &b2Vec2::y)
       // member functions
       .def("set_zero",&b2Vec2::SetZero)
       .def("Set",&b2Vec2::Set,py::arg("x"),py::arg("y"))
       //.def("Length",&b2Vec2::Length)
       .def("normalize",&b2Vec2::Normalize)
       .def("is_valid",&b2Vec2::IsValid)
       .def("skew",&b2Vec2::Skew)
       .def("__len__",[](const b2Vec2 & vec){return 2;})
       // operators
       // .def(py::self += py::self)
       // .def(py::self -= py::self)
       // .def(py::self *= float())
       // .def(py::self +  float())
       // .def(py::self -  float())
       // .def(float() *  py::self)
       .def(py::self *  float())
       .def(py::self /  float())
       .def(py::self +  py::self)
       .def(py::self -  py::self)
       // .def(py::self + py::tuple())
       // .def(py::tuple() + py::self)
       .def_property_readonly("length",[](const b2Vec2 & self){
            return std::sqrt(self.x * self.x + self.y * self.y);
       })
       .def_property_readonly("length_squared",&b2Vec2::LengthSquared)
    ;

    py::implicitly_convertible<py::tuple, b2Vec2>();
    py::implicitly_convertible<py::list, b2Vec2>();

    py::class_<b2Vec3>(pybox2dModule,"Vec3")
        .def(py::init<>())
        .def(py::init<float,float,float>(),py::arg("x"),py::arg("y"),py::arg("z"))
        .def_readwrite("x", &b2Vec3::x)
        .def_readwrite("y", &b2Vec3::y)
        .def_readwrite("z", &b2Vec3::z)
        // member functions
        .def("set_zero",&b2Vec3::SetZero)
        .def("set",&b2Vec3::Set,py::arg("x"),py::arg("y"),py::arg("z"))
        //.def("normalize",&b2Vec3::Normalize)
        // operators
        .def(py::self += py::self)
        .def(py::self -= py::self)
        .def(py::self *= float())
        //.def_property_readonly("length",&b2Vec3::Length)
        // .def_property_readonly("length_squared",&b2Vec3::LengthSquared)
    ;

    // py::class_<b2Vec4>(pybox2dModule,"b2Vec4")
    //     .def(py::init<>())
    //     .def(py::init<float,float,float,float>(),py::arg("x"),py::arg("y"),py::arg("z"),py::arg("w"))
    //     .def_readwrite("x", &b2Vec4::x)
    //     .def_readwrite("y", &b2Vec4::y)
    //     .def_readwrite("z", &b2Vec4::z)
    //     .def_readwrite("z", &b2Vec4::w)
    //     //.def_property_readonly("length",&b2Vec4::Length)
    //     //.def_property_readonly("length_squared",&b2Vec4::LengthSquared)
    // ;

    py::class_<b2Mat22>(pybox2dModule,"Mat22")
        .def(py::init<>())
        .def(py::init<const b2Vec2 &,const b2Vec2 &>(),py::arg("c1"),py::arg("c2"))
        .def(py::init<float,float,float,float>(),py::arg("a11"),py::arg("a12"),py::arg("a21"),py::arg("a22"))
        .def_readwrite("ex", &b2Mat22::ex)
        .def_readwrite("ey", &b2Mat22::ey)
        // member functions
        .def("set",&b2Mat22::Set,py::arg("c1"),py::arg("c2"))
        .def("set_identity",&b2Mat22::SetIdentity)
        .def("set_zero",&b2Mat22::SetZero)
        .def("get_inverse",&b2Mat22::GetInverse)
        .def("solve",&b2Mat22::Solve,py::arg("b"))
        // operators
    ;

    py::class_<b2Mat33>(pybox2dModule,"Mat33")
        .def(py::init<>())
        .def(py::init<const b2Vec3 &,const b2Vec3 &,const b2Vec3 &>(),py::arg("c1"),py::arg("c2"),py::arg("c3"))
        .def_readwrite("ex", &b2Mat33::ex)
        .def_readwrite("ey", &b2Mat33::ey)
        .def_readwrite("ez", &b2Mat33::ez)
        // member functions
        .def("set_zero",&b2Mat33::SetZero)
        .def("solve_33",&b2Mat33::Solve33,py::arg("b"))
        .def("solve_22",&b2Mat33::Solve22,py::arg("b"))
        .def("get_inverse_22",&b2Mat33::GetInverse22,py::arg("M"))
        .def("get_sym_inverse_33",&b2Mat33::GetSymInverse33,py::arg("M"))
        // operators
        // 
    ;

    py::class_<b2Rot>(pybox2dModule,"Rot")
        .def(py::init<>())
        .def(py::init<float>(),py::arg("angle"))
        .def_readwrite("s", &b2Rot::s)
        .def_readwrite("c", &b2Rot::c)
        // member functions
        .def("set",&b2Rot::Set,py::arg("angle"))
        .def("set_identity",&b2Rot::SetIdentity)
        .def("get_angle",&b2Rot::GetAngle)
        .def("get_x_axis",&b2Rot::GetXAxis)
        .def("get_y_axis",&b2Rot::GetYAxis)
        // operators
        // 
    ;

    py::class_<b2Transform>(pybox2dModule,"Transform")
        .def(py::init<>())
        .def(py::init<const b2Vec2 &, const b2Rot & >(),py::arg("position"),py::arg("rotation"))
        .def_readwrite("p", &b2Transform::p)
        .def_readwrite("position", &b2Transform::p)
        .def_readwrite("q", &b2Transform::q)
        // member functions
        .def("set",&b2Transform::Set,py::arg("position"),py::arg("angle"))
        .def("set_identity",&b2Transform::SetIdentity)
        // .def("GetPositionX",&b2Transform::GetPositionX)
        // .def("GetPositionY",&b2Transform::GetPositionY)
        //.def("GetRotationCos",&b2Transform::GetRotationCos)
        // operators
        // 
    ;

    py::class_<b2Sweep>(pybox2dModule,"Sweep")
        .def(py::init<>())
        .def_readwrite("local_center", &b2Sweep::localCenter)
        .def_readwrite("c0", &b2Sweep::c0)
        .def_readwrite("c", &b2Sweep::c)
        .def_readwrite("a0", &b2Sweep::a0)
        .def_readwrite("a", &b2Sweep::a)
        .def_readwrite("alpha0", &b2Sweep::alpha0)

        // member functions
        .def("Advance",&b2Sweep::Advance,py::arg("alpha"))
        .def("Normalize",&b2Sweep::Normalize)
        // operators
        // 
    ;


    pybox2dModule.def("dot", [](const b2Vec2& a, const b2Vec2& b){
        return b2Dot(a,b);
    },py::arg("a"),py::arg("b"));

    pybox2dModule.def("dot", [](const b2Vec3& a, const b2Vec3& b){
        return b2Dot(a,b);
    },py::arg("a"),py::arg("b"));

    pybox2dModule.def("cross", [](const b2Vec2& a, const b2Vec2& b){
        return b2Cross(a,b);
    },py::arg("a"),py::arg("b"));

    pybox2dModule.def("cross", [](const b2Vec3& a, const b2Vec3& b){
        return b2Cross(a,b);
    },py::arg("a"),py::arg("b"));

    pybox2dModule.def("cross", [](const b2Vec2& a, float b){
        return b2Cross(a,b);
    },py::arg("a"),py::arg("b"));

    pybox2dModule.def("cross", [](float a, const b2Vec2& b){
        return b2Cross(a,b);
    },py::arg("a"),py::arg("b"));

    pybox2dModule.def("mulT", [](const b2Mat22 & A, const b2Vec2& v){
        return b2MulT(A,v);
    },py::arg("A"),py::arg("v"));

    pybox2dModule.def("mulT", [](const b2Rot & q, const b2Vec2& v){
        return b2MulT(q,v);
    },py::arg("q"),py::arg("v"));

    pybox2dModule.def("distance", [](const b2Vec2& a, const b2Vec2& b){
        return b2Distance(a,b);
    },py::arg("a"),py::arg("b"));

    pybox2dModule.def("distance_squared", [](const b2Vec2& a, const b2Vec2& b){
        return b2DistanceSquared(a,b);
    },py::arg("a"),py::arg("b"));

    pybox2dModule.def("mul", [](const b2Mat22 & A, const b2Mat22& B){
        return b2Mul(A,B);
    },py::arg("A"),py::arg("B"));

    pybox2dModule.def("mul", [](const b2Mat33 & A, const b2Vec3& v){
        return b2Mul(A,v);
    },py::arg("A"),py::arg("v"));

    pybox2dModule.def("mul", [](const b2Rot & q, const b2Rot& r){
        return b2Mul(q,r);
    },py::arg("q"),py::arg("r"));

    pybox2dModule.def("mul", [](const b2Rot & q, const b2Vec2& v){
        return b2Mul(q,v);
    },py::arg("q"),py::arg("v"));

    pybox2dModule.def("mul", [](const b2Transform & T, const b2Vec2& v){
        return b2Mul(T,v);
    },py::arg("T"),py::arg("v"));
}
