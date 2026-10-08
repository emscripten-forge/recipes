#include <msgpack.hpp>

#include <string>
#include <sstream>
#include <vector>
#include <map>
#include <cstdio>
#include <cstdlib>

static int failures = 0;

#define CHECK(cond) \
    do { \
        if (!(cond)) { \
            std::fprintf(stderr, "  FAIL: %s (line %d)\n", #cond, __LINE__); \
            ++failures; \
        } \
    } while (false)

static void test_int_pack_unpack() {
    std::printf("Testing int pack/unpack...\n");

    std::stringstream buffer;
    msgpack::pack(buffer, 42);

    std::string data = buffer.str();
    msgpack::object_handle oh = msgpack::unpack(data.data(), data.size());
    int val = oh.get().as<int>();

    CHECK(val == 42);
    std::printf("  PASS\n");
}

static void test_string_pack_unpack() {
    std::printf("Testing string pack/unpack...\n");

    std::stringstream buffer;
    std::string original("hello msgpack");
    msgpack::pack(buffer, original);

    std::string data = buffer.str();
    msgpack::object_handle oh = msgpack::unpack(data.data(), data.size());
    std::string val = oh.get().as<std::string>();

    CHECK(val == original);
    std::printf("  PASS\n");
}

static void test_vector_pack_unpack() {
    std::printf("Testing vector<int> pack/unpack...\n");

    std::stringstream buffer;
    std::vector<int> original = {1, 2, 3, 42, -1};
    msgpack::pack(buffer, original);

    std::string data = buffer.str();
    msgpack::object_handle oh = msgpack::unpack(data.data(), data.size());
    std::vector<int> val;
    oh.get().convert(val);

    CHECK(val == original);
    std::printf("  PASS\n");
}

static void test_map_pack_unpack() {
    std::printf("Testing map<string,int> pack/unpack...\n");

    std::stringstream buffer;
    std::map<std::string, int> original;
    original["alpha"] = 1;
    original["beta"] = 2;
    msgpack::pack(buffer, original);

    std::string data = buffer.str();
    msgpack::object_handle oh = msgpack::unpack(data.data(), data.size());
    std::map<std::string, int> val;
    oh.get().convert(val);

    CHECK(val.size() == 2);
    CHECK(val["alpha"] == 1);
    CHECK(val["beta"] == 2);
    std::printf("  PASS\n");
}

static void test_bool_pack_unpack() {
    std::printf("Testing bool pack/unpack...\n");

    std::stringstream buffer;
    msgpack::pack(buffer, true);
    msgpack::pack(buffer, false);

    std::string data = buffer.str();
    msgpack::unpacker unp;
    unp.reserve_buffer(data.size());
    std::memcpy(unp.buffer(), data.data(), data.size());
    unp.buffer_consumed(data.size());

    msgpack::object_handle oh;
    CHECK(unp.next(oh));
    CHECK(oh.get().as<bool>() == true);
    CHECK(unp.next(oh));
    CHECK(oh.get().as<bool>() == false);
    CHECK(!unp.next(oh));  // no more objects

    std::printf("  PASS\n");
}

static void test_nil_pack_unpack() {
    std::printf("Testing nil pack/unpack...\n");

    std::stringstream buffer;
    msgpack::pack(buffer, msgpack::type::nil_t());

    std::string data = buffer.str();
    msgpack::object_handle oh = msgpack::unpack(data.data(), data.size());

    CHECK(oh.get().is_nil());
    std::printf("  PASS\n");
}

static void test_double_pack_unpack() {
    std::printf("Testing double pack/unpack...\n");

    std::stringstream buffer;
    msgpack::pack(buffer, 3.14159);

    std::string data = buffer.str();
    msgpack::object_handle oh = msgpack::unpack(data.data(), data.size());
    double val = oh.get().as<double>();

    CHECK(val > 3.14 && val < 3.15);
    std::printf("  PASS\n");
}

static void test_zone_lifecycle() {
    std::printf("Testing zone lifecycle...\n");

    msgpack::zone zone;
    msgpack::object obj;

    // Create a string object in the zone
    obj = msgpack::object(std::string("zone test"), zone);
    CHECK(obj.as<std::string>() == "zone test");

    std::printf("  PASS\n");
}

static void test_empty_array() {
    std::printf("Testing empty array pack/unpack...\n");

    std::stringstream buffer;
    std::vector<int> empty;
    msgpack::pack(buffer, empty);

    std::string data = buffer.str();
    msgpack::object_handle oh = msgpack::unpack(data.data(), data.size());
    std::vector<int> val;
    oh.get().convert(val);

    CHECK(val.empty());
    std::printf("  PASS\n");
}

static void test_negative_int() {
    std::printf("Testing negative integer pack/unpack...\n");

    std::stringstream buffer;
    msgpack::pack(buffer, -100);

    std::string data = buffer.str();
    msgpack::object_handle oh = msgpack::unpack(data.data(), data.size());
    int val = oh.get().as<int>();

    CHECK(val == -100);
    std::printf("  PASS\n");
}

int main() {
    std::printf("=== msgpack-c test suite ===\n\n");

    test_int_pack_unpack();
    test_negative_int();
    test_double_pack_unpack();
    test_bool_pack_unpack();
    test_nil_pack_unpack();
    test_string_pack_unpack();
    test_vector_pack_unpack();
    test_empty_array();
    test_map_pack_unpack();
    test_zone_lifecycle();

    std::printf("\n=== Results: %d failures ===\n", failures);
    return failures > 0 ? 1 : 0;
}
