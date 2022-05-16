#include <pybind11/pybind11.h>

#include "box2d_wrapper.hpp"

namespace py = pybind11;

#include "holder.hxx"
#include "apis/user_data_api.hxx"
#include "apis/get_next_api.hxx"

class PyB2Joint : public b2Joint {
public:
    using b2Joint::b2Joint;
    virtual ~PyB2Joint() {}

    /// Get the anchor point on bodyA in world coordinates.
    virtual b2Vec2 GetAnchorA() const {
        PYBIND11_OVERLOAD_PURE(
            b2Vec2,       // Return type 
            b2Joint,      // Parent class 
            GetAnchorA    // Name of function 
        );
        return b2Vec2();
    }

    /// Get the anchor point on bodyB in world coordinates.
    virtual b2Vec2 GetAnchorB() const {
        PYBIND11_OVERLOAD_PURE(
            b2Vec2,       // Return type 
            b2Joint,      // Parent class 
            GetAnchorB    // Name of function 
        );
        return b2Vec2();
    }

    /// Get the reaction force on bodyB at the joint anchor in Newtons.
    virtual b2Vec2 GetReactionForce(float inv_dt) const {
        PYBIND11_OVERLOAD_PURE(
            b2Vec2,       // Return type 
            b2Joint,      // Parent class 
            GetReactionForce,    // Name of function 
            inv_dt
        )
        return b2Vec2();
    }

    /// Get the reaction torque on bodyB in N*m.
    virtual float GetReactionTorque(float inv_dt) const {
        PYBIND11_OVERLOAD_PURE(
            float,       // Return type 
            b2Joint,      // Parent class 
            GetReactionTorque,    // Name of function 
            inv_dt
        );
        return float();
    }

    // They are protected
    virtual void InitVelocityConstraints(const b2SolverData& data){
        PYBIND11_OVERLOAD_PURE(
            void,       // Return type 
            b2Joint,      // Parent class 
            InitVelocityConstraints,    // Name of function 
            data
        );
    }
    virtual void SolveVelocityConstraints(const b2SolverData& data){
        PYBIND11_OVERLOAD_PURE(
            void,       // Return type 
            b2Joint,      // Parent class 
            SolveVelocityConstraints,    // Name of function 
            data
        );
    }
    virtual bool SolvePositionConstraints(const b2SolverData& data){
        PYBIND11_OVERLOAD_PURE(
            bool,       // Return type 
            b2Joint,      // Parent class 
            SolvePositionConstraints,    // Name of function 
            data
        );
        return false;
    }
};


template<class DT>
bool isType(const b2Joint * shape){
    return bool(dynamic_cast<const DT *>(shape));
}

template<class DT>
DT * asType(b2Joint * shape){
    auto res =  dynamic_cast<DT *>(shape);
    if(res == nullptr){
        throw std::runtime_error("invalid b2Joint dynamic cast");
    }
    return res;
}

class PyB2JointDef : public b2JointDef{
public:
    using b2JointDef::b2JointDef;
};

void exportb2Joint(py::module & pybox2dModule){
    #ifndef PYBOX2D_OLD_BOX2D
    pybox2dModule.def("linear_stiffness", [](float frequency_hertz, float damping_ratio, b2Body* bodyA, b2Body* bodyB){
        float stiffness;
        float damping;
        b2LinearStiffness(stiffness, damping, frequency_hertz, damping_ratio, bodyA, bodyB);
        return std::make_tuple(stiffness, damping);
    },
        py::arg("frequency_hz"),
        py::arg("damping_ratio"),
        py::arg("body_a"),
        py::arg("body_b")
    );
    pybox2dModule.def("angular_stiffness", [](float frequency_hertz, float damping_ratio, b2Body* bodyA, b2Body* bodyB){
        float stiffness;
        float damping;
        b2AngularStiffness(stiffness, damping, frequency_hertz, damping_ratio, bodyA, bodyB);
        return std::make_tuple(stiffness, damping);
    },
        py::arg("frequency_hz"),
        py::arg("damping_ratio"),
        py::arg("body_a"),
        py::arg("body_b")
    );

    #endif

    py::enum_<b2JointType>(pybox2dModule, "JointType")
        .value("unknown_joint", b2JointType::e_unknownJoint)
        .value("revolute_joint", b2JointType::e_revoluteJoint)
        .value("prismatic_joint", b2JointType::e_prismaticJoint)
        .value("distance_joint", b2JointType::e_distanceJoint)
        .value("pulley_joint", b2JointType::e_pulleyJoint)
        .value("mouse_joint", b2JointType::e_mouseJoint)
        .value("gear_joint", b2JointType::e_gearJoint)
        .value("wheel_joint", b2JointType::e_wheelJoint)
        .value("weld_joint", b2JointType::e_weldJoint)
        .value("friction_joint", b2JointType::e_frictionJoint)
        //.value("rope_joint", b2JointType::e_ropeJoint)
        .value("motor_joint", b2JointType::e_motorJoint)
    ;

    // py::enum_<b2LimitState>(pybox2dModule, "b2LimitState")
    //     .value("inactive_limit", b2LimitState::e_inactiveLimit)
    //     .value("at_lower_limit", b2LimitState::e_atLowerLimit)
    //     .value("at_upper_limit", b2LimitState::e_atUpperLimit)
    //     .value("equal_limits", b2LimitState::e_equalLimits)
    // ;



    py::class_<b2JointEdge>(pybox2dModule, "JointEdge")
        // A lot to do
    ;

    auto jointCls = py::class_<b2Joint,JointHolder,  PyB2Joint>(pybox2dModule,"Joint");

    add_user_data_api<b2Joint>(jointCls);
    add_get_next_api<b2Joint>(jointCls);

    jointCls
        //.alias<b2Joint>()
       // .def(py::init<const b2JointDef* >())
        //
        .def_property_readonly("type",&b2Joint::GetType) 
        .def_property_readonly("body_a", [](b2Joint * self){
            return self->GetBodyA();
        })
        .def_property_readonly("body_b", [](b2Joint * self){
            return self->GetBodyB();
        })  
        .def_property_readonly("anchor_a",&b2Joint::GetAnchorA)
        .def_property_readonly("anchor_b",&b2Joint::GetAnchorB)     
        .def("get_reaction_force",&b2Joint::GetReactionForce, py::arg("iv_dt"))
        .def("get_reaction_torque",&b2Joint::GetReactionTorque, py::arg("iv_dt"))
    ;
   
   
    py::class_<b2DistanceJoint,DistanceJointHolder, b2Joint>(pybox2dModule,"DistanceJoint")
        .def_property("length",&b2DistanceJoint::GetLength, &b2DistanceJoint::SetLength)
        #ifdef PYBOX2D_OLD_BOX2D
        .def_property("frequency_hz",&b2DistanceJoint::GetFrequency, &b2DistanceJoint::SetFrequency)
        .def_property("damping_ratio",&b2DistanceJoint::GetDampingRatio, &b2DistanceJoint::SetDampingRatio)
        #else
        .def_property("stiffness",&b2DistanceJoint::GetStiffness, &b2DistanceJoint::SetStiffness)
        .def_property("damping",&b2DistanceJoint::GetDamping, &b2DistanceJoint::SetDamping)
        #endif
    ;  

    py::class_<b2FrictionJoint,Holder<b2FrictionJoint>, b2Joint>(pybox2dModule,"FrictionJoint")
        .def_property("max_force", &b2FrictionJoint::GetMaxForce,  &b2FrictionJoint::SetMaxForce)
        .def_property("max_torque",&b2FrictionJoint::GetMaxTorque, &b2FrictionJoint::SetMaxTorque)

    ;
    py::class_<b2GearJoint, Holder<b2GearJoint>, b2Joint >(pybox2dModule,"GearJoint")
        .def_property_readonly("joint_1", [](b2GearJoint * joint){
            return JointHolder(joint->GetJoint1());
        })
        .def_property_readonly("joint_2", [](b2GearJoint * joint){
            return JointHolder(joint->GetJoint2());
        })
    ;
    py::class_<b2PrismaticJoint , Holder<b2PrismaticJoint>, b2Joint >(pybox2dModule,"PrismaticJoint")
        .def_property_readonly("reference_angle", &b2PrismaticJoint::GetReferenceAngle)
        .def_property_readonly("joint_translation", &b2PrismaticJoint::GetJointTranslation)
        .def_property_readonly("joint_speed", &b2PrismaticJoint::GetJointSpeed)
        .def_property_readonly("is_limit_enabled", &b2PrismaticJoint::IsLimitEnabled)
        .def_property("enable_limit", &b2PrismaticJoint::IsLimitEnabled, &b2PrismaticJoint::EnableLimit)

        .def_property_readonly("lower_limit", &b2PrismaticJoint::GetLowerLimit)
        .def_property_readonly("upper_limit", &b2PrismaticJoint::GetUpperLimit)
        .def("set_limits", &b2PrismaticJoint::SetLimits)
        .def_property("enable_motor",&b2PrismaticJoint::IsMotorEnabled, &b2PrismaticJoint::EnableMotor)
        .def_property("motor_speed",&b2PrismaticJoint::GetMotorSpeed, &b2PrismaticJoint::SetMotorSpeed)
        .def_property("max_motor_force",&b2PrismaticJoint::GetMaxMotorForce, &b2PrismaticJoint::SetMaxMotorForce)

    ;
    py::class_<b2PulleyJoint, Holder<b2PulleyJoint>, b2Joint >(pybox2dModule,"PulleyJoint")
        .def_property_readonly("ground_anchor_a", &b2PulleyJoint::GetGroundAnchorA)
        .def_property_readonly("ground_anchor_b", &b2PulleyJoint::GetGroundAnchorB)
        .def_property_readonly("length_a", &b2PulleyJoint::GetLengthA)
        .def_property_readonly("length_b", &b2PulleyJoint::GetLengthB)
        .def_property_readonly("ratio", &b2PulleyJoint::GetRatio)
        .def_property_readonly("current_length_a", &b2PulleyJoint::GetCurrentLengthA)
        .def_property_readonly("current_length_b", &b2PulleyJoint::GetCurrentLengthB)
        .def("shift_origin", &b2PulleyJoint::ShiftOrigin)
    ;
    py::class_<b2RevoluteJoint, Holder<b2RevoluteJoint>, b2Joint >(pybox2dModule,"RevoluteJoint")
        .def_property_readonly("reference_angle", &b2RevoluteJoint::GetReferenceAngle)
        .def_property_readonly("joint_angle", &b2RevoluteJoint::GetJointAngle)
        .def_property_readonly("joint_speed", &b2RevoluteJoint::GetJointSpeed)
        .def_property("enable_limit", &b2RevoluteJoint::IsLimitEnabled, &b2RevoluteJoint::EnableLimit)
        .def_property_readonly("lower_limit", &b2RevoluteJoint::GetLowerLimit)
        .def_property_readonly("upper_limit", &b2RevoluteJoint::GetUpperLimit)
        .def("set_limits", &b2RevoluteJoint::SetLimits)
        .def_property("enable_motor",&b2RevoluteJoint::IsMotorEnabled, &b2RevoluteJoint::EnableMotor)
        .def_property("motor_speed",&b2RevoluteJoint::GetMotorSpeed, &b2RevoluteJoint::SetMotorSpeed)
        .def_property("max_motor_torque",&b2RevoluteJoint::GetMaxMotorTorque, &b2RevoluteJoint::SetMaxMotorTorque)
        .def("get_motor_torque",&b2RevoluteJoint::GetMotorTorque, py::arg("iv_dt"))
    ;

    py::class_<b2WeldJoint, Holder<b2WeldJoint>, b2Joint >(pybox2dModule,"WeldJoint")
        .def_property_readonly("reference_angle", &b2WeldJoint::GetReferenceAngle)
        #ifdef PYBOX2D_OLD_BOX2D
        .def_property("frequency_hz",&b2WeldJoint::GetFrequency, &b2WeldJoint::SetFrequency)
        .def_property("damping_ratio",&b2WeldJoint::GetDampingRatio, &b2WeldJoint::SetDampingRatio)
        #else
        .def_property("stiffness",&b2WeldJoint::GetStiffness, &b2WeldJoint::SetStiffness)
        .def_property("damping",&b2WeldJoint::GetDamping, &b2WeldJoint::SetDamping)
        #endif
    ;

    py::class_<b2WheelJoint, Holder<b2WheelJoint>, b2Joint >(pybox2dModule,"WheelJoint")
        .def_property_readonly("joint_translation", &b2WheelJoint::GetJointTranslation)



        #ifdef PYBOX2D_OLD_BOX2D
        .def_property_readonly("joint_speed", &b2WheelJoint::GetJointSpeed)
        #else
        .def_property_readonly("joint_linear_speed", &b2WheelJoint::GetJointLinearSpeed)
        .def_property_readonly("joint_angle", &b2WheelJoint::GetJointAngle)
        .def_property_readonly("joint_angular_speed", &b2WheelJoint::GetJointAngularSpeed)
        .def_property("enable_limit", &b2WheelJoint::IsLimitEnabled, &b2WheelJoint::EnableLimit)
        .def_property_readonly("lower_limit", &b2WheelJoint::GetLowerLimit)
        .def_property_readonly("upper_limit", &b2WheelJoint::GetUpperLimit)
        .def("set_limits", &b2WheelJoint::SetLimits)
        #endif


        .def_property("enable_motor",&b2WheelJoint::IsMotorEnabled, &b2WheelJoint::EnableMotor)
        .def_property("motor_speed",&b2WheelJoint::GetMotorSpeed, &b2WheelJoint::SetMotorSpeed)
        .def_property("max_motor_torque",&b2WheelJoint::GetMaxMotorTorque, &b2WheelJoint::SetMaxMotorTorque)
        .def("get_motor_torque",&b2WheelJoint::GetMotorTorque, py::arg("iv_dt"))
        #ifdef PYBOX2D_OLD_BOX2D
        .def_property("spring_frequency_hz",&b2WheelJoint::GetSpringFrequencyHz, &b2WheelJoint::SetSpringFrequencyHz)
        .def_property("spring_damping_ratio",&b2WheelJoint::GetSpringDampingRatio, &b2WheelJoint::SetSpringDampingRatio)
        // for generalization purposes we add these methods also under these names
        .def_property("frequency_hz",&b2WheelJoint::GetSpringFrequencyHz, &b2WheelJoint::SetSpringFrequencyHz)
        .def_property("damping_ratio",&b2WheelJoint::GetSpringDampingRatio, &b2WheelJoint::SetSpringDampingRatio)
        #else
        .def_property("stiffness",&b2WheelJoint::GetStiffness, &b2WheelJoint::SetStiffness)
        .def_property("damping",&b2WheelJoint::GetDamping, &b2WheelJoint::SetDamping)
        #endif



    ;
    py::class_<b2MouseJoint, Holder<b2MouseJoint>, b2Joint 
    >(pybox2dModule,"MouseJoint")
        .def_property("max_force",&b2MouseJoint::GetMaxForce, &b2MouseJoint::SetMaxForce)
        .def_property("target", &b2MouseJoint::GetTarget, &b2MouseJoint::SetTarget)
        #ifdef PYBOX2D_OLD_BOX2D
        .def_property("frequency_hz",&b2MouseJoint::GetFrequency, &b2MouseJoint::SetFrequency)
        .def_property("damping_ratio",&b2MouseJoint::GetDampingRatio, &b2MouseJoint::SetDampingRatio)
        #else
        .def_property("stiffness",&b2MouseJoint::GetStiffness, &b2MouseJoint::SetStiffness)
        .def_property("damping",&b2MouseJoint::GetDamping, &b2MouseJoint::SetDamping)
        #endif
    ;
   
    // py::class_<b2RopeJoint
    //     , Holder<b2RopeJoint>, b2Joint 
    // >(pybox2dModule,"RopeJoint")
    ;
}

