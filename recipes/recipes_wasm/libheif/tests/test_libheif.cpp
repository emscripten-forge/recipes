#include <libheif/heif.h>
#include <cstdio>
#include <cstdlib>
#include <cstring>

int main(void)
{
    /* 1. Test version string */
    const char* version = heif_get_version();
    if (!version || strlen(version) == 0) {
        printf("FAIL: heif_get_version() returned empty/null\n");
        return 1;
    }
    printf("libheif version: %s\n", version);

    /* 2. Test version number */
    uint32_t ver_num = heif_get_version_number();
    printf("libheif version number: %u\n", ver_num);

    /* 3. Test context alloc/free */
    heif_context* ctx = heif_context_alloc();
    if (!ctx) {
        printf("FAIL: heif_context_alloc() returned NULL\n");
        return 1;
    }

    /* 4. Test file type checking with invalid data */
    unsigned char buf[12] = {0};
    enum heif_filetype_result ft = heif_check_filetype(buf, 12);
    printf("heif_check_filetype result on zero buffer: %d (expected %d = no)\n",
           (int)ft, (int)heif_filetype_no);

    /* 5. Test MIME type detection */
    const char* mime = heif_get_file_mime_type(buf, 12);
    printf("MIME type on zero buffer: %s\n", mime ? mime : "(null)");

    heif_context_free(ctx);

    printf("All tests passed!\n");
    return 0;
}
