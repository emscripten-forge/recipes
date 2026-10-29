// Functional test for boost-crc, adapted from
// libs/crc/test/quick.cpp (crc_32_type over a byte string) plus the
// standard CRC-32 check value for "123456789".

#include <boost/crc.hpp>
#include <cstring>
#include <iostream>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

int main()
{
    {
        boost::crc_32_type crc;
        char const* data = "Hello, world!";
        crc.process_bytes(data, std::strlen(data));
        CHECK(crc.checksum() == 0xEBE6C6E6u);
    }

    {
        boost::crc_32_type crc;
        char const* data = "123456789";
        crc.process_bytes(data, std::strlen(data));
        CHECK(crc.checksum() == 0xCBF43926u);  // standard CRC-32 check value
    }

    {
        boost::crc_32_type crc;
        crc.process_byte('A');
        unsigned a = crc.checksum();
        crc.reset();
        CHECK(crc.checksum() != a);  // reset clears accumulated state
    }

    std::cout << "boost-crc OK\n";
    return 0;
}
