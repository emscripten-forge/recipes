// Functional test for boost-core, adapted from
// libs/core/test/addressof_np_test.cpp and addressof_test2.cpp

#include <boost/core/addressof.hpp>
#include <iostream>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

struct trick
{
    int v;
    trick* operator&() { return 0; }  // nasty: hides the real address
};

int main()
{
    trick t;
    t.v = 7;

    // addressof must ignore the overloaded operator&
    trick* p = boost::addressof(t);
    CHECK(p != 0);
    CHECK(p->v == 7);
    CHECK(p != t.operator&());

    const trick& cref = t;
    const trick* cp = boost::addressof(cref);
    CHECK(cp == p);

    volatile trick& vref = t;
    volatile trick* vp = boost::addressof(vref);
    CHECK(vp == p);

    int arr[3] = { 1, 2, 3 };
    int (*parr)[3] = &arr;
    CHECK(boost::addressof(arr) == parr);

    int* x = 0;
    int const* cx = x;
    CHECK(boost::addressof(cx) == &cx);

    std::cout << "boost-core OK\n";
    return 0;
}
