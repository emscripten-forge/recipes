// Functional test for boost-type_traits
// adapted from libs/type_traits/test/negation_test.cpp.

#include <boost/type_traits.hpp>
#include <boost/type_traits/negation.hpp>
#include <boost/type_traits/is_same.hpp>
#include <boost/type_traits/remove_cv.hpp>
#include <boost/type_traits/remove_reference.hpp>
#include <boost/static_assert.hpp>
#include <iostream>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

enum color { red, green, blue };
struct widget { int n; };

int main()
{
    // primary type categories
    BOOST_STATIC_ASSERT(boost::is_integral<int>::value);
    BOOST_STATIC_ASSERT(!boost::is_integral<double>::value);
    BOOST_STATIC_ASSERT(boost::is_floating_point<double>::value);
    BOOST_STATIC_ASSERT(boost::is_enum<color>::value);
    BOOST_STATIC_ASSERT(!boost::is_enum<widget>::value);
    BOOST_STATIC_ASSERT(boost::is_class<widget>::value);
    BOOST_STATIC_ASSERT(boost::is_pointer<color*>::value);

    // type transformations compose
    BOOST_STATIC_ASSERT(boost::is_same<boost::add_pointer<widget>::type, widget*>::value);
    BOOST_STATIC_ASSERT(boost::is_same<boost::add_const<widget>::type, const widget>::value);
    BOOST_STATIC_ASSERT(boost::is_same<boost::remove_cv<const volatile int>::type, int>::value);
    BOOST_STATIC_ASSERT(boost::is_same<boost::remove_reference<int&>::type, int>::value);

    // boolean operator template from the negation corpus test
    BOOST_STATIC_ASSERT(boost::negation<boost::is_integral<double> >::value);
    BOOST_STATIC_ASSERT(!boost::negation<boost::is_integral<int> >::value);

    CHECK((boost::is_same<int, int>::value));
    std::cout << "boost-type_traits OK\n";
    return 0;
}
