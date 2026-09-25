library(prodlim)

set.seed(42)
mock_data <- data.frame(
  time   = c(1, 3, 5, 12, 15),
  status = c(1, 1, 0,  1,  0), # 1 = event, 0 = censored
  group  = c("A", "A", "B", "B", "B")
)

fit <- prodlim(Hist(time, status) ~ group, data = mock_data)

predictions <- predict(fit, times = c(2, 6), newdata = data.frame(group = c("A", "B"))