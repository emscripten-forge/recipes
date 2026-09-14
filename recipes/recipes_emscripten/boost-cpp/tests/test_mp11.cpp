// Functional test for boost-mp11,
// adapted from libs/mp11/test/mp11.cpp

#include <boost/mp11.hpp>
#include <iostream>
#include <type_traits>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

using namespace boost::mp11;

using L = mp_list<int, char, long, int>;

static_assert(mp_size<L>::value == 4, "list size");
static_assert(std::is_same<mp_at_c<L, 2>, long>::value, "mp_at_c element type");
static_assert(mp_count<L, int>::value == 2, "mp_count duplicates");

using U = mp_unique<L>;
static_assert(mp_size<U>::value == 3, "mp_unique removes duplicates");
static_assert(std::is_same<mp_at_c<U, 0>, int>::value, "first unique element");

using A = mp_append<mp_list<int>, mp_list<char, double>>;
static_assert(mp_size<A>::value == 3, "mp_append concatenates");

int main()
{
    // Compile-time list arithmetic observable at runtime
    int n = mp_at_c<mp_iota_c<10>, 5>::value;
    CHECK(n == 5);
    CHECK(mp_size<L>::value == 4);
    std::cout << "boost-mp11 OK\n";
    return 0;
}
