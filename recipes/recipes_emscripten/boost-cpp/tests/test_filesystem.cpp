// Functional test for boost-filesystem, adapted from
// libs/filesystem/test
#include <boost/filesystem.hpp>
#include <boost/filesystem/fstream.hpp>
#include <boost/system/error_code.hpp>
#include <string>
#include <iostream>

namespace fs = boost::filesystem;

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << std::endl; return 1; } } while (0)

int main()
{
    fs::path cwd = fs::current_path();
    fs::path dir = cwd / "boost_fs_test_dir";

    fs::remove_all(dir);                      // clean slate
    CHECK(fs::create_directory(dir));
    CHECK(fs::is_directory(dir));

    fs::path file = dir / "data.txt";
    {
        fs::ofstream out(file);
        out << "hello";
    }
    CHECK(fs::exists(file));
    CHECK(fs::file_size(file) == 5);
    CHECK(file.filename() == fs::path("data.txt"));
    CHECK(file.extension() == fs::path(".txt"));
    CHECK(file.stem() == fs::path("data"));
    CHECK(file.parent_path() == dir);

    fs::path file2 = dir / "renamed.txt";
    fs::rename(file, file2);
    CHECK(!fs::exists(file));
    CHECK(fs::exists(file2));

    std::string content;
    {
        fs::ifstream in(file2);
        in >> content;
    }
    CHECK(content == "hello");

    CHECK(fs::equivalent(file2, dir / "renamed.txt"));
    fs::remove_all(dir);
    CHECK(!fs::exists(dir));

    // error_code overload must not throw and must report a missing dir
    boost::system::error_code ec;
    fs::remove_all(dir / "nope", ec);
    CHECK(!ec);                                 // removing nothing is not an error

    std::cout << "boost-filesystem OK" << std::endl;
    return 0;
}
