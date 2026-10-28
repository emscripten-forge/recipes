// Functional test for boost-algorithm, adapted from
// libs/algorithm/test/hex_test1.cpp and the misc algorithms of
// boost/algorithm/algorithm.hpp

#include <boost/algorithm/algorithm.hpp>
#include <boost/algorithm/hex.hpp>
#include <iostream>
#include <string>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

int main()
{
    // hex encode / decode round trip (boost::algorithm::hex / unhex)
    std::string src = "Boost";
    std::string enc = boost::algorithm::hex(src);
    CHECK(enc == "426F6F7374");
    CHECK(boost::algorithm::hex_lower(src) == "426f6f7374");
    CHECK(boost::algorithm::unhex(enc) == src);
    std::string long_src = "Hello, wasm!";
    CHECK(boost::algorithm::unhex(boost::algorithm::hex(long_src)) == long_src);

    // misc algorithm: repeated-squaring power
    CHECK(boost::algorithm::power(2, 10) == 1024);
    CHECK(boost::algorithm::power(3, 4) == 81);

    std::cout << "boost-algorithm OK\n";
    return 0;
}
