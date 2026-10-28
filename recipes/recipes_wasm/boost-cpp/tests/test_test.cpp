// Functional test for boost-test: a real Boost.Test framework run.
// Adapted from the classic static-link pattern used throughout
// libs/test/test/

#define BOOST_TEST_MODULE boost_cpp_test
#include <boost/test/unit_test.hpp>

BOOST_AUTO_TEST_CASE( arithmetic_smoke )
{
    BOOST_CHECK_EQUAL(1 + 1, 2);
}