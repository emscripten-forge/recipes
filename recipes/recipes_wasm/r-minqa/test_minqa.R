library(minqa)

fr <- function(x) {
  100 * (x[2] - x[1]^2)^2 + (1 - x[1])^2
}

res <- uobyqa(
    c(-1, 1),
    fr,
    control = list(iprint = 0, maxfun = 500)
)

stopifnot(res$ierr == 0L)
stopifnot(length(res$par) == 2L)
stopifnot(res$fval < 1e-4)

print(res$par)
print(res$fval)