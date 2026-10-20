# Define the parameters
p <- 3          # dimension of the multivariate normal distribution
n <- 5          # number of samples to generate
x <- rep(0, p)  # a point where to evaluate the density (must be a vector of length p)

library(mvtnorm)

# This evaluates the density at point x
dmvnorm(x, mean = rep(0, p), sigma = diag(p), log = FALSE, checkSymmetry = TRUE)

# This generates n random samples from the multivariate normal distribution
rmvnorm(n, mean = rep(0, p), sigma = diag(p),
        method = c("eigen", "svd", "chol"), pre0.9_9994 = FALSE, 
        checkSymmetry = TRUE, rnorm = stats::rnorm)
