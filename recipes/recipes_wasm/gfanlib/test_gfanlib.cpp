#include <cstdio>
#include <cstdlib>
#include <initializer_list>
#include <vector>

#include "gfanlib.h"

#define CHECK(cond)                                                          \
    do {                                                                     \
        if (!(cond)) {                                                       \
            std::fprintf(stderr, "line %d: CHECK failed: %s\n", __LINE__, #cond); \
            std::exit(1);                                                    \
        }                                                                    \
    } while (0)

// ---------------------------------------------------------------------------
// Matrix::operator*(Matrix, Matrix) (patched, see patches/0001), tested for
// all three matrix types: IntMatrix, ZMatrix (gmp integers), QMatrix (gmp
// rationals)
// ---------------------------------------------------------------------------

template <class typ>
gfan::Matrix<typ> from_rows(int height, int width, std::initializer_list<long> values) {
    CHECK((int)values.size() == height * width);
    gfan::Matrix<typ> m(height, width);
    auto it = values.begin();
    for (int i = 0; i < height; ++i)
        for (int j = 0; j < width; ++j)
            m[i][j] = typ(*it++);
    return m;
}

template <class typ>
bool equal(const gfan::Matrix<typ> &a, const gfan::Matrix<typ> &b) {
    if (a.getHeight() != b.getHeight() || a.getWidth() != b.getWidth())
        return false;
    for (int i = 0; i < a.getHeight(); ++i)
        for (int j = 0; j < a.getWidth(); ++j)
            if (!(a[i][j] == b[i][j]))
                return false;
    return true;
}

template <class typ>
void test_matrix_product() {
    using M = gfan::Matrix<typ>;
    const M a = from_rows<typ>(2, 3, {1, 2, 3,
                                      4, 5, 6});
    const M b = from_rows<typ>(3, 2, {7, 8,
                                      9, 10,
                                      11, 12});
    const M c = from_rows<typ>(2, 2, {1, -1,
                                      2, 0});

    // non-square shapes in both orders
    M ab = a * b;
    CHECK(ab.getHeight() == 2 && ab.getWidth() == 2);
    CHECK(equal(ab, from_rows<typ>(2, 2, {58, 64,
                                          139, 154})));
    M ba = b * a;
    CHECK(ba.getHeight() == 3 && ba.getWidth() == 3);
    CHECK(equal(ba, from_rows<typ>(3, 3, {39, 54, 69,
                                          49, 68, 87,
                                          59, 82, 105})));

    // negative entries
    CHECK(equal(ab * c, from_rows<typ>(2, 2, {186, -58,
                                              447, -139})));

    // identities on both sides
    CHECK(equal(M::identity(2) * a, a));
    CHECK(equal(a * M::identity(3), a));

    // associativity and (AB)^T = B^T A^T
    CHECK(equal((a * b) * c, a * (b * c)));
    CHECK(equal(ab.transposed(), b.transposed() * a.transposed()));

    // row vector times column vector, and the outer product
    const M row = from_rows<typ>(1, 3, {1, -2, 3});
    const M col = from_rows<typ>(3, 1, {4, 5, -6});
    CHECK(equal(row * col, from_rows<typ>(1, 1, {-24})));
    CHECK(equal(col * row, from_rows<typ>(3, 3, {4, -8, 12,
                                                 5, -10, 15,
                                                 -6, 12, -18})));

    // empty inner dimension: every entry is the empty sum 0
    M z = M(2, 0) * M(0, 3);
    CHECK(z.getHeight() == 2 && z.getWidth() == 3);
    CHECK(equal(z, M(2, 3)));
    CHECK(equal(z, from_rows<typ>(2, 3, {0, 0, 0, 0, 0, 0})));

    // empty outer dimensions
    M e = M(0, 3) * b;
    CHECK(e.getHeight() == 0 && e.getWidth() == 2);
    e = a * M(3, 0);
    CHECK(e.getHeight() == 2 && e.getWidth() == 0);

    // a larger product against a reference computed with plain longs
    const int h = 5, n = 7, w = 4;
    std::vector<long> x(h * n), y(n * w);
    unsigned seed = 12345;
    auto next = [&seed]() {
        seed = seed * 1103515245u + 12345u;
        return long((seed >> 16) % 19) - 9;  // -9 .. 9
    };
    for (auto &v : x) v = next();
    for (auto &v : y) v = next();
    M mx(h, n), my(n, w);
    for (int i = 0; i < h; ++i)
        for (int k = 0; k < n; ++k)
            mx[i][k] = typ(x[i * n + k]);
    for (int k = 0; k < n; ++k)
        for (int j = 0; j < w; ++j)
            my[k][j] = typ(y[k * w + j]);
    M p = mx * my;
    CHECK(p.getHeight() == h && p.getWidth() == w);
    for (int i = 0; i < h; ++i)
        for (int j = 0; j < w; ++j) {
            long s = 0;
            for (int k = 0; k < n; ++k)
                s += x[i * n + k] * y[k * w + j];
            CHECK(p[i][j] == typ(s));
        }
}

static void test_matrix_product_exact() {
    // ZMatrix: entries beyond 64 bit
    // long is 32 bit on wasm32: build 2^40 as 2^20 * 2^20
    gfan::Integer big = gfan::Integer(1L << 20) * gfan::Integer(1L << 20);
    gfan::ZMatrix a(1, 2), b(2, 1);
    a[0][0] = big; a[0][1] = big;
    b[0][0] = big; b[1][0] = gfan::Integer(-1);
    gfan::Integer expected = big * big - big;  // 2^80 - 2^40
    CHECK((a * b)[0][0] == expected);

    // QMatrix: fractions (Rational(int) is ambiguous, so construct from long)
    auto Q = [](long v) { return gfan::Rational(v); };
    gfan::Rational half = Q(1) / Q(2);
    gfan::Rational third = Q(1) / Q(3);
    gfan::QMatrix q(2, 2), r(2, 2);
    q[0][0] = half;  q[0][1] = third;
    q[1][0] = third; q[1][1] = half;
    r[0][0] = Q(6); r[0][1] = Q(0);
    r[1][0] = Q(0); r[1][1] = Q(6);
    gfan::QMatrix qr = q * r;
    CHECK(qr[0][0] == Q(3) && qr[0][1] == Q(2));
    CHECK(qr[1][0] == Q(2) && qr[1][1] == Q(3));
    // [[1/2, 1/3], [1/3, 1/2]]^2 = [[13/36, 1/3], [1/3, 13/36]]
    gfan::QMatrix q2 = q * q;
    CHECK(q2[0][0] == Q(13) / Q(36));
    CHECK(q2[0][1] == third && q2[1][0] == third);
    CHECK(q2[1][1] == Q(13) / Q(36));
}

int main() {
    gfan::initializeCddlibIfRequired();

    test_matrix_product<int>();
    test_matrix_product<gfan::Integer>();
    test_matrix_product<gfan::Rational>();
    test_matrix_product_exact();

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
