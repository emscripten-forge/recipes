// Functional test for boost-outcome , adapted from
// libs/outcome/test/expected-pass.cpp

#include <boost/outcome/result.hpp>
#include <boost/outcome/success_failure.hpp>
#include <iostream>
#include <string>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

namespace out = boost::outcome_v2;

int main()
{
    // Value state.
    out::unchecked<long, std::string> ok = 42L;
    CHECK(ok.has_value());
    CHECK(!ok.has_error());
    CHECK(ok.value() == 42L);

    // Error state carries the failure payload.
    out::unchecked<long, std::string> err =
        out::failure(std::string("disk full"));
    CHECK(!err.has_value());
    CHECK(err.has_error());
    CHECK(err.error() == "disk full");

    // success/failure factories reassign states.
    ok = out::success(7L);
    CHECK(ok.has_value() && ok.value() == 7L);
    err = out::failure(std::string("timeout"));
    CHECK(err.has_error() && err.error() == "timeout");

    // State round-trip through an unchecked (value-preserving) accessor.
    CHECK(!ok.has_error());
    long v = ok.value();
    CHECK(v == 7L);

    // as_failure() lets the error state be inspected or forwarded.
    auto as_f = err.as_failure();
    CHECK(as_f.error() == "timeout");

    std::cout << "boost-outcome OK\n";
    return 0;
}
