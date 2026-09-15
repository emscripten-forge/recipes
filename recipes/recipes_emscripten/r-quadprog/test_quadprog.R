library(quadprog)
test_1 <- function() {
    ##
    ## Assume we want to minimize: -(0 5 0) %*% b + 1/2 b^T b
    ## under the constraints:      A^T b >= b0
    ## with b0 = (-8,2,0)^T
    ## and      (-4  2  0) 
    ##      A = (-3  1 -2)
    ##          ( 0  0  1)
    ## we can use solve.QP as follows:
    ##
    Dmat       <- matrix(0,3,3)
    diag(Dmat) <- 1
    dvec       <- c(0,5,0)
    Amat       <- matrix(c(-4,-3,0,2,1,0,0,-2,1),3,3)
    bvec       <- c(-8,2,0)
    solve.QP(Dmat,dvec,Amat,bvec=bvec)
}

test_2 <- function() {
    ##
    ## Assume we want to minimize: -(0 5 0) %*% b + 1/2 b^T b
    ## under the constraints:      A^T b >= b0
    ## with b0 = (-8,2,0)^T
    ## and      (-4  2  0) 
    ##      A = (-3  1 -2)
    ##          ( 0  0  1)
    ## we can use solve.QP.compact as follows:
    ##
    Dmat       <- matrix(0,3,3)
    diag(Dmat) <- 1
    dvec       <- c(0,5,0)
    Aind       <- rbind(c(2,2,2),c(1,1,2),c(2,2,3))
    Amat       <- rbind(c(-4,2,-2),c(-3,1,1))
    bvec       <- c(-8,2,0)
    solve.QP.compact(Dmat,dvec,Amat,Aind,bvec=bvec)
}

cat("Running test_1\n")
test_1()

cat("Running test_2\n")
test_2()

