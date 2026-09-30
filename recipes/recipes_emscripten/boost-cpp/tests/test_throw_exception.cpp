// Functional test for boost-throw_exception, adapted from
// libs/throw_exception/test/throw_exception_no_exceptions_test.cpp.

#include <cstdlib>
#include <exception>
#include <iostream>
#include <string>

#define BOOST_NO_EXCEPTIONS
#include <boost/throw_exception.hpp>

class my_exception: public std::exception {
public:
    const char* what() const noexcept { return "boom"; }
};

int main()
{
    boost::throw_exception(my_exception());
    std::cerr << "FAIL: handler was not invoked\n";
    return 1;
}

namespace boost
{

// User-defined handler: in BOOST_NO_EXCEPTIONS builds every
// boost::throw_exception call is routed here (declared in the header).
void throw_exception(std::exception const& e)
{
    // The real exception object must arrive intact.
    if (std::string(e.what()) != "boom") {
        std::cerr << "FAIL: unexpected exception content: " << e.what() << "\n";
        std::exit(1);
    }
    std::cout << "boost-throw_exception OK\n";
    std::exit(0);
}

} // namespace boost
