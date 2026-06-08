#include <simde/x86/sse.h>
#include <stdio.h>
#include <stdlib.h>

int main(void) {
    /* Set all four elements to 1.0 */
    simde__m128 a = simde_mm_set1_ps(1.0f);
    simde__m128 b = simde_mm_set1_ps(2.0f);

    /* Add them: should get all 3.0 */
    simde__m128 r = simde_mm_add_ps(a, b);

    float result[4];
    simde_mm_storeu_ps(result, r);

    int failed = 0;
    for (int i = 0; i < 4; i++) {
        if (result[i] != 3.0f) {
            printf("FAIL: result[%d] = %f, expected 3.0\n", i, result[i]);
            failed = 1;
        }
    }

    if (!failed) {
        printf("PASS: simde_mm_add_ps works correctly\n");
    }

    /* Also test a store operation */
    float src[4] = {4.0f, 5.0f, 6.0f, 7.0f};
    simde__m128 loaded = simde_mm_loadu_ps(src);
    float loaded_result[4];
    simde_mm_storeu_ps(loaded_result, loaded);

    for (int i = 0; i < 4; i++) {
        if (loaded_result[i] != src[i]) {
            printf("FAIL: load/store result[%d] = %f, expected %f\n",
                   i, loaded_result[i], src[i]);
            failed = 1;
        }
    }

    if (!failed) {
        printf("PASS: simde_mm_loadu_ps/simde_mm_storeu_ps works correctly\n");
    }

    return failed ? EXIT_FAILURE : EXIT_SUCCESS;
}
