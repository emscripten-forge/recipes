// Functional test for boost-uuid, adapted from
// libs/uuid/test/quick.cpp

#include <boost/uuid.hpp>
#include <string>
#include <iostream>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

int main()
{
    using namespace boost::uuids;

    // nil uuid
    uuid n = nil_generator()();
    CHECK(n.is_nil());

    // parse a canonical RFC 4122 version-1 uuid
    std::string s = "f81d4fae-7dec-11d0-a765-00a0c91e6bf6";
    uuid u = string_generator()(s.c_str());
    CHECK(!u.is_nil());
    CHECK(u.size() == 16);
    CHECK(to_string(u) == s);
    CHECK(static_cast<int>(u.version()) == 1);  // time-based (nibble 0x1)

    // same input parses to the same uuid
    uuid u2 = string_generator()(s.c_str());
    CHECK(u == u2);

    // name-based (sha1) generator is deterministic
    uuid ns = nil_generator()();
    name_generator ng(ns);
    uuid a1 = ng("example.com");
    uuid a2 = ng("example.com");
    uuid a3 = ng("example.org");
    CHECK(a1 == a2);
    CHECK(!(a1 == a3));
    CHECK(!a1.is_nil());

    std::cout << "boost-uuid OK\n";
    return 0;
}
