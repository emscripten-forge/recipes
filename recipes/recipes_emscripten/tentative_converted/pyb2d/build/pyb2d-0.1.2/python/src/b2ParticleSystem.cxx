#include <pybind11/pybind11.h>
#include "box2d_wrapper.hpp"

#include "apis/user_data_api.hxx"
#include "holder.hxx"

namespace py = pybind11;



void exportB2ParticleSystem(py::module & pybox2dModule){



    py::class_<b2ParticleSystemDef>(pybox2dModule, "ParticleSystemDef")
        .def(py::init<>())

        .def_readwrite("strict_contact_check", &b2ParticleSystemDef::strictContactCheck)
        .def_readwrite("density", &b2ParticleSystemDef::density)
        .def_readwrite("gravity_scale", &b2ParticleSystemDef::gravityScale)
        .def_readwrite("radius", &b2ParticleSystemDef::radius)
        .def_readwrite("max_count", &b2ParticleSystemDef::maxCount)

        .def_readwrite("pressure_strength", &b2ParticleSystemDef::pressureStrength)
        .def_readwrite("damping_strength", &b2ParticleSystemDef::dampingStrength)
        .def_readwrite("elastic_strength", &b2ParticleSystemDef::elasticStrength)
        .def_readwrite("spring_strength", &b2ParticleSystemDef::springStrength)
        .def_readwrite("viscous_strength", &b2ParticleSystemDef::viscousStrength)
        .def_readwrite("surface_tension_pressure_strength", &b2ParticleSystemDef::surfaceTensionPressureStrength)
        .def_readwrite("surface_tension_normal_strength", &b2ParticleSystemDef::surfaceTensionNormalStrength)
        .def_readwrite("repulsive_strength", &b2ParticleSystemDef::repulsiveStrength)
        .def_readwrite("powder_strength", &b2ParticleSystemDef::powderStrength)
        .def_readwrite("ejection_strength", &b2ParticleSystemDef::ejectionStrength)
        .def_readwrite("static_pressure_strength", &b2ParticleSystemDef::staticPressureStrength)
        .def_readwrite("static_pressure_relaxation", &b2ParticleSystemDef::staticPressureRelaxation)
        .def_readwrite("static_pressure_iterations", &b2ParticleSystemDef::staticPressureIterations)
        .def_readwrite("color_mixing_strength", &b2ParticleSystemDef::colorMixingStrength)
        .def_readwrite("destroy_by_age", &b2ParticleSystemDef::destroyByAge)
        .def_readwrite("lifetime_granularity", &b2ParticleSystemDef::lifetimeGranularity)
    ;

    py::class_<b2ParticleSystem, ParticleSystemHolder >(pybox2dModule, "ParticleSystem")
        .def_property("radius", &b2ParticleSystem::GetRadius, &b2ParticleSystem::SetRadius)
        .def_property("damping", &b2ParticleSystem::GetDamping, &b2ParticleSystem::SetDamping)
        .def_property("density", &b2ParticleSystem::GetDensity, &b2ParticleSystem::SetDensity)
        .def("create_particle_group",
            [](b2ParticleSystem * self, const b2ParticleGroupDef & def)
            {
                return ParticleGroupHolder(self->CreateParticleGroup(def));
            }
        )
        .def("destroy_oldest_particle", &b2ParticleSystem::DestroyOldestParticle,
            py::arg("index"), py::arg("call_destruction_listener"))
        .def("destroy_particles_in_shape", 
        [](b2ParticleSystem * self,  const b2Shape& shape, const b2Transform& xf,bool callDestructionListener)
            {
                self->DestroyParticlesInShape(shape, xf, callDestructionListener);
            }, 
            py::arg("shape"), py::arg("xf"), py::arg("call_destruction_listener") = false
        )
        .def("create_particle",
        [](b2ParticleSystem * self,  PyDefExtender<b2ParticleDef>  & def)
            {
                self->CreateParticle(def);
            }, 
            py::arg("def")
        )
    ;

}


