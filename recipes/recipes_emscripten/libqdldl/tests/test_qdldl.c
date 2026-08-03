#include <math.h>
#include <stdio.h>
#include <stdlib.h>

#include <qdldl.h>

/* Factor and solve A x = b in place (b becomes x). Returns factorization status. */
static QDLDL_int ldl_factor_solve(QDLDL_int n, const QDLDL_int* Ap, const QDLDL_int* Ai,
                                 const QDLDL_float* Ax, QDLDL_float* b) {
  QDLDL_int* etree = (QDLDL_int*)malloc(sizeof(QDLDL_int) * (size_t)n);
  QDLDL_int* Lnz = (QDLDL_int*)malloc(sizeof(QDLDL_int) * (size_t)n);
  QDLDL_int* iwork = (QDLDL_int*)malloc(sizeof(QDLDL_int) * (size_t)(3 * n));
  QDLDL_bool* bwork = (QDLDL_bool*)malloc(sizeof(QDLDL_bool) * (size_t)n);
  QDLDL_float* fwork = (QDLDL_float*)malloc(sizeof(QDLDL_float) * (size_t)n);
  QDLDL_int* Lp = (QDLDL_int*)malloc(sizeof(QDLDL_int) * (size_t)(n + 1));
  QDLDL_float* D = (QDLDL_float*)malloc(sizeof(QDLDL_float) * (size_t)n);
  QDLDL_float* Dinv = (QDLDL_float*)malloc(sizeof(QDLDL_float) * (size_t)n);

  QDLDL_int sumLnz = QDLDL_etree(n, Ap, Ai, iwork, Lnz, etree);
  if (sumLnz < 0) {
    free(etree);
    free(Lnz);
    free(iwork);
    free(bwork);
    free(fwork);
    free(Lp);
    free(D);
    free(Dinv);
    return sumLnz;
  }

  QDLDL_int* Li = (QDLDL_int*)malloc(sizeof(QDLDL_int) * (size_t)sumLnz);
  QDLDL_float* Lx = (QDLDL_float*)malloc(sizeof(QDLDL_float) * (size_t)sumLnz);

  QDLDL_int status =
      QDLDL_factor(n, Ap, Ai, Ax, Lp, Li, Lx, D, Dinv, Lnz, etree, bwork, iwork, fwork);
  if (status >= 0) {
    QDLDL_solve(n, Lp, Li, Lx, Dinv, b);
  }

  free(etree);
  free(Lnz);
  free(iwork);
  free(bwork);
  free(fwork);
  free(Lp);
  free(Li);
  free(Lx);
  free(D);
  free(Dinv);
  return status;
}

int main(void) {
  /* Upper-triangular CSC for A = [[1, 1], [1, -1]] */
  QDLDL_int Ap[] = {0, 1, 3};
  QDLDL_int Ai[] = {0, 0, 1};
  QDLDL_float Ax[] = {1.0, 1.0, -1.0};
  QDLDL_int An = 2;

  QDLDL_float b[] = {2.0, 4.0};
  const QDLDL_float xsol[] = {3.0, -1.0};
  const QDLDL_float tol = 1e-10;

  QDLDL_int status = ldl_factor_solve(An, Ap, Ai, Ax, b);
  if (status < 0) {
    fprintf(stderr, "QDLDL factorization failed with status %lld\n", (long long)status);
    return 1;
  }

  for (QDLDL_int i = 0; i < An; i++) {
    if (fabs(b[i] - xsol[i]) > tol) {
      fprintf(stderr, "Solve mismatch at index %lld: got %g, expected %g\n", (long long)i, b[i],
              xsol[i]);
      return 1;
    }
  }

  printf("libqdldl smoke test passed\n");
  return 0;
}
