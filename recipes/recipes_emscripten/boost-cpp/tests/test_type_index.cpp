// Functional test for boost-type_index , adapted from
// libs/type_index/test/ctti_print_name.cpp 

#include <boost/type_index.hpp>
#include <boost/type_index/ctti_type_index.hpp>
#include <iostream>
#include <string>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

namespace user_defined_namespace {
    class user_defined_class {};
}

class empty
{
};

int main()
{
    using namespace boost::typeindex;

    // Default (RTTI-based) type_index: same type ==, different types !=,
    // raw name present, hash of two ids of the same type agree.
    type_index ti_int = type_id<int>();
    CHECK(ti_int == type_id<int>());
    CHECK(ti_int != type_id<double>());
    CHECK(ti_int != type_id<user_defined_namespace::user_defined_class>());
    CHECK(ti_int.raw_name()[0] != 0);        // raw RTTI name present
    CHECK(ti_int.hash_code() == type_id<int>().hash_code());
    CHECK(ti_int.hash_code() != type_id<double>().hash_code());
    CHECK(!ti_int.pretty_name().empty());

    // Explicit ctti_type_index: no RTTI needed, pretty name is parsed from
    // the type spelling, so it is deterministic.
    ctti_type_index ct = ctti_type_index::type_id<int>();
    CHECK(ct == ctti_type_index::type_id<int>());
    CHECK(ct != ctti_type_index::type_id<double>());
    CHECK(ct.pretty_name() == "int");
    CHECK(ctti_type_index::type_id<user_defined_namespace::user_defined_class>().pretty_name()
          == "user_defined_namespace::user_defined_class");
    CHECK(ctti_type_index::type_id<empty>().pretty_name() == "empty");

    // stl and ctti spellings of the same type must not collide.
    CHECK(type_id<int>().pretty_name() != ctti_type_index::type_id<double>().pretty_name());

    std::cout << "boost-type_index OK\n";
    return 0;
}
