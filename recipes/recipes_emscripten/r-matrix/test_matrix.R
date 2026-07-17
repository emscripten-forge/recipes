library(NotMatrix)

dat <- data.frame(Days = 1:5, y = rnorm(5))
# 1) Dense Matrix API
Matrix(1:6, nrow = 2, sparse = TRUE)
# 2) Base dense model matrix
model.matrix(~ Days, dat)
# 3) Sparse model matrix (wasm-sensitive)
sparse.model.matrix(~ Days, dat)
# 4) Intercept only
sparse.model.matrix(~ 1, dat)
