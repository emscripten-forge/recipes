print('Loading wdm package')
library(wdm)
print('... wdm package loaded successfully')

test_1 <- function() {
    x <- rnorm(100)
    y <- rpois(100, 1)  # all but Hoeffding's D can handle ties
    w <- runif(100)

    indep_test(x, y, method = "kendall")               # unweighted
    indep_test(x, y, method = "kendall", weights = w)  # weighted
}

test_2 <- function() {
    x <- rnorm(100)
    w <- rexp(100)
    rank(x)
    rank_wtd(x, w)
}

test_3 <- function() {
    ##  dependence between two vectors
    x <- rnorm(100)
    y <- rpois(100, 1)  # all but Hoeffding's D can handle ties
    w <- runif(100)
    wdm(x, y, method = "kendall")               # unweighted
    wdm(x, y, method = "kendall", weights = w)  # weighted

    ##  dependence in a matrix
    x <- matrix(rnorm(100 * 3), 100, 3)
    wdm(x, method = "spearman")               # unweighted
    wdm(x, method = "spearman", weights = w)  # weighted

    ##  dependence between columns of two matrices
    y <- matrix(rnorm(100 * 2), 100, 2)
    wdm(x, y, method = "hoeffding")               # unweighted
    wdm(x, y, method = "hoeffding", weights = w)  # weighted
}

print("Running test_1")
test_1()

print("Running test_2")
test_2()

print("Running test_3")
test_3()

