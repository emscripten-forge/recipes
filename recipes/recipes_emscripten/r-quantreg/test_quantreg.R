library(quantreg)

set.seed(123)

# TEST 1

x <- 1:50
y <- 2 * x + rnorm(50, mean = 0, sd = 10)

model <- rq(y ~ x, tau = 0.5)
summary(model)

coef(model)

new_x <- data.frame(x = c(25, 30, 35))
predict(model, newdata = new_x)

# TEST 2

x <- seq(0, 10, length.out = 100)
y <- sin(x) + rnorm(100, mean = 0, sd = 0.3)

model_ss <- rqss(y ~ qss(x, lambda = 2), tau = 0.5)

summary(model_ss)

coef(model_ss)

new_x <- data.frame(x = c(2.5, 5.0, 7.5))
predict(model_ss, newdata = new_x)

model_ss_low <- rqss(y ~ qss(x, lambda = 2), tau = 0.1)  # 10th percentile
model_ss_high <- rqss(y ~ qss(x, lambda = 2), tau = 0.9) # 90th percentile

residuals(model_ss)[1:5]
