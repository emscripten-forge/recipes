library(survival)

data(cancer)
x <- Surv(cancer$time, cancer$status)
print(x)
stopifnot(is.Surv(x))

fit_km <- survfit(Surv(time, status) ~ ph.ecog, data = cancer)
print(fit_km)
stopifnot(inherits(fit_km, "survfit"))

data(heart)
y <- Surv(heart$start, heart$stop, heart$event)
print(y)
stopifnot(is.Surv(y))

fit <- survreg(Surv(time, status) ~ ph.ecog + age, data = cancer, dist = "weibull")
print(fit)
stopifnot(inherits(fit, "survreg"))
