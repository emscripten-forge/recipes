// Functional test for boost-units, adapted from
// libs/units/example/temperature.cpp

#include <boost/units/quantity.hpp>
#include <boost/units/absolute.hpp>
#include <boost/units/systems/si.hpp>
#include <iostream>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

using namespace boost::units;

int main()
{
    // dimensional analysis: length / time -> velocity
    quantity<si::length> L(2.0 * si::meter);
    quantity<si::time> T(4.0 * si::second);
    CHECK(L.value() == 2.0);
    CHECK(T.value() == 4.0);

    auto v = L / T;                 // m/s
    CHECK(v.value() == 0.5);

    auto A = L * L;                 // m^2
    CHECK(A.value() == 4.0);

    // same-dimension addition
    quantity<si::length> L2 = L + 3.0 * si::meter;
    CHECK(L2.value() == 5.0);

    // absolute temperature (absolute.hpp): the difference of two absolute
    // quantities is a plain (relative) temperature difference
    quantity<absolute<si::temperature> > T1(300.0 * absolute<si::temperature>());
    quantity<absolute<si::temperature> > T2(273.15 * absolute<si::temperature>());
    auto dT = T1 - T2;
    CHECK(dT.value() > 26.8 && dT.value() < 26.9);

    std::cout << "boost-units OK\n";
    return 0;
}
