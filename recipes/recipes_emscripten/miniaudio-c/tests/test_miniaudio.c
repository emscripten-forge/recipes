#define MINIAUDIO_IMPLEMENTATION
#include <miniaudio.h>

#include <stdio.h>

int test_version() {
    printf("miniaudio version macros: %u.%u.%u\n",
           MA_VERSION_MAJOR, MA_VERSION_MINOR, MA_VERSION_REVISION);

    if (MA_VERSION_MAJOR == 0 && MA_VERSION_MINOR == 0 && MA_VERSION_REVISION == 0) {
        printf("FAIL: All version numbers are zero\n");
        return 1;
    }

    printf("  PASS: Version macros are valid\n");
    return 0;
}

int test_encoder_format() {
    /* Verify encoding format enum is accessible */
    ma_encoding_format format = ma_encoding_format_wav;
    if (format != ma_encoding_format_wav) {
        printf("FAIL: Encoding format enum mismatch\n");
        return 1;
    }
    printf("  PASS: Encoding format enum accessible\n");
    return 0;
}

int test_decoder_config() {
    ma_decoder_config config = ma_decoder_config_init_default();
    /* Verify the config was initialized (format should be a valid enum value) */
    if (config.format > ma_format_count) {
        printf("FAIL: Invalid decoder config format: %d\n", (int)config.format);
        return 1;
    }
    printf("  Default decoder config format: %d, channels: %u, sampleRate: %u\n",
           (int)config.format, config.channels, config.sampleRate);
    printf("  PASS: Decoder config initialized correctly\n");
    return 0;
}

int main() {
    int failures = 0;

    printf("=== miniaudio tests ===\n\n");

    printf("test_version...\n");
    failures += test_version();
    printf("\n");

    printf("test_encoder_format...\n");
    failures += test_encoder_format();
    printf("\n");

    printf("test_decoder_config...\n");
    failures += test_decoder_config();
    printf("\n");

    if (failures == 0) {
        printf("All tests passed!\n");
        return 0;
    } else {
        printf("%d test(s) failed!\n", failures);
        return 1;
    }
}
