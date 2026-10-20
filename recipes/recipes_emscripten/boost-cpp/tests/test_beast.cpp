// Functional test for boost-beast , adapted from the offline
// parser patterns in libs/beast/test/beast/http/basic_parser.cpp


#define BOOST_ASIO_DISABLE_THREADS
#include <boost/beast.hpp>
#include <boost/asio/buffer.hpp>
#include <boost/system/error_code.hpp>
#include <iostream>
#include <string>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

int main()
{
    namespace http = boost::beast::http;

    // parse a complete HTTP/1.1 request out of one flat buffer
    std::string raw =
        "GET /index.html HTTP/1.1\r\n"
        "Host: example.com\r\n"
        "User-Agent: boost-test\r\n"
        "\r\n";

    boost::system::error_code ec;
    http::request_parser<http::string_body> parser;
    std::size_t used = parser.put(boost::asio::buffer(raw), ec);
    CHECK(!ec);
    CHECK(used == raw.size());
    CHECK(parser.is_done());

    http::request<http::string_body> const& req = parser.get();
    CHECK(req.method() == http::verb::get);
    CHECK(req.target() == "/index.html");
    CHECK(req.version() == 11);
    CHECK(req[http::field::host] == "example.com");
    CHECK(req.body().empty());

    // body arriving in pieces: parser is not done until all bytes arrive
    std::string feed = "POST /api HTTP/1.1\r\nContent-Length: 4\r\n\r\nab";
    boost::system::error_code ec2;
    http::request_parser<http::string_body> parser2;
    parser2.eager(true);
    std::size_t used2 = parser2.put(boost::asio::buffer(feed), ec2);
    CHECK(!parser2.is_done());
    // re-send whatever was not consumed, plus the final body chunk
    std::string rest = feed.substr(used2) + "cd";
    parser2.put(boost::asio::buffer(rest), ec2);
    CHECK(!ec2);
    CHECK(parser2.is_done());
    CHECK(parser2.get().body() == "abcd");

    std::cout << "boost-beast OK\n";
    return 0;
}
