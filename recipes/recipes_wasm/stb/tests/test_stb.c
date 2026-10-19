#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"
#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image_write.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static unsigned char* bmp_buf = NULL;
static size_t bmp_size = 0;
static size_t bmp_cap = 0;

static void write_callback(void* context, void* data, int size) {
    (void)context;
    if (bmp_size + (size_t)size > bmp_cap) {
        bmp_cap = bmp_cap ? bmp_cap * 2 : (size_t)size;
        bmp_buf = (unsigned char*)realloc(bmp_buf, bmp_cap);
    }
    memcpy(bmp_buf + bmp_size, data, (size_t)size);
    bmp_size += (size_t)size;
}

int main(void) {
    int failures = 0;

    /* 2x2 RGB image: red, green, blue, white */
    unsigned char pixels[2 * 2 * 3] = {
        255, 0, 0,   0, 255, 0,
        0, 0, 255,   255, 255, 255
    };

    /* Write BMP to memory via callback */
    if (!stbi_write_bmp_to_func(write_callback, NULL, 2, 2, 3, pixels)) {
        fprintf(stderr, "FAIL: stbi_write_bmp_to_func returned 0\n");
        failures++;
    } else {
        printf("PASS: wrote %zu-byte BMP to memory\n", bmp_size);

        /* Read it back with stb_image */
        int w = 0, h = 0, n = 0;
        unsigned char* loaded = stbi_load_from_memory(
            bmp_buf, (int)bmp_size, &w, &h, &n, 0);
        if (!loaded) {
            fprintf(stderr, "FAIL: stbi_load_from_memory: %s\n",
                    stbi_failure_reason());
            failures++;
        } else {
            if (w != 2 || h != 2) {
                fprintf(stderr, "FAIL: expected 2x2, got %dx%d\n", w, h);
                failures++;
            } else {
                printf("PASS: loaded BMP: %dx%d channels=%d\n", w, h, n);
            }
            stbi_image_free(loaded);
        }
    }

    /* Test stbi_set_flip_vertically_on_load (no-op API call) */
    stbi_set_flip_vertically_on_load(1);
    stbi_set_flip_vertically_on_load(0);

    free(bmp_buf);

    if (failures > 0) {
        fprintf(stderr, "%d test(s) FAILED\n", failures);
        return 1;
    }
    printf("All tests passed.\n");
    return 0;
}
