// Solve a small LP through the HiGHS C++ API.
//   max  x + 2y   s.t.  x + y <= 4,  x + 3y <= 6,  0 <= x <= 3,  y >= 0
// Optimum: x = 3, y = 1, objective 5.
#include <cmath>
#include <cstdio>

#include "Highs.h"

int main() {
  HighsLp lp;
  lp.num_col_ = 2;
  lp.num_row_ = 2;
  lp.sense_ = ObjSense::kMaximize;
  lp.col_cost_ = {1.0, 2.0};
  lp.col_lower_ = {0.0, 0.0};
  lp.col_upper_ = {3.0, kHighsInf};
  lp.row_lower_ = {-kHighsInf, -kHighsInf};
  lp.row_upper_ = {4.0, 6.0};
  // column-wise matrix
  lp.a_matrix_.format_ = MatrixFormat::kColwise;
  lp.a_matrix_.start_ = {0, 2, 4};
  lp.a_matrix_.index_ = {0, 1, 0, 1};
  lp.a_matrix_.value_ = {1.0, 1.0, 1.0, 3.0};

  Highs highs;
  highs.setOptionValue("output_flag", false);
  if (highs.passModel(lp) != HighsStatus::kOk) {
    std::printf("passModel failed\n");
    return 1;
  }
  if (highs.run() != HighsStatus::kOk) {
    std::printf("run failed\n");
    return 1;
  }
  if (highs.getModelStatus() != HighsModelStatus::kOptimal) {
    std::printf("not optimal: %s\n",
                highs.modelStatusToString(highs.getModelStatus()).c_str());
    return 1;
  }
  const double obj = highs.getInfo().objective_function_value;
  std::printf("objective = %g\n", obj);
  if (std::fabs(obj - 5.0) > 1e-6) {
    return 1;
  }
  std::printf("HIGHS TEST OK\n");
  return 0;
}
