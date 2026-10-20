#include <proxsuite/proxqp/dense/wrapper.hpp>
#include <Eigen/Core>

#include <iostream>
#include <cmath>

int main() {
    // Solve a simple 2-variable QP:
    //   minimize    0.5 * x^T H x + g^T x
    //   subject to  l <= Cx <= u
    //
    // H = [[2, 0], [0, 2]]
    // g = [-2, -2]
    // C = [[1, 0], [0, 1], [1, 1]]
    // l = [0, 0, -inf]   (x >= 0)
    // u = [inf, inf, 1]  (x1 + x2 <= 1)
    //
    // Optimal solution: x = [0.5, 0.5], obj = -1.5

    using T = double;
    int n = 2;  // primal dim
    int n_eq = 0;
    int n_in = 3;

    // Hessian (column-major, 2x2)
    Eigen::Matrix<T, 2, 2> H;
    H << 2.0, 0.0,
         0.0, 2.0;

    // Gradient (2x1)
    Eigen::Matrix<T, 2, 1> g;
    g << -2.0, -2.0;

    // Constraint matrix (3x2)
    Eigen::Matrix<T, 3, 2> C;
    C << 1.0, 0.0,
         0.0, 1.0,
         1.0, 1.0;

    // Lower bounds (3x1)
    Eigen::Matrix<T, 3, 1> l;
    l << 0.0, 0.0, -std::numeric_limits<T>::infinity();

    // Upper bounds (3x1)
    Eigen::Matrix<T, 3, 1> u;
    u << std::numeric_limits<T>::infinity(),
         std::numeric_limits<T>::infinity(),
         1.0;

    proxsuite::proxqp::dense::QP<T> qp(n, n_eq, n_in);

    // Set solver settings
    qp.settings.eps_abs = 1e-6;
    qp.settings.eps_rel = 0.0;
    qp.settings.verbose = false;

    // Initialize with data
    qp.init(H, g, std::nullopt, std::nullopt, C, l, u);
    qp.solve();

    const auto& results = qp.results;

    std::cout << "Status: " << static_cast<int>(results.info.status) << std::endl;
    std::cout << "x = [" << results.x[0] << ", " << results.x[1] << "]" << std::endl;
    std::cout << "Objective: " << results.info.objValue << std::endl;

    // Check: x ≈ [0.5, 0.5]
    bool passed = true;
    if (std::abs(results.x[0] - 0.5) > 1e-4) {
        std::cout << "FAIL: x[0] = " << results.x[0] << ", expected 0.5" << std::endl;
        passed = false;
    }
    if (std::abs(results.x[1] - 0.5) > 1e-4) {
        std::cout << "FAIL: x[1] = " << results.x[1] << ", expected 0.5" << std::endl;
        passed = false;
    }
    if (std::abs(results.info.objValue - (-1.5)) > 1e-4) {
        std::cout << "FAIL: objValue = " << results.info.objValue
                  << ", expected -1.5" << std::endl;
        passed = false;
    }

    if (passed) {
        std::cout << "PASS: Quadratic program solved correctly" << std::endl;
    } else {
        std::cout << "FAIL: Some checks failed" << std::endl;
        return 1;
    }

    return 0;
}
