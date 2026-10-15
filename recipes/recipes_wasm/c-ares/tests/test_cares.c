#include <ares.h>
#include <stdio.h>
#include <string.h>

int main() {
    int status;
    ares_channel channel;
    struct ares_options options;

    /* Initialize the c-ares library */
    status = ares_library_init(ARES_LIB_INIT_ALL);
    if (status != ARES_SUCCESS) {
        fprintf(stderr, "ares_library_init failed: %s\n", ares_strerror(status));
        return 1;
    }

    /* Initialize a channel with options (exercises the options API) */
    memset(&options, 0, sizeof(options));
    options.timeout = 1000;
    options.tries = 1;

    status = ares_init_options(&channel, &options, ARES_OPT_TIMEOUTMS | ARES_OPT_TRIES);
    if (status != ARES_SUCCESS) {
        fprintf(stderr, "ares_init_options failed: %s\n", ares_strerror(status));
        ares_library_cleanup();
        return 1;
    }

    /* Verify version string is available */
    const char *version = ares_version(NULL);
    printf("c-ares version: %s\n", version);
    if (version == NULL || strlen(version) == 0) {
        fprintf(stderr, "ares_version returned invalid version\n");
        ares_destroy(channel);
        ares_library_cleanup();
        return 1;
    }

    /* Cleanup */
    ares_destroy(channel);
    ares_library_cleanup();

    printf("c-ares real test passed\n");
    return 0;
}
