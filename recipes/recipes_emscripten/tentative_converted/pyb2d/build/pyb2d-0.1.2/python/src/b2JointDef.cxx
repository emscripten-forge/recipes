#include <pybind11/pybind11.h>

#include "box2d_wrapper.hpp"
#include "apis/user_data_api.hxx"
#include "holder.hxx"

namespace py = pybind11;




void exportb2JointDef(py::module & pybox2dModule){

    typedef PyDefExtender<b2JointDef> PyJointDef;
    py::class_<PyJointDef> jdClass(pybox2dModule, "JointDef");
    add_user_data_to_def_api<PyJointDef>(jdClass);
    jdClass
        .def(py::init<>())
        .def_readwrite("jtype", &PyJointDef::type)
        .def_readwrite("collide_connected", &PyJointDef::collideConnected)
        .def_property("body_a", 
            [](PyJointDef * self){
                BodyHolder(self->bodyA);
            }, 
            [](PyJointDef * self, b2Body * bodyA){
                self->bodyA = bodyA;
            }
        )
        .def_property("body_b", 
            [](PyJointDef * self){
                BodyHolder(self->bodyB);
            }, 
            [](PyJointDef * self, b2Body * bodyB){
                self->bodyB = bodyB;
            }
        )
    ;
   

    typedef PyDefExtender<b2DistanceJointDef> PyDistanceJointDef;
    py::class_<PyDistanceJointDef> b2DistanceJointDefCls(pybox2dModule,"DistanceJointDef",jdClass);
    //add_user_data_to_def_api<b2DistanceJointDef>(b2DistanceJointDefCls);
    b2DistanceJointDefCls
        .def(py::init<>())
        .def_readwrite("local_anchor_a",&PyDistanceJointDef::localAnchorA)
        .def_readwrite("local_anchor_b",&PyDistanceJointDef::localAnchorB)
        .def_readwrite("length", &PyDistanceJointDef::length)
        #ifdef PYBOX2D_OLD_BOX2D
        .def_readwrite("frequency_hz", &PyDistanceJointDef::frequencyHz)
        .def_readwrite("damping_ratio", &PyDistanceJointDef::dampingRatio)
        #else
        .def_readwrite("min_length", &PyDistanceJointDef::minLength)
        .def_readwrite("max_length", &PyDistanceJointDef::maxLength)
        .def_readwrite("stiffness", &PyDistanceJointDef::stiffness)
        .def_readwrite("damping", &PyDistanceJointDef::damping)
        #endif
    ;
    
    typedef PyDefExtender<b2FrictionJointDef> PyFrictionJointDef;
    py::class_<PyFrictionJointDef>(pybox2dModule,"FrictionJointDef",jdClass)
        .def(py::init<>())
        .def_readwrite("local_anchor_a",&PyFrictionJointDef::localAnchorA)
        .def_readwrite("local_anchor_b",&PyFrictionJointDef::localAnchorB)
        .def_readwrite("max_force", &PyFrictionJointDef::maxForce)
        .def_readwrite("max_torque", &PyFrictionJointDef::maxTorque)
    ;

    typedef PyDefExtender<b2GearJointDef> PyGearJointDef;
    py::class_<PyGearJointDef>(pybox2dModule,"GearJointDef",jdClass)
        .def(py::init<>())
        .def_readwrite("joint_1",&PyGearJointDef::joint1)
        .def_readwrite("joint_2",&PyGearJointDef::joint2)
        .def_readwrite("ratio", &PyGearJointDef::ratio)
    ;


    typedef PyDefExtender<b2PrismaticJointDef> PyPrismaticJointDef;
    py::class_<PyPrismaticJointDef>(pybox2dModule,"PrismaticJointDef",jdClass)
        .def(py::init<>())
        .def_readwrite("local_anchor_a",&PyPrismaticJointDef::localAnchorA)
        .def_readwrite("local_anchor_b",&PyPrismaticJointDef::localAnchorB)
        .def_readwrite("local_axis_a", &PyPrismaticJointDef::localAxisA)
        .def_readwrite("reference_angle", &PyPrismaticJointDef::referenceAngle)
        .def_readwrite("enable_limit", &PyPrismaticJointDef::enableLimit)
        .def_readwrite("lower_translation", &PyPrismaticJointDef::lowerTranslation)
        .def_readwrite("upper_translation", &PyPrismaticJointDef::upperTranslation)
        .def_readwrite("enable_motor", &PyPrismaticJointDef::enableMotor)
        .def_readwrite("max_motor_force", &PyPrismaticJointDef::maxMotorForce)
        .def_readwrite("motor_speed", &PyPrismaticJointDef::motorSpeed)
    ;


    typedef PyDefExtender<b2PulleyJointDef> PyPulleyJointDef;
    py::class_<PyPulleyJointDef>(pybox2dModule,"PulleyJointDef",jdClass)
        .def(py::init<>())
        .def_readwrite("local_anchor_a",&PyPulleyJointDef::localAnchorA)
        .def_readwrite("local_anchor_b",&PyPulleyJointDef::localAnchorB)
        .def_readwrite("ground_anchor_a", &PyPulleyJointDef::groundAnchorA)
        .def_readwrite("ground_anchor_b", &PyPulleyJointDef::groundAnchorB)
        .def_readwrite("length_a", &PyPulleyJointDef::lengthA)
        .def_readwrite("length_b", &PyPulleyJointDef::lengthB)
        .def_readwrite("ratio", &PyPulleyJointDef::ratio)
        .def_readwrite("collide_connected", &PyPulleyJointDef::collideConnected)
    ;


    typedef PyDefExtender<b2RevoluteJointDef> PyRevoluteJointDef;
    py::class_<PyRevoluteJointDef>(pybox2dModule,"RevoluteJointDef",jdClass)
        .def(py::init<>())
        .def_readwrite("local_anchor_a",&PyRevoluteJointDef::localAnchorA)
        .def_readwrite("local_anchor_b",&PyRevoluteJointDef::localAnchorB)
        .def_readwrite("reference_angle", &PyRevoluteJointDef::referenceAngle)
        .def_readwrite("lower_angle", &PyRevoluteJointDef::lowerAngle)
        .def_readwrite("upper_angle", &PyRevoluteJointDef::upperAngle)
        .def_readwrite("max_motor_torque", &PyRevoluteJointDef::maxMotorTorque)
        .def_readwrite("motor_speed", &PyRevoluteJointDef::motorSpeed)
        .def_readwrite("enable_limit", &PyRevoluteJointDef::enableLimit)
        .def_readwrite("enable_motor", &PyRevoluteJointDef::enableMotor)
        .def_readwrite("collide_connected", &PyRevoluteJointDef::collideConnected)
    ;


    // typedef PyDefExtender<b2RopeJointDef> PyRopeJointDef;
    // py::class_<PyRopeJointDef>(pybox2dModule,"RopeJointDef",jdClass)
    //     .def(py::init<>())
    //     .def_readwrite("local_anchor_a",&PyRopeJointDef::localAnchorA)
    //     .def_readwrite("local_anchor_b",&PyRopeJointDef::localAnchorB)
    //     .def_readwrite("max_length", &PyRopeJointDef::maxLength)
    // ;


    typedef PyDefExtender<b2WeldJointDef> Py2WeldJointDef;
    py::class_<Py2WeldJointDef>(pybox2dModule,"WeldJointDef",jdClass)
        .def(py::init<>())
        .def_readwrite("local_anchor_a",&Py2WeldJointDef::localAnchorA)
        .def_readwrite("local_anchor_b",&Py2WeldJointDef::localAnchorB)
        .def_readwrite("reference_angle", &Py2WeldJointDef::referenceAngle)
        #ifdef PYBOX2D_OLD_BOX2D
        .def_readwrite("frequency_hz", &Py2WeldJointDef::frequencyHz)
        .def_readwrite("damping_ratio", &Py2WeldJointDef::dampingRatio)
        #else
        .def_readwrite("stiffness", &Py2WeldJointDef::stiffness)
        .def_readwrite("damping", &Py2WeldJointDef::damping)
        #endif
    ;


    typedef PyDefExtender<b2WheelJointDef> PyWheelJointDef;
    py::class_<PyWheelJointDef>(pybox2dModule,"WheelJointDef",jdClass)
        .def(py::init<>())
        .def_readwrite("local_anchor_a",&PyWheelJointDef::localAnchorA)
        .def_readwrite("local_anchor_b",&PyWheelJointDef::localAnchorB)
        .def_readwrite("local_axis_a", &PyWheelJointDef::localAxisA)
        .def_readwrite("enable_motor", &PyWheelJointDef::enableMotor)
        .def_readwrite("max_motor_torque", &PyWheelJointDef::maxMotorTorque)
        .def_readwrite("motor_speed", &PyWheelJointDef::motorSpeed)
        #ifdef PYBOX2D_OLD_BOX2D
        .def_readwrite("frequency_hz", &PyWheelJointDef::frequencyHz)
        .def_readwrite("damping_ratio", &PyWheelJointDef::dampingRatio)
        #else
        .def_readwrite("stiffness", &PyWheelJointDef::stiffness)
        .def_readwrite("damping", &PyWheelJointDef::damping)
        #endif
    ;

    typedef PyDefExtender<b2MouseJointDef> PyMouseJointDef;
    py::class_<PyMouseJointDef>(pybox2dModule,"MouseJointDef",jdClass)
        .def(py::init<>())
        .def_readwrite("target", &PyMouseJointDef::target)
        .def_readwrite("max_force", &PyMouseJointDef::maxForce)
        #ifdef PYBOX2D_OLD_BOX2D
        .def_readwrite("frequency_hz", &PyMouseJointDef::frequencyHz)
        .def_readwrite("damping_ratio", &PyMouseJointDef::dampingRatio)
        #else
        .def_readwrite("stiffness", &PyMouseJointDef::stiffness)
        .def_readwrite("damping", &PyMouseJointDef::damping)
        #endif
    ;

}

