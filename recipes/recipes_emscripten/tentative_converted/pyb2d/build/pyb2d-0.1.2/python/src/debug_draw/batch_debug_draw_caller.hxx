#ifndef PYBOX2D_BATCH_DEBUG_DRAW_CALLER
#define PYBOX2D_BATCH_DEBUG_DRAW_CALLER

#include "../numpy.hxx"

#include "extended_debug_draw_base.hxx"



class BatchDebugDrawCaller : public ExtendedDebugDrawBase {
public:

    typedef std::pair<float,float> P;
    typedef std::tuple<uint8_t,uint8_t,uint8_t> UInt8Color;



    virtual ~BatchDebugDrawCaller() {}

    BatchDebugDrawCaller(
        const py::object object
    )
    :   m_object(object),
        m_scale(1),
        m_translate(0,0),
        m_flip_y(true)
    {

    }

    void BeginDraw() override {
        m_object.attr("begin_draw")();
    }

    void EndDraw() override {
        this->trigger_callbacks();
        m_object.attr("end_draw")();
    }
    bool ReleaseGilWhileDebugDraw() override {
        return true;
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

   
    virtual void DrawPolygon(const b2Vec2* vertices, int32 vertexCount, const b2Color& color)
    {
        m_polygon_sizes.push_back(vertexCount);
        add_color(color, m_polygon_colors);
        for(std::size_t i=0; i<vertexCount; ++i)
        {
            const auto v = this->world_to_screen(vertices[i]);
            m_polygon_verts.push_back(v.x);
            m_polygon_verts.push_back(v.y);
        }
    }

    virtual void DrawSolidPolygon(const b2Vec2* vertices, int32 vertexCount, const b2Color& color)
    {
        m_solid_polygon_sizes.push_back(vertexCount);
        add_color(color, m_solid_polygon_colors);
        for(std::size_t i=0; i<vertexCount; ++i)
        {
            const auto v = this->world_to_screen(vertices[i]);
            m_solid_polygon_verts.push_back(v.x);
            m_solid_polygon_verts.push_back(v.y);
        }
    }

    virtual void DrawPoint(const b2Vec2& center, float size, const b2Color& color) {
       const auto c = this->world_to_screen(center);
       m_point_coords.push_back(c.x);
       m_point_coords.push_back(c.y);
       m_point_sizes.push_back(this->world_to_screen_scale(size));
       add_color(color, m_circle_colors);
    }

    virtual void DrawCircle(const b2Vec2& center, float radius, const b2Color& color) {
        const auto c = this->world_to_screen(center);
        m_circle_coords.push_back(c.x);
        m_circle_coords.push_back(c.y);
        m_circle_radii.push_back(this->world_to_screen_scale(radius));
        add_color(color, m_circle_colors);
    }

    virtual void DrawSolidCircle(const b2Vec2& center, float radius, const b2Vec2& axis, const b2Color& color) {
        const auto c = this->world_to_screen(center);
        m_solid_circle_coords.push_back(c.x);
        m_solid_circle_coords.push_back(c.y);
        m_solid_circle_radii.push_back(this->world_to_screen_scale(radius));
        m_solid_circle_axis.push_back(axis.x);
        m_solid_circle_axis.push_back(axis.y);
        add_color(color, m_solid_circle_colors);
    }


    virtual void DrawSegment(const b2Vec2& p1, const b2Vec2& p2, const b2Color& color) {
        const auto tp1 = this->world_to_screen(p1);
        const auto tp2 = this->world_to_screen(p2);
        m_segment_coords.push_back(tp1.x);
        m_segment_coords.push_back(tp1.y);
        m_segment_coords.push_back(tp2.x);
        m_segment_coords.push_back(tp2.y);
        add_color(color, m_segment_colors);
    }

    virtual void DrawTransform(const b2Transform& xf) {

    }

    #ifdef PYBOX2D_LIQUID_FUN
    virtual void DrawParticles(const b2Vec2 *centers, float radius, const b2ParticleColor *colors, const int32 count) {
        m_particle_systems_size.push_back(count);
        m_particle_systems_radii.push_back(this->world_to_screen_scale(radius));
        m_particle_systems_has_colors.push_back(colors != nullptr);

        for(int32 i=0; i<count; ++i)
        {
            const auto t = this->world_to_screen(centers[i]);
            m_particle_systems_centers.push_back(t.x);
            m_particle_systems_centers.push_back(t.y);
            if(colors != nullptr)
            {
                m_particle_systems_colors.push_back(colors[i].r);
                m_particle_systems_colors.push_back(colors[i].g);
                m_particle_systems_colors.push_back(colors[i].b);
                m_particle_systems_colors.push_back(colors[i].a);
            }
        }
    }
    #endif
    void trigger_callbacks(){


        #ifdef PYBOX2D_LIQUID_FUN
        //py::object f = m_object.attr("draw_particles");
        auto coord_offset = 0;
        auto color_offset = 0;
        for(auto psi=0; psi<m_particle_systems_radii.size(); ++psi)
        {
            const auto radius = m_particle_systems_radii[psi];
            const auto n_particels = m_particle_systems_size[psi];
            const auto has_colors = m_particle_systems_has_colors[psi];

            auto centers_ptr = m_particle_systems_centers.data() + coord_offset;

            if(!has_colors)
            {
                m_object.attr("draw_particles")(
                    np_view(centers_ptr, {n_particels, 2}),
                    radius
                );
            } 
            else
            {
                auto color_ptr = m_particle_systems_colors.data() + color_offset;
                m_object.attr("draw_particles")(
                    np_view(centers_ptr, {n_particels, 2}),
                    radius, 
                    np_view(color_ptr, {n_particels, 4})
                );
                color_offset += 4 * n_particels;
            }

            coord_offset += 2* n_particels;
        }
        #endif
        
        if(!m_solid_polygon_sizes.empty())
        {
            m_object.attr("draw_solid_polygons")(
                np_view(m_solid_polygon_verts.data(),  {m_solid_polygon_verts.size()/2, std::size_t(2)}),
                np_view(m_solid_polygon_sizes.data(),  {m_solid_polygon_sizes.size()}),
                np_view(m_solid_polygon_colors.data(), {m_solid_polygon_colors.size()/3, 3})
            );
        }
        if(!m_solid_circle_coords.empty())
        {
            m_object.attr("draw_solid_circles")(
                np_view(m_solid_circle_coords.data(), {m_solid_circle_coords.size()/2, std::size_t(2)}),
                np_view(m_solid_circle_radii.data(),  {m_solid_circle_radii.size()}),
                np_view(m_solid_circle_axis.data(),  {m_solid_circle_axis.size()/2, 2}),
                np_view(m_solid_circle_colors.data(), {m_solid_circle_colors.size()/3, 3})
            );
        }
        if(!m_polygon_sizes.empty())
        {
            m_object.attr("draw_polygons")(
                np_view(m_polygon_verts.data(),  {m_polygon_verts.size()/2, std::size_t(2)}),
                np_view(m_polygon_sizes.data(),  {m_polygon_sizes.size()}),
                np_view(m_polygon_colors.data(), {m_polygon_colors.size()/3, 3})
            );
        }
        if(!m_circle_coords.empty())
        {
            m_object.attr("draw_circles")(
                np_view(m_circle_coords.data(), {m_circle_coords.size()/2, std::size_t(2)}),
                np_view(m_circle_radii.data(),  {m_circle_radii.size()}),
                np_view(m_circle_colors.data(), {m_circle_colors.size()/3, 3})
            );
        }
        {
            py::object f = m_object.attr("draw_points");
        }
        if(!m_segment_coords.empty())
        {
            py::object f = m_object.attr("draw_segments");

            m_object.attr("draw_segments")(
                np_view(m_segment_coords.data(), {m_segment_coords.size()/4, std::size_t(2) ,std::size_t(2)}),
                np_view(m_segment_colors.data(), {m_segment_colors.size()/3, 3})
            );
        }


        this->reset();
    }
    void reset()
    {
        m_polygon_verts.resize(0);
        m_polygon_sizes.resize(0);
        m_polygon_colors.resize(0);
        m_solid_polygon_verts.resize(0);
        m_solid_polygon_sizes.resize(0);
        m_solid_circle_axis.resize(0);
        m_solid_polygon_colors.resize(0);
        m_circle_coords.resize(0);
        m_circle_radii.resize(0);
        m_circle_colors.resize(0);
        m_solid_circle_coords.resize(0);
        m_solid_circle_radii.resize(0);
        m_solid_circle_colors.resize(0);
        m_point_coords.resize(0);
        m_point_sizes.resize(0);
        m_point_colors.resize(0);
        m_segment_coords.resize(0);
        m_segment_colors.resize(0);
        #ifdef PYBOX2D_LIQUID_FUN
        m_particle_systems_centers.resize(0);
        m_particle_systems_size.resize(0);
        m_particle_systems_radii.resize(0);
        m_particle_systems_has_colors.resize(0);
        m_particle_systems_colors.resize(0);
        #endif
    }
    void add_color(const b2Color & color, std::vector<uint8_t> & color_array)
    {
        color_array.push_back(uint8_t(color.r * 255.0 + 0.5));
        color_array.push_back(uint8_t(color.g * 255.0 + 0.5));
        color_array.push_back(uint8_t(color.b * 255.0 + 0.5));
    }

    std::array<float, 2> m_min_coord;
    std::array<float, 2> m_max_coord;

    // polygon
    std::vector<float>          m_polygon_verts;
    std::vector<uint16_t>       m_polygon_sizes;
    std::vector<uint8_t>        m_polygon_colors;

    // solid polygon
    std::vector<float>          m_solid_polygon_verts;
    std::vector<uint16_t>       m_solid_polygon_sizes;
    std::vector<float>          m_solid_circle_axis;
    std::vector<uint8_t>        m_solid_polygon_colors;

    // circle
    std::vector<float>          m_circle_coords;
    std::vector<float>          m_circle_radii;
    std::vector<uint8_t>        m_circle_colors;

    // solid circle
    std::vector<float>          m_solid_circle_coords;
    std::vector<float>          m_solid_circle_radii;
    std::vector<uint8_t>        m_solid_circle_colors;  

    // points
    std::vector<float>          m_point_coords;
    std::vector<float>          m_point_sizes;
    std::vector<uint8_t>        m_point_colors;

    // segments
    std::vector<float>          m_segment_coords;
    std::vector<uint8_t>        m_segment_colors;

    #ifdef PYBOX2D_LIQUID_FUN

    // particles
    std::vector<float>          m_particle_systems_centers;
    std::vector<uint32_t>       m_particle_systems_size;
    std::vector<float>          m_particle_systems_radii;
    std::vector<uint8_t>        m_particle_systems_has_colors;
    std::vector<uint8_t>        m_particle_systems_colors;

    #endif


    py::object m_object;

public:
    float m_scale;
    b2Vec2 m_translate;
    bool m_flip_y;

};


#endif