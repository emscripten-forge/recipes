print('Loading kde1d package')
library(kde1d)
print('... kde1d package loaded successfully')

test_1 <- function() {
    set.seed(0) # for reproducibility
    x <- rnorm(100) # simulate some data
    fit <- kde1d(x) # estimate density
    dkde1d(0, fit) # evaluate density estimate (close to dnorm(0))
    pkde1d(0, fit) # evaluate corresponding cdf (close to pnorm(0))
    qkde1d(0.5, fit) # quantile function (close to qnorm(0))
    hist(rkde1d(100, fit)) # simulate
}

test_2 <- function() {
    x <- as.factor(rbinom(10, 1, 0.5))
    equi_jitter(x)
}

test_3 <- function() {

    ## unbounded data
    x <- rnorm(500) # simulate data
    fit <- kde1d(x) # estimate density
    dkde1d(0, fit) # evaluate density estimate
    summary(fit) # information about the estimate
    plot(fit) # plot the density estimate
    curve(dnorm(x),
      add = TRUE, # add true density
      col = "red"
    )

    ## bounded data, log-linear
    x <- rgamma(500, shape = 1) # simulate data
    fit <- kde1d(x, xmin = 0, deg = 1) # estimate density
    dkde1d(seq(0, 5, by = 1), fit) # evaluate density estimate
    summary(fit) # information about the estimate
    plot(fit) # plot the density estimate
    curve(dgamma(x, shape = 1), # add true density
      add = TRUE, col = "red",
      from = 1e-3
    )

    ## discrete data
    x <- rbinom(500, size = 5, prob = 0.5) # simulate data
    fit <- kde1d(x, xmin = 0, xmax = 5, type = "discrete") # estimate density
    fit <- kde1d(ordered(x, levels = 0:5)) # alternative API
    dkde1d(sort(unique(x)), fit) # evaluate density estimate
    summary(fit) # information about the estimate
    plot(fit) # plot the density estimate
    points(ordered(0:5, 0:5), # add true density
      dbinom(0:5, 5, 0.5),
      col = "red"
    )

    ## zero-inflated data
    x <- rexp(500, 0.5)  # simulate data
    x[sample(1:500, 200)] <- 0 # add zero-inflation
    fit <- kde1d(x, xmin = 0, type = "zi") # estimate density
    dkde1d(sort(unique(x)), fit) # evaluate density estimate
    summary(fit) # information about the estimate
    plot(fit) # plot the density estimate
    lines(  # add true density
      seq(0, 20, l = 100),
      0.6 * dexp(seq(0, 20, l = 100), 0.5),
      col = "red"
    )
    points(0, 0.4, col = "red")

    ## weighted estimate
    x <- rnorm(100) # simulate data
    weights <- rexp(100) # weights as in Bayesian bootstrap
    fit <- kde1d(x, weights = weights) # weighted fit
    plot(fit) # compare with unweighted fit
    lines(kde1d(x), col = 2)
}

test_4 <- function() {
    ## continuous data
    x <- rbeta(100, shape1 = 0.3, shape2 = 0.4) # simulate data
    fit <- kde1d(x) # unbounded estimate
    plot(fit, ylim = c(0, 4)) # plot estimate
    curve(dbeta(x, 0.3, 0.4), # add true density
      col = "red", add = TRUE
    )
    fit_bounded <- kde1d(x, xmin = 0, xmax = 1) # bounded estimate
    lines(fit_bounded, col = "green")

    ## discrete data
    x <- rpois(100, 3) # simulate data
    x <- ordered(x, levels = 0:20) # declare variable as ordered
    fit <- kde1d(x) # estimate density
    plot(fit, ylim = c(0, 0.25)) # plot density estimate
    points(ordered(0:20, 0:20), # add true density values
      dpois(0:20, 3),
      col = "red"
    )

    ## zero-inflated data
    x <- rexp(500, 0.5)  # simulate data
    x[sample(1:500, 200)] <- 0 # add zero-inflation
    fit <- kde1d(x, xmin = 0, type = "zi") # estimate density
    plot(fit) # plot the density estimate
    lines(  # add true density
      seq(0, 20, l = 100),
      0.6 * dexp(seq(0, 20, l = 100), 0.5),
      col = "red"
    )
    points(0, 0.4, col = "red")
}

print("Running test_1")
test_1()

print("Running test_2")
test_2()

print("Running test_3")
test_3()

print("Running test_4")
test_4()

