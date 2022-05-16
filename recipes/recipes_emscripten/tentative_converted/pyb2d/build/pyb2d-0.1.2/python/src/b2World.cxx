#include <pybind11/pybind11.h>

#include "box2d_wrapper.hpp"
#include "debug_draw/batch_debug_draw_caller.hxx"
#include "debug_draw/pyb2Draw.hxx"
#include "pyb2WorldCallbacks.hxx"
#include "extensions/pyworld.hxx"
#include "holder.hxx"


namespace py = pybind11;





void exportB2World(py::module & pybox2dModule){
    typedef PyWorld world_type;


    
    py::class_<world_type>(pybox2dModule,"_World")
        .def(py::init<const b2Vec2 & >(),py::arg("gravity"))


        .def(py::init([](world_type & instance,  std::pair<float,float>  arg){
            return new world_type(b2Vec2(arg.first,arg.second));
        }))


        .def("set_contact_listener", [](world_type & w, PyB2ContactListenerCaller * listener){
            w.SetContactListener(listener);
        },py::arg("listener"), py::keep_alive<1, 2>()) 

        .def("_set_destruction_listener", [](world_type & w, py::object listener_obj){
            w.set_py_destruction_listener(listener_obj);
        },py::arg("listener"), py::keep_alive<1, 2>()) 

        // .def("set_destruction_listener", [](world_type & w, PyB2DestructionListenerCaller * listener){
        //     w.SetDestructionListener(listener);
        // },py::arg("listener"))

        .def("set_contact_filter", [](world_type & w, PyB2ContactFilterCaller * listener){
            w.SetContactFilter(listener);
        },py::arg("listener"), py::keep_alive<1, 2>()) 
        .def("set_debug_draw", [](world_type & w, PyB2Draw * d){
            w.SetExtendedDebugDraw(d);
        },  py::keep_alive<1, 2>())
        .def("set_debug_draw", [](world_type & w, BatchDebugDrawCaller * d){
            w.SetExtendedDebugDraw(d);
        }
        ,py::arg("debugDraw"), py::keep_alive<1, 2>()
        )
        //.def("_createBodyCpp", &world_type::CreateBody, py::return_value_policy::reference_internal)


        .def("_create_body_cpp", [](world_type * self, const PyDefExtender<b2BodyDef> * def)
        {
            
            b2Body * body = self->CreateBody(def);
            set_user_data_from_def(def, body);
            return BodyHolder(body);

        },py::return_value_policy::copy)

        .def("destroy_body", 
            [](world_type & world, b2Body *  body){
                auto vud = get_user_data(body);
                if(vud!=0){
                    auto ud = static_cast<py::object *>(vud);
                    delete ud;
                    set_user_data(body, 0);
                }
                world.DestroyBody(body);
            }
            ,py::arg("body")
        )
        .def("create_joint", []
        (
            world_type * self, 
            const PyDefExtender<b2JointDef> * def
        )
        {
            b2Joint * joint = self->CreateJoint(def);
            set_user_data_from_def(def, joint);
            return JointHolder(joint);
        },py::arg("def"))
        .def("destroy_joint", 
            [](world_type & world, b2Joint *  joint){
                auto vud = get_user_data(joint);
                if(vud!=nullptr){
                    auto ud = static_cast<py::object *>(vud);
                    delete ud;
                    set_user_data(joint, 0);
                }
                world.DestroyJoint(joint);
            }
            ,py::arg("joint")
        )

        #ifdef PYBOX2D_LIQUID_FUN
        .def("create_particle_system",
            [](world_type * w, const b2ParticleSystemDef * def)
            {
                return ParticleSystemHolder(w->CreateParticleSystem(def));
            }
        )
        .def("destroy_particle_system",&world_type::DestroyParticleSystem)
        .def("calculateReasonableParticleIterations",&world_type::CalculateReasonableParticleIterations)
        #endif

        #ifdef PYBOX2D_LIQUID_FUN
        .def("step",[&]
            (world_type & self, float timeStep, 
            int32 velocityIterations, int32 positionIterations,
            int32 particleIterations){
                py::gil_scoped_release release;
                self.Step(timeStep, velocityIterations, positionIterations,particleIterations);
            },
            py::arg("time_step"),
            py::arg("velocity_iterations"),
            py::arg("position_iterations"),
            py::arg("particle_iterations") = 1
        )
        #else
        .def("step",[&]
            (world_type & self, float timeStep, 
            int32 velocityIterations, int32 positionIterations){

                self.Step(timeStep, velocityIterations, positionIterations);
            },
            py::arg("time_step"),
            py::arg("velocity_iterations"),
            py::arg("position_iterations")
        )
        #endif
        .def("clearForces",&world_type::ClearForces)
        .def("draw_debug_data",&world_type::ExtendedDebugDraw)
        .def("query_aabb", 
            [](const world_type & world, PyB2QueryCallbackCaller * cb, const b2AABB & aabb ){
                return world.QueryAABB(cb, aabb);
        })
        .def("ray_cast", 
            [](const world_type & world, PyB2RayCastCallbackCaller * cb, const b2Vec2 & pa,const b2Vec2 & pb ){
                return world.RayCast(cb, pa, pb);
        })
        
        .def("shift_origin",&world_type::ShiftOrigin)


        // py extended properties
        .def("_get_body_list", []( world_type & w){
            return  BodyHolder(w.GetBodyList());
        })
        .def("_get_joint_list", []( world_type & w){
            return  JointHolder(w.GetJointList());
        }, py::return_value_policy::reference_internal)
        .def("_get_contact_list", []( world_type & w){
            return  ContactHolder(w.GetContactList());
        }, py::return_value_policy::reference_internal)


        #ifdef PYBOX2D_LIQUID_FUN
        .def("_get_particleSystem_list", []( world_type & w){
            return  ParticleSystemHolder(w.GetParticleSystemList());
        })
        #endif

        // properties
        .def_property("allow_sleeping",&world_type::GetAllowSleeping,&world_type::SetAllowSleeping)
        .def_property("warm_starting",&world_type::GetWarmStarting,&world_type::SetWarmStarting)
        .def_property("continuous_physics",&world_type::GetContinuousPhysics,&world_type::SetContinuousPhysics)
        .def_property("sub_stepping",&world_type::GetSubStepping,&world_type::SetSubStepping)
        .def_property("gravity",&world_type::GetGravity, [](world_type & w,const b2Vec2 & g){w.SetGravity(g);})
        .def_property_readonly("locked",&world_type::IsLocked)
        .def_property("auto_clear_forces",&world_type::GetAutoClearForces,&world_type::SetAutoClearForces)


        .def_property_readonly("proxy_count",&world_type::GetProxyCount)
        .def_property_readonly("body_count",&world_type::GetBodyCount)
        .def_property_readonly("joint_count",&world_type::GetJointCount)
        .def_property_readonly("contact_count",&world_type::GetContactCount)
        .def_property_readonly("tree_height",&world_type::GetTreeHeight)
        .def_property_readonly("tree_balance",&world_type::GetTreeBalance)
        .def_property_readonly("tree_quality",&world_type::GetTreeQuality)
        .def_property_readonly("contact_manager",&world_type::GetContactManager)
        .def_property_readonly("profile",&world_type::GetProfile) 



        // SPECIAL VECTORIZED FUNCTONS
    ;

}

