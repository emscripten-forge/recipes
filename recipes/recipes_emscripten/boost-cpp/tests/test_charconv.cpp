// Functional test for boost-charconv, adapted from
// libs/charconv/test/roundtrip.cpp

#include <boost/charconv.hpp>
#include <system_error>

int main()
{
    double const values[] = { 3.141592653589793, 1.0e100, -0.5, 12345.6789 };

    for (double v : values)
    {
        char buffer[128];
        auto r = boost::charconv::to_chars(
            buffer, buffer + sizeof(buffer), v,
            boost::charconv::chars_format::general);
        if (r.ec != std::errc()) return 1;

        double v2 = 0;
        auto r2 = boost::charconv::from_chars(
            buffer, r.ptr, v2, boost::charconv::chars_format::general);
        if (r2.ec != std::errc()) return 1;
        if (v2 != v) return 1; // shortest-roundtrip must be exact
    }

    return 0;
}