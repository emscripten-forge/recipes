// Functional test for boost-poly_collection, adapted from
// libs/poly_collection/test/test_algorithm*.cpp

#include <boost/poly_collection/algorithm.hpp>
#include <boost/poly_collection/base_collection.hpp>
#include <iostream>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

struct shape
{
    virtual ~shape() = default;
    virtual int area() const = 0;
};

struct square : shape
{
    explicit square(int n) : s(n) {}
    int area() const override { return s * s; }
    int s;
};

struct circle : shape
{
    explicit circle(int r) : r(r) {}
    int area() const override { return 3 * r * r; }
    int r;
};

int main()
{
    using boost::poly_collection::base_collection;
    base_collection<shape> c;
    c.insert(square{3});
    c.insert(circle{2});
    c.insert(square{4});
    CHECK(c.size() == 3);

    int total = 0;
    for (const shape& s : c)
        total += s.area();
    CHECK(total == 37); // 9 + 12 + 16

    // 1.92 exposes the algorithm.hpp algorithms in boost::poly_collection;
    // explicit segment types disambiguate from std:: (ADL via allocator)
    CHECK((boost::poly_collection::all_of<square, circle>(c.begin(), c.end(),
        [](const shape& s) { return s.area() > 0; })));
    CHECK((boost::poly_collection::any_of<square, circle>(c.begin(), c.end(),
        [](const shape& s) { return s.area() > 15; })));
    CHECK((boost::poly_collection::none_of<square, circle>(c.begin(), c.end(),
        [](const shape& s) { return s.area() < 9; })));
    CHECK((boost::poly_collection::count_if<square, circle>(c.begin(), c.end(),
        [](const shape& s) { return s.area() >= 12; }) == 2));

    std::cout << "boost-poly_collection OK\n";
    return 0;
}
