#include <iostream>
#include <string>
#include <vector>

#include "absl/strings/str_cat.h"
#include "absl/strings/str_split.h"
#include "absl/strings/string_view.h"
#include "absl/strings/str_format.h"
#include "absl/container/flat_hash_map.h"
#include "absl/container/flat_hash_set.h"
#include "absl/status/status.h"
#include "absl/status/statusor.h"
#include "absl/time/time.h"
#include "absl/time/clock.h"

// Report helper
static int failures = 0;
#define CHECK(cond) \
    do { \
        if (!(cond)) { \
            std::cerr << "FAIL: " #cond " (line " << __LINE__ << ")" << std::endl; \
            ++failures; \
        } \
    } while (false)

// ---------------------------------------------------------------------------
// Test absl::strings
// ---------------------------------------------------------------------------
void test_strings() {
    std::cout << "Testing absl::strings..." << std::endl;

    // StrCat
    std::string s = absl::StrCat("Hello", ", ", "World", "!");
    CHECK(s == "Hello, World!");

    // StrFormat
    std::string formatted = absl::StrFormat("value=%d pi=%.2f", 42, 3.14159);
    CHECK(formatted == "value=42 pi=3.14");

    // StrSplit
    std::vector<std::string> parts = absl::StrSplit("a,b,c,d", ',');
    CHECK(parts.size() == 4);
    CHECK(parts[0] == "a");
    CHECK(parts[3] == "d");

    // string_view
    absl::string_view sv = "abcdef";
    CHECK(sv.size() == 6);
    CHECK(sv.substr(1, 3) == "bcd");

    std::cout << "  absl::strings OK" << std::endl;
}

// ---------------------------------------------------------------------------
// Test absl::flat_hash_map / flat_hash_set
// ---------------------------------------------------------------------------
void test_containers() {
    std::cout << "Testing absl::containers..." << std::endl;

    // flat_hash_map
    absl::flat_hash_map<std::string, int> map;
    map["one"] = 1;
    map["two"] = 2;
    map["three"] = 3;
    CHECK(map.size() == 3);
    CHECK(map["one"] == 1);
    CHECK(map.contains("two"));
    CHECK(!map.contains("four"));

    // flat_hash_set
    absl::flat_hash_set<int> set = {1, 2, 3, 4, 5};
    CHECK(set.size() == 5);
    CHECK(set.contains(3));
    CHECK(!set.contains(6));
    set.insert(6);
    CHECK(set.contains(6));

    std::cout << "  absl::containers OK" << std::endl;
}

// ---------------------------------------------------------------------------
// Test absl::Status / absl::StatusOr
// ---------------------------------------------------------------------------
absl::StatusOr<int> safe_divide(int a, int b) {
    if (b == 0) {
        return absl::InvalidArgumentError("division by zero");
    }
    return a / b;
}

void test_status() {
    std::cout << "Testing absl::Status / absl::StatusOr..." << std::endl;

    // OK status
    absl::Status ok = absl::OkStatus();
    CHECK(ok.ok());

    // Error status
    absl::Status err = absl::NotFoundError("item not found");
    CHECK(!err.ok());
    CHECK(err.code() == absl::StatusCode::kNotFound);

    // StatusOr success
    auto result = safe_divide(10, 2);
    CHECK(result.ok());
    CHECK(*result == 5);

    // StatusOr failure
    auto bad = safe_divide(10, 0);
    CHECK(!bad.ok());
    CHECK(bad.status().code() == absl::StatusCode::kInvalidArgument);

    std::cout << "  absl::Status OK" << std::endl;
}

// ---------------------------------------------------------------------------
// Test absl::Time
// ---------------------------------------------------------------------------
void test_time() {
    std::cout << "Testing absl::Time..." << std::endl;

    absl::Time epoch = absl::UnixEpoch();
    absl::Time now = absl::Now();

    // now should be strictly after epoch
    CHECK(now > epoch);

    // Duration arithmetic
    absl::Duration one_hour = absl::Hours(1);
    absl::Duration one_min  = absl::Minutes(1);
    CHECK(one_hour == 60 * one_min);

    absl::Time future = epoch + absl::Seconds(3600);
    CHECK(future - epoch == one_hour);

    std::cout << "  absl::Time OK" << std::endl;
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------
int main() {
    std::cout << "=== Testing Abseil C++ library ===" << std::endl;

    test_strings();
    test_containers();
    test_status();
    test_time();

    if (failures > 0) {
        std::cerr << failures << " test(s) FAILED." << std::endl;
        return 1;
    }

    std::cout << "=== All Abseil tests passed! ===" << std::endl;
    return 0;
}
