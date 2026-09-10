// Functional test for boost-optional, adapted from
// libs/optional/test/optional_test.cpp and optional_test_make_optional.cpp

#include <boost/optional.hpp>
#include <iostream>
#include <string>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

int main()
{
    // Construction and value access.
    boost::optional<int> a = 5;
    CHECK(a);
    CHECK(*a == 5);
    boost::optional<int> empty;
    CHECK(!empty);

    // Assignment keeps the value alive and resettable.
    empty = a;
    CHECK(empty && *empty == 5);
    a.reset();
    CHECK(!a);
    CHECK(empty.value() == 5);           // engaged: value() is safe
    CHECK(empty.value_or(-1) == 5);      // value_or on engaged optional
    CHECK(a.value_or(-1) == -1);         // value_or on empty optional

    // emplace + in-place semantics on non-trivially-copyable types.
    boost::optional<std::string> s;
    s.emplace("hello");
    CHECK(s && s->size() == 5u);
    s = std::string("world");
    CHECK(*s == "world");
    s.reset();
    CHECK(!s);

    // make_optional and comparisons with boost::none.
    boost::optional<int> m = boost::make_optional(7);
    CHECK(m && *m == 7);
    CHECK(m != boost::none);
    CHECK(boost::none < m);
    boost::optional<int> n = boost::none;
    CHECK(n == boost::none);

    // Ordering compares engaged values.
    boost::optional<int> low = 1;
    boost::optional<int> high = 2;
    CHECK(low < high);
    CHECK(high > low && high != low);

    std::cout << "boost-optional OK\n";
    return 0;
}
