// Functional test for boost-metaparse,
// adapted from libs/metaparse/test/int_.cpp

#include <boost/metaparse/int_.hpp>
#include <boost/metaparse/is_error.hpp>
#include <boost/metaparse/start.hpp>
#include <boost/metaparse/get_result.hpp>
#include <boost/metaparse/string.hpp>
#include <boost/mpl/apply_wrap.hpp>
#include <iostream>

int main()
{
    using boost::metaparse::is_error;
    using boost::metaparse::int_;
    using boost::metaparse::start;
    using boost::metaparse::get_result;
    using boost::mpl::apply_wrap2;

    // "1983" parses as the integer 1983
    typedef apply_wrap2<int_, boost::metaparse::string<'1', '9', '8', '3'>, start>::type ok;
    static_assert(!is_error<ok>::value, "int parse of 1983 must succeed");
    static_assert(get_result<ok>::type::value == 1983, "parsed value must be 1983");

    // "0" parses as 0
    typedef apply_wrap2<int_, boost::metaparse::string<'0'>, start>::type zero;
    static_assert(!is_error<zero>::value, "int parse of 0 must succeed");
    static_assert(get_result<zero>::type::value == 0, "parsed value must be 0");

    // "hello" is not an integer: parse must fail
    typedef apply_wrap2<int_, boost::metaparse::string<'h', 'e', 'l', 'l', 'o'>, start>::type bad;
    static_assert(is_error<bad>::value, "int parse of hello must fail");

    std::cout << "boost-metaparse OK\n";
    return 0;
}
