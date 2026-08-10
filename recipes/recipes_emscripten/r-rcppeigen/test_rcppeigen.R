library(RcppEigen)

# Test 1: Check Eigen version
print(packageVersion("RcppEigen"))

# Test 2: Test Eigen matrix operations
A <- matrix(1:9, nrow = 3)
B <- matrix(9:1, nrow = 3)
C <- A %*% B
print(C)

# Test 3: Test Eigen solver
eigen(C)$values