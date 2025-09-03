// Simple test to verify soxr headers can be included
#include <soxr.h>
#include <stdio.h>

int main() {
    printf("soxr version: %s\n", soxr_version());
    return 0;
}