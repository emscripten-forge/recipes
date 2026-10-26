#include "rebound.h"
#include <stdio.h>

int main() {
    struct reb_simulation* r = reb_simulation_create();
    if (r == NULL) {
        fprintf(stderr, "Failed to create simulation\n");
        return 1;
    }

    reb_simulation_add(r, (struct reb_particle){
        .m = 1.0,
    });
    reb_simulation_add(r, (struct reb_particle){
        .m = 1.0e-3,
        .x = 1.0,
        .vy = 1.0,
    });

    if (r->N != 2) {
        fprintf(stderr, "Expected 2 particles, got %zu\n", r->N);
        reb_simulation_free(r);
        return 1;
    }

    reb_simulation_integrate(r, 10.0);

    if (r->t < 9.0 || r->t > 11.0) {
        fprintf(stderr, "Expected t~10.0, got %f\n", r->t);
        reb_simulation_free(r);
        return 1;
    }

    printf("OK: librebound C test passed\n");
    reb_simulation_free(r);
    return 0;
}
