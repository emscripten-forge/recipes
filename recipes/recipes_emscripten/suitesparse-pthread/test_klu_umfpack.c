/* Solve the 5x5 system of the KLU and UMFPACK demos (solution 1..5) with
 * both, on the main thread and on a pthread. */
#include <klu.h>
#include <math.h>
#include <pthread.h>
#include <stdio.h>
#include <umfpack.h>

static int n = 5;
static int Ap[] = {0, 2, 5, 9, 10, 12};
static int Ai[] = {0, 1, 0, 2, 4, 1, 2, 3, 4, 2, 1, 4};
static double Ax[] = {2., 3., 3., -1., 4., 4., -3., 1., 2., 2., 6., 1.};
static double b0[] = {8., 45., -3., 3., 19.};

static int check(const double *x)
{
    int i, bad = 0;
    for (i = 0; i < n; i++)
        if (fabs(x[i] - (i + 1)) > 1e-10)
            bad++;
    return bad;
}

static int solve_klu(void)
{
    double b[5];
    klu_symbolic *S;
    klu_numeric *N;
    klu_common c;
    int i;
    for (i = 0; i < n; i++)
        b[i] = b0[i];
    klu_defaults(&c);
    S = klu_analyze(n, Ap, Ai, &c);
    N = klu_factor(Ap, Ai, Ax, S, &c);
    klu_solve(S, N, n, 1, b, &c);
    klu_free_symbolic(&S, &c);
    klu_free_numeric(&N, &c);
    return check(b);
}

static int solve_umfpack(void)
{
    double x[5];
    void *Symbolic, *Numeric;
    if (umfpack_di_symbolic(n, n, Ap, Ai, Ax, &Symbolic, NULL, NULL) != UMFPACK_OK)
        return 1;
    if (umfpack_di_numeric(Ap, Ai, Ax, Symbolic, &Numeric, NULL, NULL) != UMFPACK_OK)
        return 1;
    umfpack_di_free_symbolic(&Symbolic);
    if (umfpack_di_solve(UMFPACK_A, Ap, Ai, Ax, x, b0, Numeric, NULL, NULL) != UMFPACK_OK)
        return 1;
    umfpack_di_free_numeric(&Numeric);
    return check(x);
}

static void *on_thread(void *arg)
{
    *(int *) arg = solve_klu() + solve_umfpack();
    return NULL;
}

int main(void)
{
    pthread_t t;
    int bad = solve_klu() + solve_umfpack(), bad_thread = 1;
    pthread_create(&t, NULL, on_thread, &bad_thread);
    pthread_join(t, NULL);
    printf("%s (KLU %d.%d.%d, UMFPACK %d.%d.%d)\n", bad + bad_thread ? "FAILED" : "OK",
           KLU_MAIN_VERSION, KLU_SUB_VERSION, KLU_SUBSUB_VERSION,
           UMFPACK_MAIN_VERSION, UMFPACK_SUB_VERSION, UMFPACK_SUBSUB_VERSION);
    return bad + bad_thread != 0;
}
