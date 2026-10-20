library(e1071)

model <- naiveBayes(Species ~ ., data = iris)
pred <- predict(model, iris[1:5, 1:4])
stopifnot(length(pred) == 5)
