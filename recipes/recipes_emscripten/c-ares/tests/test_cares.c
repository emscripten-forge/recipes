#include <ares.h>
#include <stdio.h>

int main() {
    const char *version = ares_version(NULL);
    printf("c-ares version: %s\n", version);
    return 0;
}
