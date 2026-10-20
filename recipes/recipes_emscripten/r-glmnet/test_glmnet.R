library(glmnet)

set.seed(1)
x <- matrix(rnorm(50 * 10), 50, 10)
y <- rnorm(50)
fit <- glmnet(x, y)
stopifnot(length(fit$lambda) > 0)
