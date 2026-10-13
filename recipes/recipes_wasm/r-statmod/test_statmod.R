library(statmod)

stopifnot(is.function(gauss.quad))
stopifnot(is.function(permp))

# Gauss-Hermite quadrature nodes and weights
gq <- gauss.quad(n = 5, kind = "hermite")
stopifnot(length(gq$nodes) == 5L)
stopifnot(length(gq$weights) == 5L)
