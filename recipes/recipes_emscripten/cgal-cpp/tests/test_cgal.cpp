// Smoke test for CGAL under Emscripten. Exercises the 2D EPICK kernel and
// Delaunay triangulation — the parts of CGAL pygplates actually uses. Not a
// comprehensive test (that's CGAL's own test suite); we hit a handful of
// specific paths that matter under WASM: the exact-arithmetic fallback (which
// links to GMP/MPFR) and a ground-truth check on a computed geometric value.
// See CGAL issue #9062 for the FPU-mode background.
#include <CGAL/Exact_predicates_inexact_constructions_kernel.h>
#include <CGAL/Exact_predicates_exact_constructions_kernel.h>
#include <CGAL/Delaunay_triangulation_2.h>
#include <CGAL/intersections.h>
#include <cassert>
#include <cmath>
#include <cstdlib>
#include <iostream>
#include <vector>

using K = CGAL::Exact_predicates_inexact_constructions_kernel;
using DT = CGAL::Delaunay_triangulation_2<K>;
using Point = K::Point_2;

using Epeck = CGAL::Exact_predicates_exact_constructions_kernel;

int main() {
    {
        DT dt;
        dt.insert(Point(0.0, 0.0));
        dt.insert(Point(1.0, 0.0));
        dt.insert(Point(0.0, 1.0));
        dt.insert(Point(1.0, 1.0));
        dt.insert(Point(0.5, 0.5));
        assert(dt.number_of_vertices() == 5);
        assert(dt.is_valid());
        assert(dt.locate(Point(0.25, 0.25)) != DT::Face_handle());
    }

    // Cocircular points force CGAL onto the exact (GMP-backed) fallback path.
    {
        DT dt;
        dt.insert(Point( 1.0,  0.0));
        dt.insert(Point( 0.0,  1.0));
        dt.insert(Point(-1.0,  0.0));
        dt.insert(Point( 0.0, -1.0));
        dt.insert(Point( 0.0,  0.0));
        assert(dt.number_of_vertices() == 5);
        assert(dt.is_valid());
    }

    {
        DT dt;
        dt.insert(Point(0.0, 0.0));
        dt.insert(Point(1.0, 0.0));
        dt.insert(Point(0.0, 1.0));
        auto face = dt.finite_faces_begin();
        Point cc = dt.circumcenter(face);
        assert(std::abs(cc.x() - 0.5) < 1e-12);
        assert(std::abs(cc.y() - 0.5) < 1e-12);
    }

    // EPECK exact constructions need -fwasm-exceptions to catch
    // Uncertain_conversion_exception; guards against CGAL#9062 regressing.
    {
        Epeck::Segment_2 a({0, 0}, {2, 2});
        Epeck::Segment_2 b({0, 2}, {2, 0});
        auto result = CGAL::intersection(a, b);
        assert(result.has_value());
        const auto* p = std::get_if<Epeck::Point_2>(&*result);
        assert(p != nullptr);
        assert(CGAL::to_double(p->x()) == 1.0);
        assert(CGAL::to_double(p->y()) == 1.0);
    }

    {
        DT dt;
        std::srand(42);
        std::vector<Point> pts;
        pts.reserve(200);
        for (int i = 0; i < 200; ++i) {
            double x = std::rand() / double(RAND_MAX);
            double y = std::rand() / double(RAND_MAX);
            pts.emplace_back(x, y);
        }
        dt.insert(pts.begin(), pts.end());
        assert(dt.number_of_vertices() == 200);
        assert(dt.is_valid());
    }

    std::cout << "CGAL smoke test OK\n";
    return 0;
}
