library(leaps)

fit <- regsubsets(mpg ~ ., data = mtcars, nvmax = 3)
s <- summary(fit)
stopifnot(nrow(s$which) == 3)
