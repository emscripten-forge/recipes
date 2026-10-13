library(fastmatch)

stopifnot(is.function(coalesce))
stopifnot(is.function(ctapply))
stopifnot(is.function(fmatch))

# Example from fastmatch documentation
i = rnorm(2e6)
names(i) = as.integer(rnorm(2e6))
coalesce(names(i))

i = i[order(names(i))]
ctapply(i, names(i), sum)

x = as.integer(rnorm(1e6) * 1000000)
s = 1:100
fmatch(s,x)