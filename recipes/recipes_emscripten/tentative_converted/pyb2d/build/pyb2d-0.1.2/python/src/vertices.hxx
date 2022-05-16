#include <pybind11/pybind11.h>
#include "box2d_wrapper.hpp"

template<class T>
class Vertices
{
public:
    void clear()
    {
        m_points.clear();
        m_connect.clear();
    }
    
    void add_polygon(const b2Vec2 * points, const std::size_t num_points)
    {
        for(std::size_t i=0; i<num_points; ++i)
        {
            if(i==0)
            {
                m_connect.push_back(0);
            }
            else
            {
                m_connect.push_back(1);
            }

            std::array<float, 2> p;
            p[0] = points[i].x;
            p[1] = points[i].y;
            m_points.push_back(p);
        } 

        std::array<float, 2> p;
        p[0] = points[0].x;
        p[1] = points[0].y;
        m_points.push_back(p);
        m_connect.push_back(1);
    }   

private:
    std::vector<std::array<float, 2>> m_points;
    std::vector<uint8_t> m_connect;
};