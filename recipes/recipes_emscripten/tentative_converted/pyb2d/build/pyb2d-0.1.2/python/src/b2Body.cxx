#include <pybind11/pybind11.h>

#include "box2d_wrapper.hpp"


#include <vector>

#include "holder.hxx"
#include "apis/user_data_api.hxx"
#include "apis/get_next_api.hxx"

namespace py = pybind11;


void exportB2Body(py::module & pybox2dModule){




    py::enum_<b2BodyType>(pybox2dModule, "BodyType")
        .value("static", b2BodyType::b2_staticBody)
        .value("kinematic", b2BodyType::b2_kinematicBody)
        .value("dynamic", b2BodyType::b2_dynamicBody)
    ;


    typedef PyDefExtender<b2BodyDef> PyBodyDef;


    py::class_<PyBodyDef> body_def_py_cls(pybox2dModule,"BodyDef");
    add_user_data_to_def_api<PyBodyDef>(body_def_py_cls);
    body_def_py_cls
        .def(py::init<>())          
        .def_readwrite("btype", &PyBodyDef::type)
        .def_readwrite("type", &PyBodyDef::type)
        .def_readwrite("position", &PyBodyDef::position)
        .def_readwrite("angle", &PyBodyDef::angle)
        .def_readwrite("linear_velocity", &PyBodyDef::linearVelocity)
        .def_readwrite("angular_velocity", &PyBodyDef::angularVelocity)
        .def_readwrite("linear_damping", &PyBodyDef::linearDamping)
        .def_readwrite("angular_damping", &PyBodyDef::angularDamping)
        .def_readwrite("allow_sleep", &PyBodyDef::allowSleep)
        .def_readwrite("awake", &PyBodyDef::awake)
        .def_readwrite("fixed_rotation", &PyBodyDef::fixedRotation)
        .def_readwrite("bullet", &PyBodyDef::bullet)
        .def_readwrite("gravity_scale", &PyBodyDef::gravityScale)
    ;

    py::class_<b2Body, BodyHolder > body_py_cls(pybox2dModule,"Body");
    add_user_data_api<b2Body>(body_py_cls);
    add_get_next_api<b2Body>(body_py_cls);

    body_py_cls
        //.def(py::init<>())
        .def("create_fixture",
            [&](b2Body & body, b2Shape * shape, float density){
                return FixtureHolder(body.CreateFixture(shape, density));
            },
            py::arg("shape"),
            py::arg("density") = 1.0
        )
        .def("create_fixture",
            [&](b2Body & body, const PyDefExtender<b2FixtureDef> * def){
                return FixtureHolder(body.CreateFixture(def));
            },
            py::arg("fixtureDef")
        )
        .def("_create_fixture_from_fixture_def",
            [&](b2Body & body, const PyDefExtender<b2FixtureDef> * def){
                return FixtureHolder(body.CreateFixture(def));
            },
            py::arg("fixture_def")
        )
        .def("destroy_fixture",&b2Body::DestroyFixture,py::arg("fixture"))


        .def_property("transform", &b2Body::GetTransform,  [](b2Body * body, b2Transform * trafo){
            body->SetTransform(trafo->p, trafo->q.GetAngle());
         })
        .def_property_readonly("position", &b2Body::GetPosition)
        .def_property_readonly("angle", &b2Body::GetAngle)
        .def_property_readonly("world_center",&b2Body::GetWorldCenter)
        .def_property_readonly("local_center",&b2Body::GetLocalCenter)
        .def_property_readonly("mass",&b2Body::GetMass)
        .def_property_readonly("inertia",&b2Body::GetInertia)



        //.def_property_readonly("world",&b2Body::GetWorl)

        .def_property("linear_velocity",&b2Body::GetLinearVelocity,&b2Body::SetLinearVelocity)
        .def_property("angular_velocity",&b2Body::GetAngularVelocity,&b2Body::SetAngularVelocity)
        .def_property("mass_data",&b2Body::GetMassData,&b2Body::SetMassData)
        .def_property("bullet",&b2Body::IsBullet,&b2Body::SetBullet)
        .def_property("btype",&b2Body::GetType,&b2Body::SetType)
        .def_property("sleeping_allowed",&b2Body::IsSleepingAllowed,&b2Body::SetSleepingAllowed)
        .def_property("awake",&b2Body::IsAwake,&b2Body::SetAwake)
        #ifdef PYBOX2D_OLD_BOX2D
        .def_property("active",&b2Body::IsActive,&b2Body::SetActive)
        .def_property("enabled",&b2Body::IsActive,&b2Body::SetActive)
        #else
        .def_property("active",&b2Body::IsEnabled,&b2Body::SetEnabled)
        .def_property("enabled",&b2Body::IsEnabled,&b2Body::SetEnabled)
        #endif

        .def_property("fixed_rotation",&b2Body::IsFixedRotation,&b2Body::SetFixedRotation)
        .def_property("gravity_scale",&b2Body::GetGravityScale,&b2Body::SetGravityScale)
        .def_property("linear_damping",&b2Body::GetLinearDamping,&b2Body::SetLinearDamping)
        .def_property("angular_damping",&b2Body::GetAngularDamping,&b2Body::SetAngularDamping)


        .def("apply_force", &b2Body::ApplyForce, py::arg("force"), py::arg("point"), py::arg("wake"))
        .def("apply_force_to_center", &b2Body::ApplyForceToCenter, py::arg("force"), py::arg("wake"))
        .def("apply_torque", &b2Body::ApplyTorque, py::arg("torque"), py::arg("wake"))
        .def("apply_linear_impulse", &b2Body::ApplyLinearImpulse, py::arg("impulse"), py::arg("point"), py::arg("wake"))
        .def("apply_angular_impulse", &b2Body::ApplyAngularImpulse, py::arg("impulse"), py::arg("wake"))

        .def("reset_mass_data", &b2Body::ResetMassData)  
        .def("get_world_point", &b2Body::GetWorldPoint, py::arg("local_point"))
        .def("get_world_vector", &b2Body::GetWorldVector, py::arg("local_vector"))
        .def("get_local_point", &b2Body::GetLocalPoint, py::arg("world_point"))
        .def("get_local_vector", &b2Body::GetLocalVector, py::arg("world_vector"))
        .def("get_linear_velocity_from_world_point", &b2Body::GetLinearVelocityFromWorldPoint, py::arg("world_point"))
        .def("get_linear_velocity_from_local_point", &b2Body::GetLinearVelocityFromLocalPoint, py::arg("local_point"))

     
        // will be extended on the python side
        .def("_has_fixture_list",[]( b2Body & body){return body.GetFixtureList()!= nullptr;})
        .def("_get_fixture_list",[]( b2Body & body){return body.GetFixtureList();}, py::return_value_policy::reference_internal)
        .def("_has_joint_list",[]( b2Body & body){return body.GetJointList()!= nullptr;})
        .def("_get_joint_list",[]( b2Body & body){return body.GetJointList();}, py::return_value_policy::reference_internal)
        .def("_has_contact_list",[]( b2Body & body){return body.GetContactList()!= nullptr;})
        .def("_get_contact_list",[]( b2Body & body){return body.GetContactList();}, py::return_value_policy::reference_internal)
        .def("_get_world",[]( b2Body & body){return body.GetWorld();}, py::return_value_policy::reference_internal)
    
    ;


}
