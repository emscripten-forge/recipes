// Functional test for boost-endian , adapted from
// libs/endian/example/endian_example.cpp (endian buffers) and
// libs/endian/test/conversion_test.cpp (store/load + endian_reverse).
#include <boost/endian.hpp>
#include <cstdint>
#include <iostream>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

int main()
{
    unsigned char buf[4] = { 0, 0, 0, 0 };

    boost::endian::store_big_u32(buf, 0x01020304u);
    CHECK(buf[0] == 0x01 && buf[1] == 0x02 && buf[2] == 0x03 && buf[3] == 0x04);
    CHECK(boost::endian::load_big_u32(buf) == 0x01020304u);

    boost::endian::store_little_u32(buf, 0x01020304u);
    CHECK(buf[0] == 0x04 && buf[1] == 0x03 && buf[2] == 0x02 && buf[3] == 0x01);
    CHECK(boost::endian::load_little_u32(buf) == 0x01020304u);

    CHECK(boost::endian::endian_reverse<std::uint32_t>(0x01020304u) == 0x04030201u);
    std::uint32_t v = 0xDEADBEEFu;
    CHECK(boost::endian::endian_reverse(boost::endian::endian_reverse(v)) == v);

    // endian arithmetic type round-trips through a big-endian buffer
    boost::endian::big_uint32_t x = 0x01020304u;
    boost::endian::store_big_u32(buf, static_cast<std::uint32_t>(x));
    CHECK(boost::endian::load_big_u32(buf) == static_cast<std::uint32_t>(x));
    x += 1;
    CHECK(static_cast<std::uint32_t>(x) == 0x01020305u);

    std::cout << "boost-endian OK\n";
    return 0;
}
