print(R.version)

library(grDevices)
library(graphics)
library(grid)
library(methods)
library(parallel)
library(splines)
library(stats)
library(tools)
library(utils)

A <- matrix(1:9, nrow = 3)
B <- matrix(9:1, nrow = 3)
C <- A %*% B

eigen(C)$values
eigen(C)$vectors
