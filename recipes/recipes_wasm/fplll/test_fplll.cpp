#include <cstdio>
#include <cstdlib>

#include <fplll.h>

#define CHECK(cond)                                                          \
    do {                                                                     \
        if (!(cond)) {                                                       \
            std::fprintf(stderr, "line %d: CHECK failed: %s\n", __LINE__, #cond); \
            std::exit(1);                                                    \
        }                                                                    \
    } while (0)

using namespace fplll;

static long det3(ZZ_mat<mpz_t> &b) {
    long m[3][3];
    for (int i = 0; i < 3; ++i)
        for (int j = 0; j < 3; ++j)
            m[i][j] = b[i][j].get_si();
    return m[0][0] * (m[1][1] * m[2][2] - m[1][2] * m[2][1]) -
           m[0][1] * (m[1][0] * m[2][2] - m[1][2] * m[2][0]) +
           m[0][2] * (m[1][0] * m[2][1] - m[1][1] * m[2][0]);
}

int main() {
    CHECK(get_threads() == 1);

    // a skewed basis of Z^3 (determinant 1)
    const long rows[3][3] = {{1, 1, 1}, {1, 2, 3}, {1, 3, 6}};
    ZZ_mat<mpz_t> b(3, 3);
    for (int i = 0; i < 3; ++i)
        for (int j = 0; j < 3; ++j)
            b[i][j] = rows[i][j];
    CHECK(det3(b) == 1);

    CHECK(lll_reduction(b) == RED_SUCCESS);

    // LLL keeps the lattice (|det| = 1) and the reduced basis of Z^3
    // consists of unit vectors
    long d = det3(b);
    CHECK(d == 1 || d == -1);
    for (int i = 0; i < 3; ++i) {
        long norm2 = 0;
        for (int j = 0; j < 3; ++j)
            norm2 += b[i][j].get_si() * b[i][j].get_si();
        CHECK(norm2 == 1);
    }

    std::printf("fplll test passed\n");
    return 0;
}
