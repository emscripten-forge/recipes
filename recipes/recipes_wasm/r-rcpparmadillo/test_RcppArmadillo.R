library(RcppArmadillo)

# Version helpers
arma <- armadillo_version(FALSE)
stopifnot(is.integer(arma))
stopifnot(identical(length(arma), 3L))
stopifnot(identical(names(arma), c("major", "minor", "patch")))
stopifnot(all(arma >= 0L))

arma_single <- armadillo_version(TRUE)
stopifnot(is.integer(arma_single), length(arma_single) == 1L)
stopifnot(arma_single == 10000L * arma[["major"]] + 100L * arma[["minor"]] + arma[["patch"]])

pv <- armadillo_version_typed()
stopifnot(inherits(pv, "package_version"))
stopifnot(inherits(pv, "numeric_version"))
stopifnot(identical(pv, as.package_version(paste(arma, collapse = "."))))

# Seed / OpenMP helpers
armadillo_set_seed(42L)
suppressWarnings(armadillo_set_seed_random())
n_threads <- armadillo_get_number_of_omp_threads()
stopifnot(is.integer(n_threads), length(n_threads) == 1L, n_threads >= 1L)
armadillo_set_number_of_omp_threads(1L)
stopifnot(identical(armadillo_get_number_of_omp_threads(), 1L))
armadillo_throttle_cores(1)
armadillo_reset_cores()

# Linear model via Armadillo (fastLm)
set.seed(1)
n <- 50L
x <- rnorm(n)
y <- 2 + 3 * x + rnorm(n, sd = 0.1)
X <- cbind(1, x)

fit_pure <- fastLmPure(X, y)
stopifnot(is.list(fit_pure))
stopifnot(length(fit_pure$coefficients) == 2L)
stopifnot(abs(fit_pure$coefficients[1] - 2) < 0.2)
stopifnot(abs(fit_pure$coefficients[2] - 3) < 0.2)

fit <- fastLm(y ~ x)
stopifnot(inherits(fit, "fastLm"))
cf <- coef(fit)
stopifnot(length(cf) == 2L)
stopifnot(abs(cf[1] - 2) < 0.2)
stopifnot(abs(cf[2] - 3) < 0.2)
pred <- predict(fit)
stopifnot(length(pred) == n)
