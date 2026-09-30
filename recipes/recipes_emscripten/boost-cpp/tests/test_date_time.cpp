// Functional test for boost-date_time, adapted from
// libs/date_time/test/gregorian/testdate.cpp (date arithmetic)

#include <boost/date_time/gregorian/gregorian.hpp>

int main()
{
    using namespace boost::gregorian;

    // days arithmetic: Jan 15 2024 + 16 days = Jan 31; - 1 day = Jan 30
    date d(2024, Jan, 15);
    date d2 = d + days(16);
    date d3 = d2 - days(1);
    if (d2 != date(2024, Jan, 31)) return 1;
    if (d3 != date(2024, Jan, 30)) return 1;

    // month iteration: 12 x months(1) from Jan 31 2024 lands on Jan 31 2025
    date m(2024, Jan, 31);
    int steps = 0;
    while (m.year() == 2024 && steps < 13)
    {
        m = m + months(1);
        ++steps;
    }
    if (steps != 12) return 1;
    if (m != date(2025, Jan, 31)) return 1;

    return 0;
}