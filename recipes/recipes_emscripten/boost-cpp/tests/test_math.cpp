// Functional test for boost-math, adapted from
// libs/math/test (test_tgamma_ratio.cpp exercises tgamma/lgamma)
#include <boost/math/special_functions/gamma.hpp>
#include <cmath>

int main()
{
    using boost::math::lgamma;
    using boost::math::tgamma;

    // tgamma(5) == 4! == 24
    double g = tgamma(5.0);
    if (std::abs(g - 24.0) > 1e-12) return 1;

    // lgamma(5) == log(24)
    double l = lgamma(5.0);
    if (std::abs(l - std::log(24.0)) > 1e-12) return 1;

    return 0;
}