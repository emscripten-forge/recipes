// Functional test for boost-conversion , adapted from
// libs/conversion/test/cast_test.cpp

#include <boost/implicit_cast.hpp>
#include <boost/polymorphic_cast.hpp>
#include <iostream>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

struct Base { virtual char kind() { return 'B'; } };
struct Base2 { virtual char kind2() { return '2'; } };
struct Derived : Base, Base2 { virtual char kind() { return 'D'; } };

int main()
{
    Derived d;
    Base* b = &d;

    Derived* p = boost::polymorphic_downcast<Derived*>(b); // downcast
    CHECK(p == &d);
    CHECK(p->kind() == 'D');

    Derived* q = boost::polymorphic_cast<Derived*>(b);      // downcast, checks type
    CHECK(q == &d);

    Base2* b2 = boost::polymorphic_cast<Base2*>(b);         // crosscast
    CHECK(b2->kind2() == '2');

    Derived& r = boost::polymorphic_downcast<Derived&>(*b); // downcast by ref
    CHECK(r.kind() == 'D');

    long L = boost::implicit_cast<long>(42);
    CHECK(L == 42L);
    int i = boost::implicit_cast<int>(static_cast<short>(7));
    CHECK(i == 7);

    std::cout << "boost-conversion OK\n";
    return 0;
}
