#include <curl/curl.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

static int test_version(void) {
    curl_version_info_data *data;
    
    /* Test 1: curl_version() returns a non-empty string */
    const char *version = curl_version();
    if (version == NULL || version[0] == '\0') {
        fprintf(stderr, "FAIL: curl_version() returned empty or NULL\n");
        return 1;
    }
    printf("PASS: curl_version() = %s\n", version);
    
    /* Test 2: curl_version_info() returns valid data */
    data = curl_version_info(CURLVERSION_NOW);
    if (data == NULL) {
        fprintf(stderr, "FAIL: curl_version_info() returned NULL\n");
        return 1;
    }
    if (data->version == NULL || data->version[0] == '\0') {
        fprintf(stderr, "FAIL: curl_version_info()->version is empty\n");
        return 1;
    }
    printf("PASS: libcurl version = %s\n", data->version);
    
    /* Test 3: Check that SSL (OpenSSL) is available */
    if (!(data->features & CURL_VERSION_SSL)) {
        fprintf(stderr, "FAIL: SSL support not detected\n");
        return 1;
    }
    if (data->ssl_version == NULL || data->ssl_version[0] == '\0') {
        fprintf(stderr, "FAIL: SSL version string is empty\n");
        return 1;
    }
    printf("PASS: SSL backend = %s\n", data->ssl_version);
    
    /* Test 4: Check that zlib is available */
    if (!(data->features & CURL_VERSION_LIBZ)) {
        fprintf(stderr, "FAIL: zlib support not detected\n");
        return 1;
    }
    printf("PASS: zlib support detected\n");
    
    return 0;
}

static int test_easy_handle(void) {
    CURL *curl;
    CURLcode res;
    
    /* Test 5: curl_easy_init() succeeds */
    curl = curl_easy_init();
    if (curl == NULL) {
        fprintf(stderr, "FAIL: curl_easy_init() returned NULL\n");
        return 1;
    }
    printf("PASS: curl_easy_init() succeeded\n");
    
    /* Test 6: Set a basic option */
    res = curl_easy_setopt(curl, CURLOPT_URL, "https://example.com");
    if (res != CURLE_OK) {
        fprintf(stderr, "FAIL: curl_easy_setopt(CURLOPT_URL) failed: %s\n",
                curl_easy_strerror(res));
        curl_easy_cleanup(curl);
        return 1;
    }
    printf("PASS: curl_easy_setopt(CURLOPT_URL) succeeded\n");
    
    /* Test 7: Set timeout option */
    res = curl_easy_setopt(curl, CURLOPT_TIMEOUT, 30L);
    if (res != CURLE_OK) {
        fprintf(stderr, "FAIL: curl_easy_setopt(CURLOPT_TIMEOUT) failed: %s\n",
                curl_easy_strerror(res));
        curl_easy_cleanup(curl);
        return 1;
    }
    printf("PASS: curl_easy_setopt(CURLOPT_TIMEOUT) succeeded\n");
    
    /* Test 8: Set SSL options */
    res = curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, 0L);
    if (res != CURLE_OK) {
        fprintf(stderr, "FAIL: curl_easy_setopt(CURLOPT_SSL_VERIFYPEER) failed: %s\n",
                curl_easy_strerror(res));
        curl_easy_cleanup(curl);
        return 1;
    }
    printf("PASS: curl_easy_setopt(CURLOPT_SSL_VERIFYPEER) succeeded\n");
    
    /* Test 9: curl_easy_cleanup() - basic cleanup */
    curl_easy_cleanup(curl);
    printf("PASS: curl_easy_cleanup() succeeded\n");
    
    return 0;
}

static int test_escape(void) {
    CURL *curl;
    char *escaped, *unescaped;
    const char *input = "hello world!@#$";
    const char *expected = "hello%20world%21%40%23%24";
    
    curl = curl_easy_init();
    if (curl == NULL) {
        fprintf(stderr, "FAIL: curl_easy_init() for escape test returned NULL\n");
        return 1;
    }
    
    /* Test 10: URL escape */
    escaped = curl_easy_escape(curl, input, (int)strlen(input));
    if (escaped == NULL) {
        fprintf(stderr, "FAIL: curl_easy_escape() returned NULL\n");
        curl_easy_cleanup(curl);
        return 1;
    }
    if (strcmp(escaped, expected) != 0) {
        fprintf(stderr, "FAIL: curl_easy_escape() expected '%s', got '%s'\n",
                expected, escaped);
        curl_free(escaped);
        curl_easy_cleanup(curl);
        return 1;
    }
    printf("PASS: curl_easy_escape() = %s\n", escaped);
    
    /* Test 11: URL unescape */
    unescaped = curl_easy_unescape(curl, escaped, 0, NULL);
    if (unescaped == NULL) {
        fprintf(stderr, "FAIL: curl_easy_unescape() returned NULL\n");
        curl_free(escaped);
        curl_easy_cleanup(curl);
        return 1;
    }
    if (strcmp(unescaped, input) != 0) {
        fprintf(stderr, "FAIL: curl_easy_unescape() expected '%s', got '%s'\n",
                input, unescaped);
        curl_free(escaped);
        curl_free(unescaped);
        curl_easy_cleanup(curl);
        return 1;
    }
    printf("PASS: curl_easy_unescape() = %s\n", unescaped);
    
    curl_free(escaped);
    curl_free(unescaped);
    curl_easy_cleanup(curl);
    return 0;
}

int main(void) {
    int failures = 0;
    
    printf("=== libcurl smoke tests ===\n\n");
    
    /* Initialize global state */
    curl_global_init(CURL_GLOBAL_ALL);
    
    failures += test_version();
    printf("\n");
    
    failures += test_easy_handle();
    printf("\n");
    
    failures += test_escape();
    printf("\n");
    
    /* Cleanup global state */
    curl_global_cleanup();
    
    if (failures > 0) {
        fprintf(stderr, "FAILED: %d test(s) failed\n", failures);
        return 1;
    }
    
    printf("All tests passed!\n");
    return 0;
}
