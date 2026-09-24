/* Smoke test for the emscripten-forge dSFMT package.
 *
 * Checks the first numbers of the MEXP=19937 reference stream shipped with
 * dSFMT (dSFMT.19937.out.txt) and that the helpers dSFMT.h only declares as
 * `static inline` are exported by the library (Julia ccalls them by name).
 */
#define DSFMT_DO_NOT_USE_OLD_NAMES
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "dSFMT.h"

/* Bind by symbol name: linking fails if libdSFMT does not export them. */
extern void x_init_gen_rand(dsfmt_t *, uint32_t) __asm__("dsfmt_init_gen_rand");
extern void x_init_by_array(dsfmt_t *, uint32_t *, int) __asm__("dsfmt_init_by_array");
extern double x_genrand_close1_open2(dsfmt_t *) __asm__("dsfmt_genrand_close1_open2");
extern double x_genrand_close_open(dsfmt_t *) __asm__("dsfmt_genrand_close_open");
extern uint32_t x_genrand_uint32(dsfmt_t *) __asm__("dsfmt_genrand_uint32");
extern void x_gv_init_gen_rand(uint32_t) __asm__("dsfmt_gv_init_gen_rand");
extern double x_gv_genrand_close1_open2(void) __asm__("dsfmt_gv_genrand_close1_open2");

/* From dSFMT.19937.out.txt */
static const double ref_seed0[4] = {
    1.030581026769374, 1.213140320067012, 1.299002525016001, 1.381138853044628};
static const char *ref_id = "dSFMT2-19937:117-19:ffafffffffb3f-ffdfffc90fffd";

static int close_enough(double a, double b) { return fabs(a - b) < 1e-14; }

int main(void) {
    static dsfmt_t state;
    int failures = 0;

    if (strcmp(dsfmt_get_idstring(), ref_id) != 0) {
        printf("FAIL idstring: %s\n", dsfmt_get_idstring());
        failures++;
    }

    int n = dsfmt_get_min_array_size();
    double *buf = aligned_alloc(16, (size_t)n * sizeof(double));
    x_init_gen_rand(&state, 0);
    dsfmt_fill_array_close1_open2(&state, buf, (ptrdiff_t)n);
    for (int i = 0; i < 4; i++) {
        if (!close_enough(buf[i], ref_seed0[i])) {
            printf("FAIL fill_array[%d] = %.15f, expected %.15f\n", i, buf[i], ref_seed0[i]);
            failures++;
        }
    }

    x_init_gen_rand(&state, 0);
    for (int i = 0; i < 4; i++) {
        double v = x_genrand_close1_open2(&state);
        if (!close_enough(v, ref_seed0[i])) {
            printf("FAIL genrand_close1_open2 #%d = %.15f\n", i, v);
            failures++;
        }
    }

    x_gv_init_gen_rand(0);
    if (!close_enough(x_gv_genrand_close1_open2(), ref_seed0[0])) {
        printf("FAIL gv_genrand_close1_open2\n");
        failures++;
    }

    uint32_t key[4] = {0x1234, 0x5678, 0x9abc, 0xdef0};
    x_init_by_array(&state, key, 4);
    double u = x_genrand_close_open(&state);
    (void)x_genrand_uint32(&state);
    if (!(u >= 0.0 && u < 1.0)) {
        printf("FAIL genrand_close_open out of range: %f\n", u);
        failures++;
    }

    free(buf);
    if (failures == 0)
        printf("dSFMT OK (%s)\n", dsfmt_get_idstring());
    return failures ? 1 : 0;
}
