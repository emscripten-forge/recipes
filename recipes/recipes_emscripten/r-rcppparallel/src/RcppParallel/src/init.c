#include <R.h>
#include <Rinternals.h>
#include <R_ext/Rdynload.h>

void R_init_RcppParallel(DllInfo *dll)
{
    R_registerRoutines(dll, NULL, NULL, NULL, NULL);
    R_useDynamicSymbols(dll, FALSE);
}