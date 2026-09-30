// Functional test for boost-chrono, adapted from
// libs/chrono/test/duration/arithmetic_pass.cpp

#include <boost/chrono.hpp>

int main()
{
    using namespace boost::chrono;

    // duration arithmetic: 2h + 30min == 150min, 2h - 30min == 90min
    hours h(2);
    minutes m(30);
    minutes total = h + m;
    if (total.count() != 150) return 1;
    if ((h - m).count() != 90) return 1;

    // system_clock delta over a small loop must be non-negative
    system_clock::time_point t0 = system_clock::now();
    volatile long acc = 0;
    for (int i = 0; i < 10000; ++i) acc += i;
    (void)acc;
    system_clock::time_point t1 = system_clock::now();
    if ((t1 - t0).count() < 0) return 1;

    return 0;
}