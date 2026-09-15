library(goftest)
test_1 <- function() {
      x <- rnorm(30, mean=2, sd=1)
      # default behaviour: parameters fixed: simple null hypothesis
      cvm.test(x, "pnorm", mean=2, sd=1)
      ad.test(x, "pnorm", mean=2, sd=1)
      # parameters estimated: composite null hypothesis
      mu <- mean(x)
      sigma <- sd(x)
      cvm.test(x, "pnorm", mean=mu, sd=sigma, estimated=TRUE)
      ad.test(x, "pnorm", mean=mu, sd=sigma, estimated=TRUE)
}

test_2 <- function() {
    x <- rnorm(10, mean=2, sd=1)
    ad.test(x, "pnorm", mean=2, sd=1)
    ad.test(x, "pnorm", mean=mean(x), sd=sd(x), estimated=TRUE)
}

test_3 <- function() {
    x <- rnorm(10, mean=2, sd=1)
    cvm.test(x, "pnorm", mean=2, sd=1)
    cvm.test(x, "pnorm", mean=mean(x), sd=sd(x), estimated=TRUE)
}

test_4 <- function() {
      pAD(1.1, n=5)
      pAD(1.1)
      pAD(1.1, fast=FALSE)

      qAD(0.5, n=5)
      qAD(0.5)
}

test_5 <- function() {
      pCvM(1.1, n=5)
      pCvM(1.1)

      qCvM(0.5, n=5)
      qCvM(0.5)
}

test_6 <- function() {
       recogniseCdf("punif")
       recogniseCdf("unif")
       recogniseCdf("pt")
}

cat("Running test_1\n")
test_1()

cat("Running test_2\n")
test_2()

cat("Running test_3\n")
test_3()

cat("Running test_4\n")
test_4()

cat("Running test_5\n")
test_5()

cat("Running test_6\n")
test_6()

