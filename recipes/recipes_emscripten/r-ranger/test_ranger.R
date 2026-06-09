library(ranger)

rf <- ranger(Species ~ ., data = iris, num.trees = 10)
stopifnot(rf$num.trees == 10)
