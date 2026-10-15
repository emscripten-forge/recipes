library(quantreg)

test_1 <- function() {
    set.seed(123)
    x <- 1:50
    y <- 2 * x + rnorm(50, mean = 0, sd = 10)
    model <- rq(y ~ x, tau = 0.5)
    print(summary(model))
    print(coef(model))
    new_x <- data.frame(x = c(25, 30, 35))
    print(predict(model, newdata = new_x))
    stopifnot(inherits(model, "rq"))
}

test_2 <- function() {
    set.seed(123)
    df <- data.frame(
        x = seq(0, 10, length.out = 100),
        y = sin(seq(0, 10, length.out = 100)) + rnorm(100, mean = 0, sd = 0.3)
    )
    model_ss <- rqss(y ~ qss(x, lambda = 2), tau = 0.5, data = df)
    print(summary(model_ss))
    print(coef(model_ss))
    new_x <- data.frame(x = c(2.5, 5.0, 7.5))
    print(predict(model_ss, newdata = new_x))
    model_ss_low <- rqss(y ~ qss(x, lambda = 2), tau = 0.1, data = df)
    model_ss_high <- rqss(y ~ qss(x, lambda = 2), tau = 0.9, data = df)
    print(residuals(model_ss)[1:5])
    stopifnot(inherits(model_ss, "rqss"), inherits(model_ss_low, "rqss"),
              inherits(model_ss_high, "rqss"))
}

print("Running test_1")
test_1()

print("Running test_2")
test_2()
