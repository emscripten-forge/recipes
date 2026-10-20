// Functional test for boost-iostreams, adapted from
// libs/iostreams/test/file_test.cpp (file_source/file_sink, no zlib/bzip2)

#include <boost/iostreams/device/file.hpp>
#include <boost/iostreams/stream.hpp>
#include <iterator>
#include <string>
#include <cstdio>

int main()
{
    const char* path = "iostreams_roundtrip.txt";

    {
        boost::iostreams::stream<boost::iostreams::file_sink> out(path);
        out << "line one\nline two\nline three\n";
    } // sink closed -> file flushed

    std::string content;
    {
        boost::iostreams::stream<boost::iostreams::file_source> in(path);
        content.assign(std::istreambuf_iterator<char>(in),
                       std::istreambuf_iterator<char>());
    }

    std::remove(path);
    return content == "line one\nline two\nline three\n" ? 0 : 1;
}