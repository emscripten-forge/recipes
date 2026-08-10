library(SparseM)

cscM <- as.matrix.csc(as(diag(4:1), "matrix.csr"))
cscM
str(cscM)
stopifnot(identical(dim(cscM), c(4L, 4L)))

new("matrix.csr")      # the 1x1 matrix [0]
new("matrix.diag.csr") # the 'same'

as(1:5, "matrix.diag.csr") # a sparse version of  diag(1:5)

data(triogramX)
