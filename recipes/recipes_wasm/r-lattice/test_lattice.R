library(lattice)

p <- xyplot(mpg ~ wt, data = mtcars)
stopifnot(inherits(p, "trellis"))
print(p)
