#include <pybind11/pybind11.h>
#include <pybind11/operators.h>
#include "box2d_wrapper.hpp"


// #include "proxies.hxx"
namespace py = pybind11;



#include "holder.hxx"


void exportContact(py::module & pybox2dModule){



    py::class_<b2ContactEdge>(pybox2dModule,"b2ContactEdge")
    ;

    py::class_<b2Contact, ContactHolder>(pybox2dModule,"b2Contact")
        .def_property_readonly("fixture_a",[](const b2Contact & c){return FixtureHolder(c.GetFixtureA());})
        .def_property_readonly("fixture_a",[](      b2Contact & c){return FixtureHolder(c.GetFixtureA());})
        .def_property_readonly("fixture_b",[](const b2Contact & c){return FixtureHolder(c.GetFixtureB());})
        .def_property_readonly("fixture_b",[](      b2Contact & c){return FixtureHolder(c.GetFixtureB());})
        .def_property_readonly("world_manifold",[](b2Contact * contact){
            b2WorldManifold * wm;
            contact->GetWorldManifold(wm);
            return WorldManifoldHolder(wm);
        })
        .def_property_readonly("world_manifold",[](const b2Contact * contact){
            b2WorldManifold * wm;
            contact->GetWorldManifold(wm);
            return WorldManifoldHolder(wm);
        })

        .def_property_readonly("manifold",[](b2Contact * contact){
            return ManifoldHolder(contact->GetManifold());
        })
        .def_property_readonly("manifold",[](const b2Contact * contact){
            return ManifoldHolder(contact->GetManifold());
        })


        // .def_property_readonly("getWorldManifold",
        //     &b2Contact::GetWorldManifold)
        // .def_property_readonly("worldManifold",   
        //     &b2Contact::GetWorldManifold)
    ;



}
