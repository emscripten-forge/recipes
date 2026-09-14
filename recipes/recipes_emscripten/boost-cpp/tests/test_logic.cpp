// Functional test for boost-logic, adapted from
// libs/logic/test/tribool_test.cpp

#include <boost/logic/tribool.hpp>
#include <iostream>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

int main()
{
    using namespace boost::logic;

    tribool x(false);       // false
    tribool y(true);        // true
    tribool z(indeterminate); // indeterminate

    CHECK(static_cast<bool>(!x));
    CHECK(static_cast<bool>(x == false));
    CHECK(static_cast<bool>(y == true));
    CHECK(indeterminate(z == indeterminate));
    CHECK(indeterminate(z || !z));          // ind || !ind == ind
    CHECK(indeterminate(z && true));        // ind && true == ind
    CHECK(indeterminate(z || false));       // ind || false == ind
    CHECK(static_cast<bool>(x || true));    // false || true == true
    CHECK(static_cast<bool>(!(x && true))); // false && true == false
    CHECK(static_cast<bool>(y || z));       // true || ind == true
    CHECK(indeterminate(!(y && z)));        // !(true && ind) == ind

    z = true;                               // assignment to a definite value
    CHECK(static_cast<bool>(z == true));
    z = false;
    CHECK(static_cast<bool>(z == false));
    std::cout << "boost-logic OK\n";
    return 0;
}
