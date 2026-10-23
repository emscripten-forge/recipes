// Functional test for boost-hash2, adapted from
// libs/hash2/test/blake2.cpp

#include <boost/hash2/blake2.hpp>
#include <iostream>
#include <string>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

static std::string digest512(std::string const &s)
{
    boost::hash2::blake2b_512 h;
    h.update(s.data(), s.size());
    return to_string(h.result());
}

static std::string digest256(std::string const &s)
{
    boost::hash2::blake2s_256 h;
    h.update(s.data(), s.size());
    return to_string(h.result());
}

int main()
{
    // known-answer checks (empty string and the classic fox sentence)
    CHECK(digest512("") == "786a02f742015903c6c6fd852552d272912f4740e15847618a86e217f71f5419d25e1031afee585313896444934eb04b903a685b1448b755d56f701afe9be2ce");
    CHECK(digest512("The quick brown fox jumps over the lazy dog") == "a8add4bdddfd93e4877d2746e62817b116364a1fa7bc148d95090bc7333b3673f82401cf7aa2e4cb1ecd90296e3f14cb5413f8ed77be73045b13914cdcd6a918");
    CHECK(digest256("") == "69217a3079908094e11121d042354a7c1f55b6482ca1a51e1b250dfd1ed0eef9");

    // streaming: split updates give the same digest as one update
    std::string fox = "The quick brown fox jumps over the lazy dog";
    boost::hash2::blake2b_512 h;
    h.update(fox.data(), fox.size() / 2);
    h.update(fox.data() + fox.size() / 2, fox.size() - fox.size() / 2);
    CHECK(to_string(h.result()) == "a8add4bdddfd93e4877d2746e62817b116364a1fa7bc148d95090bc7333b3673f82401cf7aa2e4cb1ecd90296e3f14cb5413f8ed77be73045b13914cdcd6a918");

    // different input -> different digest
    CHECK(digest256("The quick brown fox jumps over the lazy dog") != "69217a3079908094e11121d042354a7c1f55b6482ca1a51e1b250dfd1ed0eef9");

    std::cout << "boost-hash2 OK\n";
    return 0;
}
