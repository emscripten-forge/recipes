#include <fxdiv.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

static int failures = 0;

#define CHECK(cond, msg) \
    do { \
        if (!(cond)) { \
            fprintf(stderr, "FAIL: %s\n", msg); \
            failures++; \
        } else { \
            printf("PASS: %s\n", msg); \
        } \
    } while (0)

static void test_uint32(void) {
    /* Basic quotient and remainder */
    const struct fxdiv_divisor_uint32_t div7 = fxdiv_init_uint32_t(7);
    CHECK(fxdiv_quotient_uint32_t(100, div7) == 100u / 7u, "quotient 100/7");
    CHECK(fxdiv_remainder_uint32_t(100, div7) == 100u % 7u, "remainder 100%7");

    /* divide returns both quotient and remainder */
    const struct fxdiv_result_uint32_t r = fxdiv_divide_uint32_t(1000, div7);
    CHECK(r.quotient == 1000u / 7u, "divide quotient 1000/7");
    CHECK(r.remainder == 1000u % 7u, "divide remainder 1000%7");

    /* round_down */
    CHECK(fxdiv_round_down_uint32_t(13, div7) == 7u, "round_down 13 by 7");
    CHECK(fxdiv_round_down_uint32_t(14, div7) == 14u, "round_down 14 by 7");

    /* divisor of 1 */
    const struct fxdiv_divisor_uint32_t div1 = fxdiv_init_uint32_t(1);
    CHECK(fxdiv_quotient_uint32_t(42, div1) == 42u, "quotient 42/1");
    CHECK(fxdiv_remainder_uint32_t(42, div1) == 0u, "remainder 42%1");

    /* power-of-2 divisor */
    const struct fxdiv_divisor_uint32_t div8 = fxdiv_init_uint32_t(8);
    CHECK(fxdiv_quotient_uint32_t(256, div8) == 32u, "quotient 256/8");
    CHECK(fxdiv_remainder_uint32_t(255, div8) == 7u, "remainder 255%8");
}

static void test_uint64(void) {
    const struct fxdiv_divisor_uint64_t div13 = fxdiv_init_uint64_t(13);
    CHECK(fxdiv_quotient_uint64_t(UINT64_C(1000000000), div13) ==
          UINT64_C(1000000000) / UINT64_C(13), "quotient 1e9/13");
    CHECK(fxdiv_remainder_uint64_t(UINT64_C(1000000000), div13) ==
          UINT64_C(1000000000) % UINT64_C(13), "remainder 1e9%13");

    const struct fxdiv_result_uint64_t r =
        fxdiv_divide_uint64_t(UINT64_C(999999999999), div13);
    CHECK(r.quotient  == UINT64_C(999999999999) / UINT64_C(13), "divide quotient large/13");
    CHECK(r.remainder == UINT64_C(999999999999) % UINT64_C(13), "divide remainder large%13");

    /* divisor of 1 */
    const struct fxdiv_divisor_uint64_t div1 = fxdiv_init_uint64_t(1);
    CHECK(fxdiv_quotient_uint64_t(UINT64_C(999), div1) == UINT64_C(999), "quotient 999/1");
}

static void test_size_t(void) {
    const struct fxdiv_divisor_size_t div5 = fxdiv_init_size_t(5);
    CHECK(fxdiv_quotient_size_t(100, div5) == (size_t)(100 / 5), "quotient 100/5 (size_t)");
    CHECK(fxdiv_remainder_size_t(103, div5) == (size_t)(103 % 5), "remainder 103%5 (size_t)");

    const struct fxdiv_result_size_t r = fxdiv_divide_size_t(99, div5);
    CHECK(r.quotient  == (size_t)(99 / 5), "divide quotient 99/5 (size_t)");
    CHECK(r.remainder == (size_t)(99 % 5), "divide remainder 99%5 (size_t)");
}

int main(void) {
    test_uint32();
    test_uint64();
    test_size_t();

    if (failures > 0) {
        fprintf(stderr, "%d test(s) FAILED\n", failures);
        return 1;
    }
    printf("All tests passed.\n");
    return 0;
}
