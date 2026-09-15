#include <quirc.h>
#include <stdio.h>
#include <string.h>

int main(void)
{
    /* Check version string */
    const char *version = quirc_version();
    if (!version || strlen(version) == 0) {
        printf("FAIL: quirc_version returned empty\n");
        return 1;
    }
    printf("quirc version: %s\n", version);

    /* Create decoder */
    struct quirc *qr = quirc_new();
    if (!qr) {
        printf("FAIL: quirc_new returned NULL\n");
        return 1;
    }

    /* Resize to a small image */
    if (quirc_resize(qr, 64, 64) != 0) {
        printf("FAIL: quirc_resize failed\n");
        quirc_destroy(qr);
        return 1;
    }

    /* Fill image with all white pixels */
    int w, h;
    uint8_t *buf = quirc_begin(qr, &w, &h);
    if (!buf) {
        printf("FAIL: quirc_begin returned NULL\n");
        quirc_destroy(qr);
        return 1;
    }
    memset(buf, 0xff, w * h);
    quirc_end(qr);

    /* Verify no QR codes in blank image */
    int count = quirc_count(qr);
    if (count != 0) {
        printf("FAIL: quirc_count returned %d, expected 0\n", count);
        quirc_destroy(qr);
        return 1;
    }
    printf("No QR codes in blank image (expected)\n");

    quirc_destroy(qr);
    printf("All tests passed!\n");
    return 0;
}
