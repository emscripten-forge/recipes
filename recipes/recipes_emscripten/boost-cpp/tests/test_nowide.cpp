// Functional test for boost-nowide, adapted from
// libs/nowide/test/test_fstream.cpp

#include <boost/nowide/cstdio.hpp>
#include <cstdio>
#include <cstring>

int main()
{
    const char* path = "nowide_roundtrip.txt";
    const char msg[] = "hello nowide";
    const size_t len = sizeof(msg) - 1;

    FILE* f = boost::nowide::fopen(path, "w");
    if (!f) return 1;
    if (std::fwrite(msg, 1, len, f) != len)
    {
        std::fclose(f);
        return 1;
    }
    std::fclose(f);

    // file exists check, then read back
    f = boost::nowide::fopen(path, "r");
    if (!f) return 1;
    char buf[32] = {0};
    size_t n = std::fread(buf, 1, len, f);
    std::fclose(f);
    if (boost::nowide::remove(path) != 0) return 1;

    return (n == len && std::strcmp(buf, msg) == 0) ? 0 : 1;
}