// Functional test for boost-qvm, adapted from
// libs/qvm/test/div_eq_qs_test.cpp and vec_operations usage

#include <boost/qvm.hpp>
#include <iostream>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

int main()
{
    using namespace boost::qvm;

    vec<double, 3> a = {1.0, 2.0, 3.0};
    vec<double, 3> b = {4.0, 5.0, 6.0};

    CHECK(mag_sqr(a) == 14.0);          // 1 + 4 + 9
    CHECK(dot(a, b) == 32.0);           // 4 + 10 + 18

    vec<double, 3> s = a + b;
    CHECK(s.a[0] == 5.0 && s.a[1] == 7.0 && s.a[2] == 9.0);

    vec<double, 3> c = cross(a, b);     // perpendicular to both operands
    CHECK(dot(c, a) == 0.0 && dot(c, b) == 0.0);
    CHECK(mag_sqr(c) == 54.0);          // |(1,2,3)x(4,5,6)|^2

    a += b;
    CHECK(a == s);                      // element-wise equality operator
    CHECK(a.a[0] + a.a[1] + a.a[2] == 21.0);

    std::cout << "boost-qvm OK\n";
    return 0;
}
