
#include <pybind11/pybind11.h>            // Pybind11 import to define Python bindings
// #include <xtensor-python/pytensor.hpp>     // Numpy bindings

#include <pybind11/pybind11.h>

#include <pybind11/stl.h>
#include "box2d_wrapper.hpp"

#include <iostream>

namespace py = pybind11;

#include "holder.hxx"
#include "helper.hxx"
#include "numpy.hxx"


class PyB2Shape : public b2Shape {
public:
    /* Inherit the constructors */
    using b2Shape::b2Shape;


    /// Clone the concrete shape using the provided allocator.
    b2Shape* Clone(b2BlockAllocator* allocator) const {
        PYBIND11_OVERLOAD_PURE(
            b2Shape*,     /* Return type */
            b2Shape,      /* Parent class */
            Clone,        /* Name of function */
            allocator     /* Argument(s) */
        );
        return NULL;
    }

    int32 GetChildCount() const {
        PYBIND11_OVERLOAD_PURE(
            int32,     /* Return type */
            b2Shape,      /* Parent class */
            GetChildCount        /* Name of function */
        )
        return 0;
    }

    bool TestPoint(const b2Transform& xf, const b2Vec2& p) const{
        PYBIND11_OVERLOAD_PURE(
            bool,     /* Return type */
            b2Shape,      /* Parent class */
            TestPoint, /* Name of function */
            xf,p        /* Name of function */
        );
        return false;
    }

    void ComputeDistance(const b2Transform& xf, const b2Vec2& p, float* distance, b2Vec2* normal, int32 childIndex) const{
        PYBIND11_OVERLOAD_PURE(
            void,     /* Return type */
            b2Shape,      /* Parent class */
            ComputeDistance, /* Name of function */
            xf,p,distance,normal,childIndex      /* Name of function */
        );
    }

    bool RayCast(b2RayCastOutput* output, const b2RayCastInput& input,
                        const b2Transform& transform, int32 childIndex) const {

        PYBIND11_OVERLOAD_PURE(
            bool,     /* Return type */
            b2Shape,  /* Parent class */
            RayCast,  /* Name of function */
            output,input,transform,childIndex      /* Name of function */
        );
        return false;

    }

    void ComputeAABB(b2AABB* aabb, const b2Transform& xf, int32 childIndex) const {
        PYBIND11_OVERLOAD_PURE(
            void,     /* Return type */
            b2Shape,      /* Parent class */
            ComputeAABB, /* Name of function */
            aabb,xf,childIndex      /* Name of function */
        );
    }

    void ComputeMass(b2MassData* massData, float density) const {
        PYBIND11_OVERLOAD_PURE(
            void,     /* Return type */
            b2Shape,      /* Parent class */
            ComputeMass, /* Name of function */
            massData,density    /* Name of function */
        );
    }
};


template<class DT>
bool isType(const b2Shape * shape){
    return bool(dynamic_cast<const DT *>(shape));
}

template<class DT>
DT * asType(b2Shape * shape){
    auto res =  dynamic_cast<DT *>(shape);
    if(res == nullptr){
        throw std::runtime_error("invalid b2Shape dynamic cast");
    }
    return res;
}

void exportB2Shape(py::module & pybox2dModule){



    auto shapeCls = py::class_< b2Shape
    , ShapeHolder, PyB2Shape
    >(pybox2dModule,"Shape");
    shapeCls
        //.alias<b2Shape>()
        .def(py::init<>())
        .def_property_readonly("type",&b2Shape::GetType)
        .def_property_readonly("child_count",&b2Shape::GetChildCount)
        .def("test_point",&b2Shape::TestPoint,py::arg("xf"),py::arg("p"))
        .def_readwrite("radius", &b2Shape::m_radius)

    ;



    py::enum_<b2Shape::Type>(shapeCls, "ShapeType")
        .value("circle", b2Shape::Type::e_circle)
        .value("edge", b2Shape::Type::e_edge)
        .value("chain", b2Shape::Type::e_chain)
        .value("polygon", b2Shape::Type::e_polygon)
        .value("type_count", b2Shape::Type::e_typeCount)
    ;
    
    
    
    // derived shapes
    py::class_<b2CircleShape, Holder<b2CircleShape>, b2Shape>(pybox2dModule,"CircleShape")
        .def(py::init<>())
        // pos is deprecated
        .def_readwrite("pos", &b2CircleShape::m_p)
        .def_readwrite("position", &b2CircleShape::m_p)
    ;

    py::class_<b2EdgeShape, Holder<b2EdgeShape>,b2Shape>(pybox2dModule,"EdgeShape")
        .def(py::init<>())

        .def("set_one_sided",[](b2EdgeShape * s,const b2Vec2 & v0,const b2Vec2 & v1,const b2Vec2 & v2, const b2Vec2 & v3)
             {s->SetOneSided(v0, v1,v2, v3);},py::arg("v0"), py::arg("v1"),py::arg("v2"),py::arg("v3"))
        .def("set_two_sided",[](b2EdgeShape * s,const b2Vec2 & v1,const b2Vec2 & v2)
             {s->SetTwoSided(v1,v2);},py::arg("v1"),py::arg("v2")

        .def_property_readonly("one_sided", &b2EdgeShape::m_oneSided)
        .def("get_vertices", [](b2EdgeShape * self, bool include_adjacent){
            if(!include_adjacent || !self.m_oneSided)
            {
                auto vertices = make_numpy_array({2,2});
                auto ptr = vertices.data(0,0);
                ptr[0] = self.m_vertex1.x;
                ptr[1] = self.m_vertex1.y;
                ptr[2] = self.m_vertex2.x;
                ptr[3] = self.m_vertex2.y;
                return vertices;
            }
            else
            {
                auto vertices = make_numpy_array({4,2});
                ptr[0] = self.m_vertex0.x;
                ptr[1] = self.m_vertex0.y;
                ptr[2] = self.m_vertex1.x;
                ptr[3] = self.m_vertex1.y;
                ptr[4] = self.m_vertex2.x;
                ptr[5] = self.m_vertex2.y;
                ptr[6] = self.m_vertex3.x;
                ptr[7] = self.m_vertex3.y;
                return vertices;
            }
        }, py::arg("include_adjacent") = false)
    ;


    py::class_<b2ChainShape, Holder<b2ChainShape>,b2Shape >(pybox2dModule,"ChainShape")
        .def(py::init<>())
        .def("create_loop",[](b2ChainShape *s, const std::vector<b2Vec2> & verts ){
            s->CreateLoop(verts.data(), verts.size());
        })
       

        .def("create_chain", []( b2ChainShape *s, const np_verts_row_major & verts,
            const b2Vec2 & prevVertex, const b2Vec2 & nextVertex ){
                with_vertices(verts, [&](auto ptr, auto n_verts){
                    s->CreateChain(ptr, n_verts, prevVertex, nextVertex);
                });
            }
        )

        .def("create_chain",[](b2ChainShape *s, const std::vector<b2Vec2> & verts,
        const b2Vec2 & prevVertex, const b2Vec2 & nextVertex ){
            s->CreateChain(verts.data(), verts.size(), prevVertex, nextVertex);
        })


        .def_readonly("vertex_count", &b2ChainShape::m_count)
        .def_property_readonly("vertices",[](const b2ChainShape * shape){
            std::vector<b2Vec2> vec(shape->m_count);
            for(size_t i=0; i<vec.size(); ++i){
                vec[i]  = shape->m_vertices[i];
            }
            return vec;
        })
    ;

    py::class_<b2PolygonShape, Holder<b2PolygonShape>,b2Shape>(pybox2dModule,"PolygonShape")
        .def(py::init<>())
        .def("set_as_box",
            [&](
                b2PolygonShape & shape,
                float hx,float hy,
                float cx,float cy,
                float angle
            ){
                shape.SetAsBox(hx, hy, b2Vec2(cx, cy), angle);
            },
            py::arg("hx"),
            py::arg("hy"),
            py::arg("center_x") = 0,
            py::arg("center_y") = 0,
            py::arg("angle") = 0
        )
        #if 0
        .def("set", []( b2PolygonShape *s, const np_verts_row_major & verts){
                with_vertices(verts, [s](auto ptr, auto n_verts){
                    s->Set(ptr, n_verts);
                });
            }
        )
        .def("set", [](b2PolygonShape *s, const np_verts_dynamic & verts){
                with_vertices(verts, [s](auto ptr, auto n_verts){
                    s->Set(ptr, n_verts);
                });
            }
        )
        #endif
        .def("set",[](b2PolygonShape *s, const std::vector<b2Vec2> & verts ){
            s->Set(verts.data(), verts.size());
        })


        //.def_property_readonly("vertex_count", &b2PolygonShape::GetVertexCount)
        //.def("get_vertex", &b2PolygonShape::GetVertex,py::return_value_policy::reference_internal)
    ;

}

