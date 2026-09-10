// Functional test for boost-mpl,
// adapted from libs/mpl/test/size.cpp and arithmetic tests in
// libs/mpl/test/arithmetic.cpp

#include <boost/mpl/vector.hpp>
#include <boost/mpl/O1_size.hpp>
#include <boost/mpl/size.hpp>
#include <boost/mpl/at.hpp>
#include <boost/mpl/plus.hpp>
#include <boost/mpl/int.hpp>
#include <iostream>
#include <type_traits>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

using V = boost::mpl::vector<int, char, double>;

static_assert(boost::mpl::O1_size<V>::value == 3, "O(1) size of mpl::vector");
static_assert(boost::mpl::size<V>::value == 3, "mpl::size of mpl::vector");
static_assert(std::is_same<boost::mpl::at_c<V, 2>::type, double>::value, "indexed access");
static_assert(boost::mpl::plus<boost::mpl::int_<20>, boost::mpl::int_<22>>::value == 42,
              "compile-time arithmetic");

int main()
{
    // Compile-time results observable at runtime
    int n = boost::mpl::O1_size<V>::value;
    CHECK(n == 3);
    std::cout << "boost-mpl OK\n";
    return 0;
}
