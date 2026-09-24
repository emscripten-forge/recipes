#include <stdio.h>
#include <math.h>
#include <gnu/libc-version.h>

int main(void) {
    printf("i686 glibc %s: sizeof(long)=%zu sqrt(2)=%.6f\n",
           gnu_get_libc_version(), sizeof(long), sqrt(2.0));
    return sizeof(long) == 4 ? 0 : 1;
}
