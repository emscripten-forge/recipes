#include <petscksp.h>

static char help[] = "PETSc smoke test: dense LU solve (LAPACK) and MatMult (BLAS).\n";

int main(int argc, char **argv)
{
  Mat         A;
  Vec         x, b, u, u2, b2;
  KSP         ksp;
  PetscReal   norm;
  PetscInt    n = 4, i, its;

  PetscFunctionBeginUser;
  PetscCall(PetscInitialize(&argc, &argv, NULL, help));

  /* 1. LAPACK path: dense LU factorization + solve (PC LU -> dgetrf/dgetrs). */
  PetscCall(MatCreateSeqDense(PETSC_COMM_SELF, n, n, NULL, &A));
  for (i = 0; i < n; i++) {
    PetscCall(MatSetValue(A, i, i, (PetscScalar)(2 + i), INSERT_VALUES));
    if (i + 1 < n) PetscCall(MatSetValue(A, i, i + 1, (PetscScalar)-1, INSERT_VALUES));
    if (i > 0) PetscCall(MatSetValue(A, i, i - 1, (PetscScalar)-1, INSERT_VALUES));
  }
  PetscCall(MatAssemblyBegin(A, MAT_FINAL_ASSEMBLY));
  PetscCall(MatAssemblyEnd(A, MAT_FINAL_ASSEMBLY));

  PetscCall(VecCreateSeq(PETSC_COMM_SELF, n, &u));
  PetscCall(VecDuplicate(u, &b));
  PetscCall(VecDuplicate(u, &x));
  PetscCall(VecSet(u, 1.0));
  PetscCall(MatMult(A, u, b));

  PetscCall(KSPCreate(PETSC_COMM_SELF, &ksp));
  PetscCall(KSPSetType(ksp, KSPPREONLY));
  PetscCall(KSPSetOperators(ksp, A, A));
  PetscCall(KSPSetFromOptions(ksp));
  PetscCall(KSPSolve(ksp, b, x));
  PetscCall(VecAXPY(x, -1.0, u));
  PetscCall(VecNorm(x, NORM_2, &norm));
  PetscCall(KSPGetIterationNumber(ksp, &its));
  PetscCheck(norm < 1e-10, PETSC_COMM_SELF, PETSC_ERR_PLIB, "LU residual %g too large", (double)norm);
  PetscCall(PetscPrintf(PETSC_COMM_SELF, "dense LU residual=%.3e its=%" PetscInt_FMT "\n", (double)norm, its));
  PetscCall(KSPDestroy(&ksp));
  PetscCall(VecDestroy(&x));
  PetscCall(VecDestroy(&b));
  PetscCall(VecDestroy(&u));
  PetscCall(MatDestroy(&A));

  /* 2. BLAS path: dense MatMult (dgemv) on a 2x2 system; ||[3,4]|| = 5. */
  PetscCall(MatCreateSeqDense(PETSC_COMM_SELF, 2, 2, NULL, &A));
  PetscCall(MatSetValue(A, 0, 0, (PetscScalar)2.0, INSERT_VALUES));
  PetscCall(MatSetValue(A, 0, 1, (PetscScalar)1.0, INSERT_VALUES));
  PetscCall(MatSetValue(A, 1, 0, (PetscScalar)1.0, INSERT_VALUES));
  PetscCall(MatSetValue(A, 1, 1, (PetscScalar)3.0, INSERT_VALUES));
  PetscCall(MatAssemblyBegin(A, MAT_FINAL_ASSEMBLY));
  PetscCall(MatAssemblyEnd(A, MAT_FINAL_ASSEMBLY));

  PetscCall(VecCreateSeq(PETSC_COMM_SELF, 2, &u2));
  PetscCall(VecDuplicate(u2, &b2));
  PetscCall(VecSet(u2, 1.0));
  PetscCall(MatMult(A, u2, b2));
  PetscCall(VecNorm(b2, NORM_2, &norm));
  PetscCheck(PetscAbsReal(norm - 5.0) < 1e-12, PETSC_COMM_SELF, PETSC_ERR_PLIB, "MatMult norm %g", (double)norm);
  PetscCall(PetscPrintf(PETSC_COMM_SELF, "BLAS MatMult norm=%g\n", (double)norm));
  PetscCall(VecDestroy(&b2));
  PetscCall(VecDestroy(&u2));
  PetscCall(MatDestroy(&A));

  PetscCall(PetscFinalize());
  return 0;
}
