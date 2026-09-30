// Functional test for boost-function_types, adapted from libs/function_types/test/synthesis/function_type.cpp

#include <boost/function_types/function_arity.hpp>
#include <boost/function_types/function_type.hpp>
#include <boost/function_types/parameter_types.hpp>
#include <boost/function_types/result_type.hpp>
#include <boost/mpl/at.hpp>
#include <boost/mpl/vector.hpp>
#include <boost/type_traits/is_same.hpp>
#include <iostream>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

namespace ft = boost::function_types;
namespace mpl = boost::mpl;
using boost::is_same;

typedef int sig(int, char);

// decomposition: arity, result type, parameter types
static_assert(ft::function_arity<sig>::value == 2, "arity of int(int,char)");
static_assert(is_same<ft::result_type<sig>::type, int>::value, "result type");
typedef ft::parameter_types<sig>::type params;
static_assert(is_same<mpl::at_c<params, 0>::type, int>::value, "param0");
static_assert(is_same<mpl::at_c<params, 1>::type, char>::value, "param1");

// synthesis: rebuild a function type from an mpl sequence
typedef long ft_long(int);
static_assert(is_same<ft::function_type<mpl::vector<long, int> >::type, ft_long>::value,
              "rebuild long(int)");

int main()
{
    CHECK(ft::function_arity<sig>::value == 2u);
    std::cout << "boost-function_types OK\n";
    return 0;
}
