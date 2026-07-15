library(truncnorm)

# Density
dtruncnorm(
  x = 0,
  a = -Inf,
  b = Inf,
  mean = 0,
  sd = 1
)

# Cumulative distribution function
ptruncnorm(
  q = 0,
  a = -Inf,
  b = Inf,
  mean = 0,
  sd = 1
)

# Quantile function
qtruncnorm(
  p = 0.95,
  a = -Inf,
  b = Inf,
  mean = 0,
  sd = 1
)

# Random generation
rtruncnorm(
  n = 100,
  a = -Inf,
  b = Inf,
  mean = 0,
  sd = 1
)

# Expected value (mean)
etruncnorm(
  a = -Inf,
  b = Inf,
  mean = 0,
  sd = 1
)

# Variance
vtruncnorm(
  a = -Inf,
  b = Inf,
  mean = 0,
  sd = 1
)
