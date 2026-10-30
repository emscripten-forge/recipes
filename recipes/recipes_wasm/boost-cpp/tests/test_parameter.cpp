// Functional test for boost-parameter, adapted from
// libs/parameter/test/tutorial.cpp


#include <boost/parameter/name.hpp>
#include <iostream>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

namespace geometry {

BOOST_PARAMETER_NAME(width)
BOOST_PARAMETER_NAME(height)

template <typename ArgumentPack>
int rectangle_area(ArgumentPack const& args)
{
    return args[_width] * args[_height];
}

} // namespace geometry

int main()
{
    using namespace geometry;

    // Order of the named arguments does not matter.
    CHECK(rectangle_area((_width = 3, _height = 7)) == 21);
    CHECK(rectangle_area((_height = 7, _width = 3)) == 21);
    CHECK(rectangle_area((_width = 10, _height = 10)) == 100);
    CHECK(rectangle_area((_height = 5, _width = 6)) == 30);

    // The pack is a single value that can be built once and reused.
    auto pack = (_width = 4, _height = 5);
    CHECK(rectangle_area(pack) == 20);
    CHECK(pack[_width] == 4 && pack[_height] == 5);

    std::cout << "boost-parameter OK\n";
    return 0;
}
