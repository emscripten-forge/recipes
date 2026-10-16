// Functional test for boost-describe, adapted from
// libs/describe/example/enum_to_string.cpp (describe_enumerators +
// mp_for_each) and libs/describe/test/enumerators_test.cpp.
#include <boost/describe.hpp>
#include <boost/mp11.hpp>
#include <iostream>
#include <string>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

enum E
{
    v1 = 3,
    v2,
    v3 = 11
};

BOOST_DESCRIBE_ENUM(E, v1, v2, v3)

struct point
{
    int x;
    int y;
    double w;
};

BOOST_DESCRIBE_STRUCT(point, (), (x, y, w))

template<class E2> std::string enum_to_string(E2 e)
{
    std::string r = "(unnamed)";
    boost::mp11::mp_for_each< boost::describe::describe_enumerators<E2> >([&](auto D) {
        if (e == D.value) r = D.name;
    });
    return r;
}

int main()
{
    CHECK(enum_to_string(v1) == "v1");
    CHECK(enum_to_string(v2) == "v2");
    CHECK(enum_to_string(v3) == "v3");
    CHECK(enum_to_string(E(0)) == "(unnamed)");

    // 3 public members were described
    using members = boost::describe::describe_members<point, boost::describe::mod_public>;
    CHECK(boost::mp11::mp_size<members>::value == 3);

    point p { 1, 2, 3.5 };
    int y_val = 0;
    bool saw_y = false;
    boost::mp11::mp_for_each<members>([&](auto D) {
        if (std::string(D.name) == "y") { y_val = p.*D.pointer; saw_y = true; }
    });
    CHECK(saw_y);
    CHECK(y_val == 2);

    std::cout << "boost-describe OK\n";
    return 0;
}
