#include <stdio.h>
#include <string.h>

#include <zenoh-pico.h>

#define CHECK(cond)                                                        \
    do {                                                                   \
        if (!(cond)) {                                                     \
            fprintf(stderr, "line %d: CHECK failed: %s\n", __LINE__, #cond); \
            return 1;                                                      \
        }                                                                  \
    } while (0)

int main(void) {
    // config (no session is opened: that needs a zenoh router)
    z_owned_config_t config;
    CHECK(z_config_default(&config) == Z_OK);
    CHECK(zp_config_insert(z_loan_mut(config), Z_CONFIG_CONNECT_KEY, "ws/127.0.0.1:10000") == Z_OK);
    z_drop(z_move(config));

    // key expressions
    z_view_keyexpr_t a, b;
    CHECK(z_view_keyexpr_from_str(&a, "demo/**") == Z_OK);
    CHECK(z_view_keyexpr_from_str(&b, "demo/example/test") == Z_OK);
    CHECK(z_keyexpr_includes(z_loan(a), z_loan(b)));
    CHECK(z_keyexpr_intersects(z_loan(a), z_loan(b)));

    // payload round trip
    const char *msg = "hello zenoh";
    z_owned_bytes_t payload;
    CHECK(z_bytes_copy_from_str(&payload, msg) == Z_OK);
    z_owned_string_t s;
    CHECK(z_bytes_to_string(z_loan(payload), &s) == Z_OK);
    CHECK(z_string_len(z_loan(s)) == strlen(msg));
    CHECK(strncmp(z_string_data(z_loan(s)), msg, strlen(msg)) == 0);
    z_drop(z_move(s));
    z_drop(z_move(payload));

    printf("zenoh-pico test passed\n");
    return 0;
}
