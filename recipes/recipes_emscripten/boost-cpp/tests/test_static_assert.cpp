// Functional test for boost-static_assert,
// adapted from libs/static_assert/test/static_assert_test.cpp

#include <boost/static_assert.hpp>
#include <type_traits>
#include <iostream>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

// namespace scope
BOOST_STATIC_ASSERT(sizeof(char) == 1);
BOOST_STATIC_ASSERT(sizeof(int) >= sizeof(short));
BOOST_STATIC_ASSERT_MSG(sizeof(char) == 1, "char must be one byte");
BOOST_STATIC_ASSERT_MSG(sizeof(int) == 4, "int must be 32-bit on wasm32");

// class scope (private members checkable)
struct Bob
{
private:
    BOOST_STATIC_ASSERT(sizeof(int) >= sizeof(short));
    BOOST_STATIC_ASSERT_MSG(sizeof(int) == 4, "wasm32 int");
public:
    int x;
};

// template class scope: assert a property of the instantiated type
template< class T >
struct Bill
{
    BOOST_STATIC_ASSERT_MSG(std::is_integral< T >::value,
        "Bill<T> requires an integral T");
    BOOST_STATIC_ASSERT(sizeof(T) <= sizeof(T)); // trivially true, macro usable
    T v;
};

int main()
{
    // function (block) scope
    BOOST_STATIC_ASSERT(sizeof(int) >= sizeof(short));
    BOOST_STATIC_ASSERT_MSG(sizeof(char) == 1, "block scope ok");

    Bob b;
    b.x = 5;
    Bill< int > bi;
    bi.v = 42;
    CHECK(b.x == 5 && bi.v == 42); // instantiations compiled above

    // negative instantiation would fail at compile time:
    // Bill< float > not_used; // static assert fires here

    std::cout << "boost-static_assert OK\n";
    return 0;
}
