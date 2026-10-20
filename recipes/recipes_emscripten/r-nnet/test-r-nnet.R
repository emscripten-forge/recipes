library(nnet)

set.seed(123)
nn.iris <- nnet(Species ~ ., data = iris, size = 3)
summary(nn.iris)