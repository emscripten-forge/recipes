// Functional test for boost-redis, adapted from
// libs/redis/test/test_request.cpp

#include <boost/redis/request.hpp>
#include <boost/redis/error.hpp>
#include <boost/redis/impl/error.ipp>
#include <boost/redis/impl/request.ipp>
#include <boost/redis/resp3/impl/serialization.ipp>
#include <iostream>
#include <string>
#include <vector>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

int main()
{
    boost::redis::request req;
    CHECK(req.get_commands() == 0);
    CHECK(req.get_expected_responses() == 0);

    // One command with two arguments: RESP3 array header + bulk strings.
    req.push("SET", "key", "value");
    CHECK(req.get_commands() == 1);
    CHECK(req.get_expected_responses() == 1);
    CHECK(std::string(req.payload()) == "*3\r\n$3\r\nSET\r\n$3\r\nkey\r\n$5\r\nvalue\r\n");

    // Second command appends to the same buffer.
    req.push("GET", "key");
    CHECK(req.get_commands() == 2);
    CHECK(req.get_expected_responses() == 2);
    CHECK(std::string(req.payload())
          == "*3\r\n$3\r\nSET\r\n$3\r\nkey\r\n$5\r\nvalue\r\n"
             "*2\r\n$3\r\nGET\r\n$3\r\nkey\r\n");

    // push_range: one command whose trailing arguments come from a range.
    boost::redis::request r2;
    std::vector<std::string> vals = {"a", "b", "c"};
    r2.push_range("LPUSH", "list", vals.begin(), vals.end());
    CHECK(r2.get_commands() == 1);
    CHECK(r2.get_expected_responses() == 1);
    CHECK(std::string(r2.payload())
          == "*5\r\n$5\r\nLPUSH\r\n$4\r\nlist\r\n$1\r\na\r\n$1\r\nb\r\n$1\r\nc\r\n");

    // Error codes translate into boost::system::error_code.
    boost::system::error_code ec = boost::redis::make_error_code(boost::redis::error::invalid_data_type);
    CHECK(ec.value() == 1);
    CHECK(ec.category().name() == std::string("boost.redis"));

    std::cout << "boost-redis OK\n";
    return 0;
}
