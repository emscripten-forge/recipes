// Functional test for boost-geometry, grounded in
// libs/geometry/test/algorithms/distance/distance_all.cpp usage patterns

#include <boost/geometry.hpp>
#include <iostream>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

namespace bg = boost::geometry;
typedef bg::model::point<double, 2, bg::cs::cartesian> pt;

int main()
{
    // distance: 3-4-5 triangle
    pt a(0, 0), b(3, 4);
    CHECK(bg::distance(a, b) == 5.0);

    // length of a polyline (two unit segments)
    bg::model::linestring<pt> line;
    line.push_back(pt(0, 0));
    line.push_back(pt(1, 0));
    line.push_back(pt(1, 1));
    CHECK(bg::length(line) == 2.0);

    // area of a 2x2 box
    bg::model::box<pt> box(pt(0, 0), pt(2, 2));
    CHECK(bg::area(box) == 4.0);

    // centroid of the box
    pt c;
    bg::centroid(box, c);
    CHECK(bg::get<0>(c) == 1.0 && bg::get<1>(c) == 1.0);

    std::cout << "boost-geometry OK\n";
    return 0;
}
