// Functional test for boost-mqtt5 , adapted from
// libs/mqtt5/test and libs/mqtt5/example/hello_world_over_tcp.cpp

#include <boost/mqtt5/error.hpp>
#include <boost/mqtt5/property_types.hpp>
#include <boost/mqtt5/reason_codes.hpp>
#include <boost/mqtt5/types.hpp>
#include <iostream>
#include <string>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

int main()
{
    namespace rc = boost::mqtt5::reason_codes;

    // MQTT v5 reason codes carry their wire value.
    CHECK(rc::success.value() == 0x00u);
    CHECK(rc::normal_disconnection.value() == 0x00u);
    CHECK(rc::malformed_packet.value() == 0x81u);
    CHECK(rc::unspecified_error.value() == 0x80u);
    CHECK(rc::granted_qos_2.value() == 0x02u);
    CHECK(!(rc::success == rc::malformed_packet));
    CHECK(!rc::success.message().empty());

    // Will message: real client state (topic, payload, delivery options).
    boost::mqtt5::will w("sensors/temp", "21.5",
                         boost::mqtt5::qos_e::at_least_once,
                         boost::mqtt5::retain_e::yes);
    CHECK(w.topic() == "sensors/temp");
    CHECK(w.message() == "21.5");
    CHECK(w.qos() == boost::mqtt5::qos_e::at_least_once);
    CHECK(w.retain() == boost::mqtt5::retain_e::yes);

    // Publish properties: values set through the typed property key are read
    // back from the same slot.
    boost::mqtt5::publish_props props;
    props[boost::mqtt5::prop::message_expiry_interval] = 60u;
    CHECK(props[boost::mqtt5::prop::message_expiry_interval] == 60u);
    props[boost::mqtt5::prop::topic_alias] = 5u;
    CHECK(props[boost::mqtt5::prop::topic_alias] == 5u);

    // Client error codes: stable category + human message.
    namespace client = boost::mqtt5::client;
    boost::system::error_code ec = client::make_error_code(client::error::invalid_topic);
    CHECK(static_cast<bool>(ec));
    CHECK(ec.category().name() == std::string("mqtt_client_error"));
    CHECK(client::client_error_to_string(client::error::invalid_topic) ==
          "The Topic is invalid and does not conform to the specification");
    CHECK(client::make_error_code(client::error::malformed_packet) != ec);

    std::cout << "boost-mqtt5 OK\n";
    return 0;
}
