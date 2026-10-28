library(survival)

test_1 <- function() {
    data(cancer)
    x <- Surv(cancer$time, cancer$status)
    print(x)
    stopifnot(is.Surv(x))
}

test_2 <- function() {
    data(cancer)
    fit_km <- survfit(Surv(time, status) ~ ph.ecog, data = cancer)
    print(fit_km)
    stopifnot(inherits(fit_km, "survfit"))
}

test_3 <- function() {
    data(heart)
    y <- Surv(heart$start, heart$stop, heart$event)
    print(y)
    stopifnot(is.Surv(y))
}

test_4 <- function() {
    data(cancer)
    fit <- survreg(Surv(time, status) ~ ph.ecog + age, data = cancer, dist = "weibull")
    print(fit)
    stopifnot(inherits(fit, "survreg"))
}

print("Running test_1")
test_1()

print("Running test_2")
test_2()

print("Running test_3")
test_3()

print("Running test_4")
test_4()
