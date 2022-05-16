#include <pybind11/pybind11.h>
#include <pybind11/numpy.h>
#include <pybind11/stl.h>
#include "box2d_wrapper.hpp"

#include <iostream>

#include <array>

namespace py = pybind11;




class RecordingB2Draw : public b2Draw {
public:

    typedef std::pair<float,float> P;
    typedef std::tuple<float,float,float> C;

    typedef std::tuple<float,float,float> FloatColor;
    typedef std::tuple<uint8_t,uint8_t,uint8_t> UInt8Color;


    /* Inherit the constructors */
    //using b2Draw::b2Draw;

    virtual ~RecordingB2Draw() {}

    RecordingB2Draw(
        const py::object object,
        const bool float_colors = true
    )
    :   m_object(object),
        m_float_colors(float_colors)
    {
        this->resetBoundingBox();
    }



    inline static UInt8Color make_uint8_color(const b2Color& color )
    {
        return UInt8Color(
            (color.r * 255.0f) + 0.5f,
            (color.g * 255.0f) + 0.5f,
            (color.b * 255.0f) + 0.5f
        );
    }

    inline static FloatColor make_float_color(const b2Color& color )
    {
        return FloatColor(
            color.r,
            color.g,
            color.b
        );
    }

    virtual void DrawPolygon(const b2Vec2* vertices, int32 vertexCount, const b2Color& color)
    {
        
        //typedef long unsigned int ShapeType;

        auto npVertices = py::array(py::buffer_info(
            nullptr,            /* Pointer to data (nullptr -> ask NumPy to allocate!) */
            sizeof(float),     /* Size of one item */
            py::format_descriptor<float>::value, /* Buffer format */
            2,          /* How many dimensions? */
            { size_t(vertexCount), size_t(2) },  /* Number of elements for each dimension */
            { 2*sizeof(float),sizeof(float)}  /* Strides for each dimension */
        ));

        float * ptr  = static_cast<float* >(npVertices.request().ptr);        
        for(size_t i=0;  i<size_t(vertexCount); ++i){
            auto v = vertices[i];
            this->updateBoundingBox(v);
            ptr[i*2 ]   = v.x;
            ptr[i*2 +1] = v.y;
        }
        py::object f = m_object.attr("draw_polygon");
        if(m_float_colors)
        {
            f(npVertices, make_float_color(color));
        }
        else
        {
            f(npVertices, make_uint8_color(color));
        }
    }

    virtual void DrawSolidPolygon(const b2Vec2* vertices, int32 vertexCount, const b2Color& color)
    {
        auto npVertices = py::array(py::buffer_info(
            nullptr,            /* Pointer to data (nullptr -> ask NumPy to allocate!) */
            sizeof(float),     /* Size of one item */
            py::format_descriptor<float>::value, /* Buffer format */
            2,          /* How many dimensions? */
            { size_t(vertexCount), size_t(2) },  /* Number of elements for each dimension */
            { 2*sizeof(float),sizeof(float)}  /* Strides for each dimension */
        ));

        float * ptr  = static_cast<float* >(npVertices.request().ptr);        
        for(size_t i=0;  i<size_t(vertexCount); ++i){
            auto v = vertices[i];
            this->updateBoundingBox(v);
            ptr[i*2 ]   = v.x;
            ptr[i*2 +1] = v.y;
        }
        py::object f = m_object.attr("draw_solid_polygon");
        if(m_float_colors)
        {
            f(npVertices, make_float_color(color));
        }
        else
        {
            f(npVertices, make_uint8_color(color));
        }
    }

    virtual void DrawCircle(const b2Vec2& center, float radius, const b2Color& color) {
        py::object f = m_object.attr("draw_circle");
        auto c =center;
        this->updateBoundingBox(center+radius);
        this->updateBoundingBox(center-radius);
        if(m_float_colors)
        {
            f(P(c.x,c.y), radius, make_float_color(color));
        }
        else
        {
            f(P(c.x,c.y), radius, make_uint8_color(color));
        }
    }

    virtual void DrawSolidCircle(const b2Vec2& center, float radius, const b2Vec2& axis, const b2Color& color) {
        this->updateBoundingBox(center+radius);
        this->updateBoundingBox(center-radius);
        py::object f = m_object.attr("draw_solid_circle");
        auto c = center;
        f(P(c.x,c.y),radius,P(axis.x,axis.y), C(color.r,color.g,color.b));

        if(m_float_colors)
        {
            f(P(c.x,c.y),radius,P(axis.x,axis.y), make_float_color(color));
        }
        else
        {
            f(P(c.x,c.y),radius,P(axis.x,axis.y), make_uint8_color(color));
        }
    }

    virtual void DrawParticles(const b2Vec2 *centers, float radius, const b2ParticleColor *colors, const int32 count) {
        py::object f = m_object.attr("draw_particles");

        auto npCenters = py::array(py::buffer_info(
            nullptr,            /* Pointer to data (nullptr -> ask NumPy to allocate!) */
            sizeof(float),     /* Size of one item */
            py::format_descriptor<float>::value, /* Buffer format */
            2,          /* How many dimensions? */
            { size_t(count), size_t(2) },  /* Number of elements for each dimension */
            { 2*sizeof(float),sizeof(float)}  /* Strides for each dimension */
        ));

        

        float * ptrCenters  = static_cast<float* >(npCenters.request().ptr);
        if(colors != nullptr){
            auto npColors = py::array(py::buffer_info(
                nullptr,            /* Pointer to data (nullptr -> ask NumPy to allocate!) */
                sizeof(uint8),     /* Size of one item */
                py::format_descriptor<uint8>::value, /* Buffer format */
                2,          /* How many dimensions? */
                { size_t(count), size_t(4) },  /* Number of elements for each dimension */
                { 4*sizeof(uint8),sizeof(uint8)}  /* Strides for each dimension */
            ));
            uint8 * ptrColors  = static_cast<uint8 * >(npColors.request().ptr);

            for(size_t i=0;  i<size_t(count); ++i){
                auto ce = centers[i];
                this->updateBoundingBox(ce+radius);
                this->updateBoundingBox(ce-radius);
                ptrCenters[i*2 ]   = ce.x ;
                ptrCenters[i*2 +1] = ce.y ; 
                const b2ParticleColor c = colors[i];
                ptrColors[i*4 ]   = c.r;
                ptrColors[i*4 +1] = c.g;
                ptrColors[i*4 +2] = c.b;
                ptrColors[i*4 +3] = c.a;
            }
            f(npCenters,radius,npColors);
        }
        else{
            for(size_t i=0;  i<size_t(count); ++i){
                auto ce = centers[i];
                this->updateBoundingBox(ce+radius);
                this->updateBoundingBox(ce-radius);

                ptrCenters[i*2 ]   = ce.x ;
                ptrCenters[i*2 +1] = ce.y ; 
            }
            f(npCenters,radius);
        }
    }

    virtual void DrawSegment(const b2Vec2& p1, const b2Vec2& p2, const b2Color& color) {
        py::object f = m_object.attr("draw_segment");
        auto pp1 =  p1;
        auto pp2 =  p2;
        this->updateBoundingBox(p1);
        this->updateBoundingBox(p2);
        if(m_float_colors)
        {
            f(P(pp1.x,pp1.y),P(pp2.x,pp2.y),make_float_color(color));
        }
        else
        {
            f(P(pp1.x,pp1.y),P(pp2.x,pp2.y),make_uint8_color(color));
        }
    }

    virtual void DrawTransform(const b2Transform& xf) {
       transform_ = xf;
       //py::object f = m_object.attr("DrawTransform");
       //f(xf);
    }

    void updateBoundingBox(const b2Vec2& p)
    {
        m_min_coord[0] = std::min(m_min_coord[0],p.x);
        m_min_coord[1] = std::min(m_min_coord[1],p.y);
        m_max_coord[0] = std::max(m_max_coord[0],p.x);
        m_max_coord[1] = std::max(m_max_coord[1],p.y);
    }
    void resetBoundingBox()
    {
        m_min_coord[0] = std::numeric_limits<float>::infinity();
        m_min_coord[1] = std::numeric_limits<float>::infinity();

        m_max_coord[0] = -1.0 * std::numeric_limits<float>::infinity();
        m_max_coord[1] = -1.0 * std::numeric_limits<float>::infinity();
    }
    b2AABB getBoundingBox()
    {
        b2AABB bb;
        bb.lowerBound = b2Vec2(m_min_coord[0],m_min_coord[1]);
        bb.upperBound = b2Vec2(m_max_coord[0],m_max_coord[1]);
        return bb;
    }

    b2Transform transform_;
    py::object m_object;
    bool m_float_colors;

    std::array<float, 2> m_min_coord;
    std::array<float, 2> m_max_coord;

    // segments
    std::map<uint32_t, std::vector< std::tuple<b2Vec2,b2Vec2> > >  m_segments;
    std::map<uint32_t, std::vector< std::tuple<b2Vec2,float> > >   m_circles;
    std::map<uint32_t, std::vector< std::tuple<b2Vec2,float> > >   m_solid_circles;

};
