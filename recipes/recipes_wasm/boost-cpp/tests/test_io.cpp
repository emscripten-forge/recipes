// Functional test for boost-io, adapted from
// libs/io/test/ostream_joiner_test.cpp

#include <boost/io/ostream_joiner.hpp>
#include <sstream>
#include <vector>
#include <iostream>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x "\n"; return 1; } } while (0)

int main()
{
    {
        std::ostringstream o;
        boost::io::ostream_joiner<const char*> j(o, ",");
        j = 1;
        CHECK(o.str() == "1");
        j = '2';
        CHECK(o.str() == "1,2");
        j = "3";
        CHECK(o.str() == "1,2,3");
    }
    {
        // joining a range of ints, like std::ostream_iterator with a separator
        std::ostringstream o;
        std::vector<int> v;
        v.push_back(10);
        v.push_back(20);
        v.push_back(30);
        std::copy(v.begin(), v.end(), boost::io::make_ostream_joiner(o, "-"));
        CHECK(o.str() == "10-20-30");
    }
    std::cout << "boost-io OK\n";
    return 0;
}
