#include <pybind11/pybind11.h>
#include <pybind11/numpy.h>
#include <pybind11/stl.h>
#include <iostream>
#include <array>


#include "../box2d_wrapper.hpp"
#include "extended_debug_draw_base.hxx"

namespace py = pybind11;




class PyB2Draw : public ExtendedDebugDrawBase {
public:

    typedef std::pair<float,float> P;
    typedef std::tuple<float,float,float> C;

    typedef std::tuple<float,float,float> FloatColor;
    typedef std::tuple<uint8_t,uint8_t,uint8_t> UInt8Color;


    /* Inherit the constructors */
    //using b2Draw::b2Draw;

    virtual ~PyB2Draw() {}

    PyB2Draw(
        const py::object object,
        const bool float_colors = true
    )
    :   m_object(object),
        m_float_colors(float_colors),
        m_scale(1),
        m_translate(0,0),
        m_flip_y(true)
    {
        this->resetBoundingBox();
    }

    b2Vec2 world_to_screen(const b2Vec2 & world_vec)const
    {   
        return b2Vec2(
            world_vec.x * m_scale + m_translate.x,
            world_vec.y * (m_flip_y ? -m_scale :  m_scale) + m_translate.y
        );
    }

    b2Vec2 screen_to_world(const b2Vec2 & screen_vec)const
    {   
        return b2Vec2(
            (screen_vec.x  - m_translate.x) / m_scale,
            (screen_vec.y  - m_translate.y) /  (m_flip_y ? -m_scale :  m_scale)
        );
    }

    float world_to_screen_scale(const float d) const
    {
        return m_scale * d;
    }


    float screen_to_world_scale(const float d) const
    {
        return d/m_scale;
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


    void BeginDraw(){
        m_object.attr("begin_draw")();
    }

    void EndDraw(){
        m_object.attr("end_draw")();
    }

    void DrawPolygon(const b2Vec2* vertices, int32 vertexCount, const b2Color& color)
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
            auto v = this->world_to_screen(vertices[i]);
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

    void DrawSolidPolygon(const b2Vec2* vertices, int32 vertexCount, const b2Color& color)
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
            auto v = this->world_to_screen(vertices[i]);
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

    void DrawPoint(const b2Vec2& center, float size, const b2Color& color) {
        py::object f = m_object.attr("draw_point");
        auto c = this->world_to_screen(center);
        if(m_float_colors)
        {
            f(P(c.x,c.y), size, make_float_color(color));
        }
        else
        {
            f(P(c.x,c.y), size, make_uint8_color(color));
        }
    }

    void DrawCircle(const b2Vec2& center, float radius, const b2Color& color) {
        py::object f = m_object.attr("draw_circle");
        auto c = this->world_to_screen(center);
        this->updateBoundingBox(b2Vec2(center.x+radius, center.y+radius));
        this->updateBoundingBox(b2Vec2(center.x-radius, center.y-radius));
        if(m_float_colors)
        {
            f(P(c.x,c.y), this->world_to_screen_scale(radius), make_float_color(color));
        }
        else
        {
            f(P(c.x,c.y), this->world_to_screen_scale(radius), make_uint8_color(color));
        }
    }

    void DrawSolidCircle(const b2Vec2& center, float radius, const b2Vec2& axis, const b2Color& color) {
        this->updateBoundingBox(b2Vec2(center.x+radius, center.y+radius));
        this->updateBoundingBox(b2Vec2(center.x-radius, center.y-radius));
        py::object f = m_object.attr("draw_solid_circle");
        auto c = this->world_to_screen(center);

        if(m_float_colors)
        {
            f(P(c.x,c.y),this->world_to_screen_scale(radius) ,P(axis.x,axis.y), make_float_color(color));
        }
        else
        {
            f(P(c.x,c.y),this->world_to_screen_scale(radius) ,P(axis.x,axis.y), make_uint8_color(color));
        }
    }
    #ifdef PYBOX2D_LIQUID_FUN
    void DrawParticles(const b2Vec2 *centers, float radius, const b2ParticleColor *colors, const int32 count) {
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
                auto ce = this->world_to_screen(centers[i]);
                this->updateBoundingBox(b2Vec2(ce.x + radius, ce.y +radius));
                this->updateBoundingBox(b2Vec2(ce.x - radius, ce.y -radius));

                ptrCenters[i*2 ]   = ce.x ;
                ptrCenters[i*2 +1] = ce.y ; 
                const b2ParticleColor c = colors[i];
                ptrColors[i*4 ]   = c.r;
                ptrColors[i*4 +1] = c.g;
                ptrColors[i*4 +2] = c.b;
                ptrColors[i*4 +3] = c.a;
            }
            f(npCenters,this->world_to_screen_scale(radius),npColors);
        }
        else{
            for(size_t i=0;  i<size_t(count); ++i){
                auto ce = this->world_to_screen(centers[i]);
                this->updateBoundingBox(b2Vec2(ce.x + radius, ce.y +radius));
                this->updateBoundingBox(b2Vec2(ce.x - radius, ce.y -radius));

                ptrCenters[i*2 ]   = ce.x ;
                ptrCenters[i*2 +1] = ce.y ; 
            }
            f(npCenters,this->world_to_screen_scale(radius));
        }
    }
    #endif

    void DrawSegment(const b2Vec2& p1, const b2Vec2& p2, const b2Color& color) {
        py::object f = m_object.attr("draw_segment");
        auto pp1 =  this->world_to_screen(p1);
        auto pp2 =  this->world_to_screen(p2);
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

    void DrawTransform(const b2Transform& xf) {
        py::object f = m_object.attr("draw_transform");
        f(b2Transform(
            this->world_to_screen(xf.p),
            xf.q
        ));
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

    py::object m_object;
    bool m_float_colors;

    std::array<float, 2> m_min_coord;
    std::array<float, 2> m_max_coord;
public:

    float m_scale;
    b2Vec2 m_translate;
    bool m_flip_y;
    #ifdef PYBOX2D_LIQUID_FUN

    #endif
};
