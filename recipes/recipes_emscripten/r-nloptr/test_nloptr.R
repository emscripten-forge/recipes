library(nloptr)

## Rosenbrock Banana function
eval_f <- function(x) {
  100 * (x[2] - x[1] * x[1]) ^ 2 + (1 - x[1]) ^ 2
}

## Gradient of Rosenbrock Banana function
eval_grad_f <- function(x) {
  c(-400 * x[1] * (x[2] - x[1] * x[1]) - 2 * (1 - x[1]),
    200 * (x[2] - x[1] * x[1]))
}

# Initial values
x0 <- c(-1.2, 1)

opts <- list("algorithm" = "NLOPT_LD_LBFGS",
             "xtol_rel" = 1.0e-8)

# Solve Rosenbrock Banana function
res <- nloptr(x0 = x0,
              eval_f = eval_f,
              eval_grad_f = eval_grad_f,
              opts = opts)

print(res)