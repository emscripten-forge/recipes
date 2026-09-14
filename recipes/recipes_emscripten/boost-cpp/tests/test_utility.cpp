#include <boost/utility.hpp>
#include <type_traits>
#include <iostream>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

struct sneaky
{
    sneaky* operator&() { return 0; }        // try to hide the address
};

struct counted
{
    static int dtors;
    ~counted() { ++dtors; }
};
int counted::dtors = 0;

struct locked : boost::noncopyable { int n; };

int main()
{
    // addressof bypasses an overloaded operator&
    sneaky a, b;
    CHECK(boost::addressof(a) != 0);
    CHECK(boost::addressof(a) != boost::addressof(b));

    // checked_delete / checked_array_delete invoke the real destructors
    counted* p = new counted;
    boost::checked_delete(p);
    CHECK(counted::dtors == 1);
    counted* arr = new counted[2];
    boost::checked_array_delete(arr);
    CHECK(counted::dtors == 3);

    // noncopyable forbids copying
    static_assert(!std::is_copy_constructible<locked>::value, "noncopyable");
    static_assert(!std::is_copy_assignable<locked>::value, "noncopyable");

    // binary literal macro
    CHECK(BOOST_BINARY(110101) == 53);

    std::cout << "boost-utility OK\n";
    return 0;
}
