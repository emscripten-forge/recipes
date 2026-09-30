// Functional test for boost-exception, adapted from
// libs/exception/test/exception_test.cpp

#include <boost/exception/all.hpp>
#include <stdexcept>
#include <string>

int main()
{
    try
    {
        BOOST_THROW_EXCEPTION(
            boost::enable_error_info(std::runtime_error("system call failed"))
                << boost::errinfo_api_function("write"));
    }
    catch (boost::exception const& e)
    {
        // diagnostic_information must be non-empty and carry the added tag
        std::string di = boost::diagnostic_information(e);
        if (di.empty()) return 1;
        if (di.find("write") == std::string::npos) return 1;
        return 0;
    }

    return 1; // the exception was not thrown/translated
}