// Functional test for boost-format, adapted from
// libs/format/test/format_test1.cpp
#include <boost/format.hpp>
#include <iostream>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

int main()
{
    using boost::format;
    using boost::str;

    CHECK(str(format("  %%  ")) == "  %  ");
    CHECK(str(format("nothing")) == "nothing");

    // escaped percents, positional args and hex conversion
    CHECK(str(format("%%##%#x ##%%1 %s00") % 20 % "Escaped OK") == "%##0x14 ##%1 Escaped OK00");
    CHECK(str(format("%1% %2% %1%") % "a" % "b") == "a b a");

    // numeric formatting: width, fill and float precision
    CHECK(str(format("%5.2f|%05d") % 3.14159 % 42) == " 3.14|00042");

    std::cout << "boost-format OK\n";
    return 0;
}
