library(randomForest)

set.seed(1)
fit <- randomForest(Species ~ ., data = iris, ntree = 10)
stopifnot(inherits(fit, "randomForest"))
print(fit)
