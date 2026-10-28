// Functional test for boost-polygon, adapted from
// libs/polygon/test/polygon_rectangle_test.cpp

#include <boost/polygon/polygon.hpp>
#include <iostream>
#include <vector>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

using namespace boost::polygon;
typedef rectangle_data<int> rectangle_type;
typedef point_data<int> point_type;

template <typename interval_type>
bool interval_equal(const interval_type& i1, const interval_type& i2)
{
    return get(i1, LOW) == get(i2, LOW) && get(i1, HIGH) == get(i2, HIGH);
}

int main()
{
    // Rectangle concept: construct, scale up/down
    rectangle_type r = construct<rectangle_type>(-1, -1, 1, 1);
    scale_up(r, 2);
    CHECK(interval_equal(horizontal(r), horizontal(construct<rectangle_type>(-2, -2, 2, 2))));
    CHECK(interval_equal(vertical(r), vertical(construct<rectangle_type>(-2, -2, 2, 2))));
    scale_down(r, 2);
    CHECK(get(horizontal(r), LOW) == -1);
    CHECK(get(horizontal(r), HIGH) == 1);
    CHECK(get(vertical(r), LOW) == -1);
    CHECK(get(vertical(r), HIGH) == 1);

    // Polygon concept: build a 4x4 square, compute its area
    std::vector<point_type> pts;
    pts.push_back(point_type(0, 0));
    pts.push_back(point_type(0, 4));
    pts.push_back(point_type(4, 4));
    pts.push_back(point_type(4, 0));
    polygon_data<int> poly;
    set_points(poly, pts.begin(), pts.end());
    CHECK(area(poly) == 16);

    std::cout << "boost-polygon OK\n";
    return 0;
}
