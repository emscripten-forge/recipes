#include <cstdio>
#include <cstdlib>
#include <vector>

#include "gfanlib.h"

#define CHECK(cond)                                                          \
    do {                                                                     \
        if (!(cond)) {                                                       \
            std::fprintf(stderr, "line %d: CHECK failed: %s\n", __LINE__, #cond); \
            std::exit(1);                                                    \
        }                                                                    \
    } while (0)

int main() {
    gfan::initializeCddlibIfRequired();

    // cones (via cddlib)
    gfan::ZCone orthant = gfan::ZCone::positiveOrthant(3);
    CHECK(orthant.dimension() == 3);
    CHECK(orthant.dimensionOfLinealitySpace() == 0);
    gfan::ZVector inside(3), outside(3);
    inside[0] = 1; inside[1] = 2; inside[2] = 3;
    outside[0] = 1; outside[1] = -2; outside[2] = 3;
    CHECK(orthant.contains(inside));
    CHECK(!orthant.contains(outside));

    // x_0 >= 0, x_1 >= 0 and x_2 = 0: a 2-dimensional cone
    gfan::ZMatrix ineq(0, 3), eq(0, 3);
    gfan::ZVector e0(3), e1(3), e2(3);
    e0[0] = 1; e1[1] = 1; e2[2] = 1;
    ineq.appendRow(e0);
    ineq.appendRow(e1);
    eq.appendRow(e2);
    gfan::ZCone face(ineq, eq);
    CHECK(face.dimension() == 2);

    // mixed volume (BKK bound) of the cyclic 5-roots system is 70,
    // computed without threads (nthreads = 0)
    gfan::Integer mv = gfan::mixedVolume(gfan::MixedVolumeExamples::cyclic(5));
    CHECK(mv.toInt() == 70);

    gfan::deinitializeCddlibIfRequired();
    std::printf("gfanlib test passed\n");
    return 0;
}
