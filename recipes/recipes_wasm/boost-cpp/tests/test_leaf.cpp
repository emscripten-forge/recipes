// Functional test for boost-leaf, adapted from
// libs/leaf/example/print_half.cpp

#include <boost/leaf.hpp>
#include <algorithm>
#include <cctype>
#include <cstdlib>
#include <iostream>
#include <string>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

namespace leaf = boost::leaf;

enum class ConversionErrc
{
    EmptyString = 1,
    IllegalChar,
    TooLong
};

leaf::result<int> convert(const std::string& str) noexcept
{
    if (str.empty())
        return leaf::new_error(ConversionErrc::EmptyString);
    if (!std::all_of(str.begin(), str.end(), ::isdigit))
        return leaf::new_error(ConversionErrc::IllegalChar);
    if (str.length() > 9)
        return leaf::new_error(ConversionErrc::TooLong);
    return std::atoi(str.c_str());
}

// Returns parsed value, or negative code per error kind.
int classify(const std::string& s)
{
    return leaf::try_handle_all(
        [&]() -> leaf::result<int> {
            BOOST_LEAF_AUTO(v, convert(s));
            return v;
        },
        [](leaf::match<ConversionErrc, ConversionErrc::EmptyString>) { return -1; },
        [](leaf::match<ConversionErrc, ConversionErrc::IllegalChar>) { return -2; },
        [](leaf::error_info const&) { return -3; });
}

int main()
{
    CHECK(classify("42") == 42);
    CHECK(classify("1983") == 1983);
    CHECK(classify("") == -1);
    CHECK(classify("1x2") == -2);
    CHECK(classify("1234567890") == -3); // TooLong: falls through to error_info
    std::cout << "boost-leaf OK\n";
    return 0;
}
