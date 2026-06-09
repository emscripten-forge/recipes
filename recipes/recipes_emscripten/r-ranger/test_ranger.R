library(ranger)

rf <- ranger(Species ~ ., data = iris, num.trees = 10, num.threads = 1)
stopifnot(rf$num.trees == 10)
