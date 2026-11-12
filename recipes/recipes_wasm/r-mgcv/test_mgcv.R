library(mgcv)

test_1 <- function() {
    set.seed(0)
    dat <- gamSim(1, n = 200, dist = "normal", scale = 2, verbose = FALSE)
    b <- gam(y ~ s(x0) + s(x1) + s(x2) + s(x3), data = dat)
    print(summary(b))
    stopifnot(inherits(b, "gam"))
}

test_2 <- function() {
    set.seed(0)
    dat <- gamSim(1, n = 200, dist = "normal", scale = 2, verbose = FALSE)
    b <- gam(y ~ s(x0) + s(x1) + s(x2) + s(x3), data = dat)
    p <- predict(b, type = "response")
    print(head(p))
    stopifnot(is.numeric(p), length(p) == nrow(dat))
}

test_3 <- function() {
    set.seed(0)
    dat <- gamSim(2, n = 200, dist = "normal", scale = 0.5, verbose = FALSE)$data
    b <- gam(y ~ te(x, z), data = dat)
    print(summary(b))
    stopifnot(inherits(b, "gam"))
}

for (name in ls(pattern = "^test_[0-9]+$")) {
  cat("Running ", name, "\n", sep = "")
  get(name)()
}
