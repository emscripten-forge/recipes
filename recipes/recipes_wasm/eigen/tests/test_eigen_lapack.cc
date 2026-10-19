#include <algorithm>
#include <cmath>
#include <cstdio>

#include <Eigen/Dense>

int main() {
  // Analytic 2x2 system: [[4,1],[2,3]] x = [1,2] has the exact solution
  // [0.1, 0.6], so a wrong LAPACKE result cannot hide behind a tolerance.
  Eigen::Matrix2d a;
  a << 4.0, 1.0, 2.0, 3.0;
  const Eigen::Vector2d b(1.0, 2.0);
  const Eigen::Vector2d x = a.fullPivLu().solve(b);
  const double analytic_error =
      std::max(std::abs(x[0] - 0.1), std::abs(x[1] - 0.6));

  // A diagonal matrix has known singular values.
  Eigen::MatrixXd diagonal = Eigen::MatrixXd::Zero(6, 6);
  for (int i = 0; i < 6; ++i) {
    diagonal(i, i) = 6.0 - i;
  }
  const Eigen::JacobiSVD<Eigen::MatrixXd> diagonal_svd(diagonal);
  const double singular_value_error =
      (diagonal_svd.singularValues() - Eigen::VectorXd::LinSpaced(6, 6.0, 1.0))
          .cwiseAbs()
          .maxCoeff();

  // U * S * V^T must reproduce the input for a non-square matrix.
  const Eigen::MatrixXd random = Eigen::MatrixXd::Random(32, 24);
  const Eigen::JacobiSVD<Eigen::MatrixXd> random_svd(
      random, Eigen::ComputeThinU | Eigen::ComputeThinV);
  const double reconstruction_error =
      (random_svd.matrixU() * random_svd.singularValues().asDiagonal() *
           random_svd.matrixV().transpose() -
       random)
          .cwiseAbs()
          .maxCoeff();

  // Residual of a larger solve.
  const Eigen::MatrixXd square = Eigen::MatrixXd::Random(48, 48);
  const Eigen::VectorXd rhs = Eigen::VectorXd::Random(48);
  const double residual =
      (square * square.fullPivLu().solve(rhs) - rhs).cwiseAbs().maxCoeff();

  std::printf("analytic %.3g, singular values %.3g, reconstruction %.3g, "
              "residual %.3g\n",
              analytic_error, singular_value_error, reconstruction_error,
              residual);

  if (!(analytic_error < 1e-12) || !(singular_value_error < 1e-12) ||
      !(reconstruction_error < 1e-10) || !(residual < 1e-8)) {
    std::printf("FAIL: LAPACKE results are wrong\n");
    return 1;
  }

  std::printf("eigen LAPACKE usable\n");
  return 0;
}
