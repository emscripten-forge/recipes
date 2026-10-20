// Functional test for boost-json, adapted from libs/json/test/parse.cpp
// and libs/json/test/serialize.cpp

#include <boost/json.hpp>
#include <boost/system/error_code.hpp>
#include <string>
#include <iostream>

namespace json = boost::json;

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << std::endl; return 1; } } while (0)

int main()
{
    // --- parse + access ---
    boost::system::error_code ec;
    json::value v = json::parse(
        R"({"name":"boost","nums":[1,2.5,-3],"ok":true,"nothing":null})", ec);
    CHECK(!ec);

    json::object const& obj = v.as_object();
    CHECK(obj.at("name").as_string() == "boost");
    CHECK(obj.at("ok").as_bool());
    CHECK(obj.at("nothing").is_null());

    json::array const& nums = obj.at("nums").as_array();
    CHECK(nums.size() == 3);
    CHECK(nums[0].as_int64() == 1);
    CHECK(nums[1].as_double() == 2.5);
    CHECK(nums[2].as_int64() == -3);

    // --- build from scratch + deterministic serialize ---
    json::value built{
        {"a", 1},
        {"b", json::array{true, "x"}},
    };
    std::string s = json::serialize(built);
    CHECK(s == R"({"a":1,"b":[true,"x"]})");

    // --- serialize(parse(x)) roundtrip ---
    std::string orig = R"({"k":[1,2,{"deep":"v"}]})";
    CHECK(json::serialize(json::parse(orig, ec)) == orig);
    CHECK(!ec);

    // --- error path (unterminated input fails; exact code is incomplete) ---
    json::parse(R"({"unterminated":)", ec);
    CHECK(ec.failed());

    std::cout << "boost-json OK" << std::endl;
    return 0;
}
