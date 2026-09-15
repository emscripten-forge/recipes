print('Loading RSpectra package')
library(RSpectra)
print('... RSpectra package loaded successfully')

test_1 <- function() {
    library(Matrix)
    n = 20
    k = 5

    ## general matrices have complex eigenvalues
    set.seed(111)
    A1 = matrix(rnorm(n^2), n)  ## class "matrix"
    A2 = Matrix(A1)             ## class "dgeMatrix"

    eigs(A1, k)
    eigs(A2, k, opts = list(retvec = FALSE))  ## eigenvalues only

    ## Sparse matrices
    A1[sample(n^2, n^2 / 2)] = 0
    A3 = as(A1, "dgCMatrix")
    A4 = as(A1, "dgRMatrix")

    eigs(A3, k)
    eigs(A4, k)

    ## Function interface
    f = function(x, args)
    {
        as.numeric(args %*% x)
    }
    eigs(f, k, n = n, args = A3)

    ## Symmetric matrices have real eigenvalues
    A5 = crossprod(A1)
    eigs_sym(A5, k)

    ## Find the smallest (in absolute value) k eigenvalues of A5
    eigs_sym(A5, k, which = "SM")

    ## Another way to do this: use the sigma argument
    eigs_sym(A5, k, sigma = 0)

    ## The results should be the same,
    ## but the latter method is far more stable on large matrices
}

test_2 <- function() {
    m = 100
    n = 20
    k = 5
    set.seed(111)
    A = matrix(rnorm(m * n), m)

    svds(A, k)
    svds(t(A), k, nu = 0, nv = 3)

    ## Sparse matrices
    library(Matrix)
    A[sample(m * n, m * n / 2)] = 0
    Asp1 = as(A, "dgCMatrix")
    Asp2 = as(A, "dgRMatrix")

    svds(Asp1, k)
    svds(Asp2, k, nu = 0, nv = 0)

    ## Function interface
    Af = function(x, args)
    {
        as.numeric(args %*% x)
    }

    Atf = function(x, args)
    {
        as.numeric(crossprod(args, x))
    }

    svds(Af, k, Atrans = Atf, dim = c(m, n), args = Asp1)
}

print("Running test_1")
test_1()

print("Running test_2")
test_2()

