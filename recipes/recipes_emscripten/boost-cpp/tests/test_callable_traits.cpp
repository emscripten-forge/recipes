// Functional test for boost-callable_traits, adapted from
// libs/callable_traits/test/args.cpp

#include <boost/callable_traits.hpp>
#include <iostream>
#include <string>
#include <tuple>
#include <type_traits>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

int f(int x, char c) { return x + c; }

struct foo1 {
    int bar(char, float&, int = 0) { return 0; }
};

int main()
{
    using namespace boost::callable_traits;
    using fn = decltype(&f);
    using pmf = decltype(&foo1::bar);

    static_assert(std::is_same<return_type_t<fn>, int>::value, "ret");
    static_assert(std::is_same<args_t<fn>, std::tuple<int, char>>::value, "args");
    static_assert(std::is_same<args_t<pmf>,
                  std::tuple<foo1&, char, float&, int>>::value, "pmf args");
    static_assert(std::is_same<function_type_t<fn>, int(int, char)>::value, "fnty");
    static_assert(is_invocable<fn, int, char>::value, "invocable");
    static_assert(!is_invocable<fn, std::string>::value, "not invocable");

    CHECK(f(3, 4) == 7);

    std::cout << "boost-callable_traits OK\n";
    return 0;
}
