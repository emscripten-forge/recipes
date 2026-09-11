// Functional test for boost-asio, adapted from the offline
// constructs exercised across libs/asio/test/

#define BOOST_ASIO_DISABLE_THREADS
#include <boost/asio.hpp>
#include <iostream>
#include <string>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

int main()
{
    // executor: posted handlers run synchronously inside io_context::run()
    boost::asio::io_context io;
    int acc = 0;
    boost::asio::post(io, [&]() { acc += 1; });
    boost::asio::post(io, [&]() { acc += 2; });
    CHECK(io.run() == 2); // both handlers executed
    CHECK(acc == 3);

    // buffers: size queries and buffer_copy
    std::string msg = "hello";
    boost::asio::const_buffer cb = boost::asio::buffer(msg);
    CHECK(cb.size() == 5);
    char out[8] = { 0 };
    boost::asio::mutable_buffer mb = boost::asio::buffer(out, 8);
    std::size_t n = boost::asio::buffer_copy(mb, cb);
    CHECK(n == 5);
    CHECK(out[0] == 'h' && out[4] == 'o' && out[5] == '\0');

    // error_code plumbing: create an asio error and check category/value
    boost::system::error_code ec = boost::asio::error::eof;
    CHECK(static_cast<bool>(ec));
    CHECK(ec == boost::asio::error::eof);
    CHECK(ec.message().find("End of file") != std::string::npos);

    std::cout << "boost-asio OK\n";
    return 0;
}
