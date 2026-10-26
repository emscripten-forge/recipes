// Functional test for boost-timer, adapted from
// libs/timer/test/cpu_timer_test.cpp


#include <boost/timer/timer.hpp>
#include <string>

int main()
{
    boost::timer::cpu_timer t;
    t.start();

    volatile long acc = 0;
    for (int i = 0; i < 100000; ++i) acc += i;
    (void)acc;

    t.stop();
    if (!t.is_stopped()) return 1;

    // format() must produce a non-empty timing report
    std::string s = t.format();
    if (s.empty()) return 1;

    return 0;
}