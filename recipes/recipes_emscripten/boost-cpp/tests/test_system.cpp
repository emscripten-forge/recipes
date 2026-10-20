// Functional test for boost-system, adapted from
// libs/system/test/error_code_test.cpp
#include <boost/system/error_code.hpp>
#include <boost/system/errc.hpp>
#include <string>

int main()
{
    using namespace boost::system;

    // error_code carrying the platform errno for ENOENT in the system category
    error_code ec(errc::no_such_file_or_directory, system_category());
    if (ec.value() == 0) return 1;
    if (!ec) return 1;

    // the system category maps it back to the generic condition
    if (ec.default_error_condition() != errc::no_such_file_or_directory)
        return 1;

    // message() must produce a non-empty human-readable description
    if (ec.message().empty()) return 1;

    return 0;
}