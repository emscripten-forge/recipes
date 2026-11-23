#include <ghostty/vt.h>
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define API_FUNCTIONS(X) \
    X(ghostty_osc_new) \
    X(ghostty_osc_free) \
    X(ghostty_terminal_new) \
    X(ghostty_terminal_free) \
    X(ghostty_terminal_vt_write) \
    X(ghostty_formatter_terminal_new) \
    X(ghostty_formatter_format_alloc) \
    X(ghostty_formatter_free) \
    X(ghostty_free)

#ifdef TEST_DYNAMIC
#include <dlfcn.h>
#define DECLARE(name) static __typeof__(&name) api_##name;
API_FUNCTIONS(DECLARE)
#define API(name) api_##name
#else
#define API(name) name
#endif

int main(void) {
#ifdef TEST_DYNAMIC
    void *handle = dlopen("/libghostty-vt.so", RTLD_NOW | RTLD_LOCAL);
    if (!handle) {
        fprintf(stderr, "dlopen: %s\n", dlerror());
        return 1;
    }
#define LOAD(name) \
    api_##name = (__typeof__(&name))dlsym(handle, #name); \
    assert(api_##name != NULL);
    API_FUNCTIONS(LOAD)
#endif

    puts("Testing OSC parser allocation");
    fflush(stdout);
    GhosttyOscParser osc = NULL;
    assert(API(ghostty_osc_new)(NULL, &osc) == GHOSTTY_SUCCESS);
    API(ghostty_osc_free)(osc);

    /* Default allocation must use the same libc heap as the embedding runtime. */
    for (int i = 0; i < 20; ++i) {
        if (i == 0) { puts("Testing terminal allocation"); fflush(stdout); }
        GhosttyTerminal terminal = NULL;
        assert(API(ghostty_terminal_new)(NULL, &terminal, 80, 24) == GHOSTTY_SUCCESS);
        if (i == 0) { puts("Testing VT input"); fflush(stdout); }
        const char *text = "\033[31mhello wasm\033[0m\r\n";
        API(ghostty_terminal_vt_write)(terminal, (const uint8_t *)text, strlen(text));
        if (i == 0) { puts("Testing serialization"); fflush(stdout); }
        GhosttyFormatter formatter = NULL;
        assert(API(ghostty_formatter_terminal_new)(NULL, &formatter, terminal) == GHOSTTY_SUCCESS);
        uint8_t *buffer = NULL;
        size_t length = 0;
        assert(API(ghostty_formatter_format_alloc)(formatter, NULL, &buffer, &length) == GHOSTTY_SUCCESS);
        char *copy = malloc(length + 1);
        assert(copy != NULL);
        memcpy(copy, buffer, length);
        copy[length] = '\0';
        assert(strstr(copy, "hello wasm") != NULL);
        free(copy);
        API(ghostty_free)(NULL, buffer, length);
        API(ghostty_formatter_free)(formatter);
        API(ghostty_terminal_free)(terminal);
    }
#ifdef TEST_DYNAMIC
    assert(dlclose(handle) == 0);
#endif
    puts("libghostty-vt C API smoke test passed");
    return 0;
}
