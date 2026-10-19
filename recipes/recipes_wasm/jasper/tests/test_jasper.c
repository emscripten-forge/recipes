#include <jasper/jasper.h>
#include <jasper/jas_image.h>

int main(void)
{
    /* Configure and initialize the JasPer library (modern API). */
    jas_conf_clear();
    jas_conf_set_max_mem_usage(256 * 1024 * 1024);
    if (jas_init_library()) {
        return 1;
    }
    if (jas_init_thread()) {
        jas_cleanup_library();
        return 1;
    }

    /* Create a small 3-component RGB image (64x64). */
    jas_image_cmptparm_t cmptparms[3];
    for (unsigned i = 0; i < 3; ++i) {
        cmptparms[i].tlx = 0;
        cmptparms[i].tly = 0;
        cmptparms[i].hstep = 1;
        cmptparms[i].vstep = 1;
        cmptparms[i].width = 64;
        cmptparms[i].height = 64;
        cmptparms[i].prec = 8;
        cmptparms[i].sgnd = 0;
    }

    jas_image_t *image = jas_image_create(3, cmptparms, JAS_CLRSPC_SRGB);
    if (!image) {
        jas_cleanup_thread();
        jas_cleanup_library();
        return 1;
    }

    /* Verify the image dimensions. */
    if (jas_image_width(image) != 64 || jas_image_height(image) != 64) {
        jas_image_destroy(image);
        jas_cleanup_thread();
        jas_cleanup_library();
        return 1;
    }

    /* Verify the image has 3 components. */
    if (jas_image_numcmpts(image) != 3) {
        jas_image_destroy(image);
        jas_cleanup_thread();
        jas_cleanup_library();
        return 1;
    }

    /* Clean up. */
    jas_image_destroy(image);
    jas_cleanup_thread();
    jas_cleanup_library();

    return 0;
}
