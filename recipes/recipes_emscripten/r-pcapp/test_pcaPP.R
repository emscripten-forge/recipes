library(pcaPP)
test_1 <- function() {
      # multivariate data with outliers
      library(mvtnorm)
      x <- rbind(rmvnorm(200, rep(0, 6), diag(c(5, rep(1,5)))),
                 rmvnorm( 15, c(0, rep(20, 5)), diag(rep(1, 6))))
      # Here we calculate the principal components with PCAgrid
      pc <- PCAgrid(x)
      # we could draw a biplot too:
      biplot(pc)
      # now we want to compare the results with the non-robust principal components
      pc <- princomp(x)
      # again, a biplot for comparison:
      biplot(pc)

      ##  Sparse loadings
      set.seed (0)
      x <- data.Zou ()

                       ##  applying PCA
      pc <-  princomp (x)
                       ##  the corresponding non-sparse loadings
      unclass (pc$load[,1:3])
      pc$sdev[1:3]

                       ##  lambda as calculated in the opt.TPO - example
      lambda <- c (0.23, 0.34, 0.005)
                       ##  applying sparse PCA
      spc <- sPCAgrid (x, k = 3, lambda = lambda, method = "sd")
      unclass (spc$load)
      spc$sdev[1:3]

                       ## comparing the non-sparse and sparse biplot
      par (mfrow = 1:2)
      biplot (pc, main = "non-sparse PCs")
      biplot (spc, main = "sparse PCs")
}

test_2 <- function() {
      # multivariate data with outliers
      library(mvtnorm)
      x <- rbind(rmvnorm(200, rep(0, 6), diag(c(5, rep(1,5)))),
                 rmvnorm( 15, c(0, rep(20, 5)), diag(rep(1, 6))))
      # Here we calculate the principal components with PCAgrid
      pc <- PCAproj(x, 6)
      # we could draw a biplot too:
      biplot(pc)

      # we could use another calculation method and another objective function, and 
      # maybe only calculate the first three principal components:
      pc <- PCAproj(x, 3, "qn", "sphere")
      biplot(pc)

      # now we want to compare the results with the non-robust principal components
      pc <- princomp(x)
      # again, a biplot for comparision:
      biplot(pc)
}

test_3 <- function() {
      # multivariate data with outliers
      library(mvtnorm)
      x <- rbind(rmvnorm(85, rep(0, 6), diag(c(5, rep(1,5)))),
                 rmvnorm( 15, c(0, rep(20, 5)), diag(rep(1, 6))))
      # Here we calculate the principal components with PCAgrid
      pcrob <- PCAgrid(x, k=6)
      resrob <- PCdiagplot(x,pcrob,plotbw=FALSE)

      # compare with classical method:
      pcclass <- PCAgrid(x, k=6, method="sd")
      resclass <- PCdiagplot(x,pcclass,plotbw=FALSE)
}

test_4 <- function() {
      x <- rnorm(100, 10, 5)
      x <- ScaleAdv(x)$x

      # can be used with multivariate data too
      library(mvtnorm)
      x <- rmvnorm(100, 3:7, diag((7:3)^2))
      res <- ScaleAdv(x, center = l1median, scale = mad)
      res

      # instead of using an estimator, you could specify the center and scale yourself too
      x <- rmvnorm(100, 3:7, diag((7:3)^2))
      res <- ScaleAdv(x, 3:7, 7:3)
      res
}

test_5 <- function() {

      set.seed (100)		## creating test data
      n <- 1000
      x <- rnorm (n)
      y <- x+  rnorm (n)

      tim <- proc.time ()[1]	## applying cor.fk
      cor.fk (x, y)
      cat ("cor.fk runtime [s]:", proc.time ()[1] - tim, "(n =", length (x), ")\n")

      tim <- proc.time ()[1]	## applying cor (standard R implementation)
      cor (x, y, method = "kendall")
      cat ("cor runtime [s]:", proc.time ()[1] - tim, "(n =", length (x), ")\n")

    		##	applying cor and cor.fk on data containing				

      Xt <- cbind (c (x, as.integer (x)), c (y, as.integer (y)))

      tim <- proc.time ()[1]	## applying cor.fk
      cor.fk (Xt)
      cat ("cor.fk runtime [s]:", proc.time ()[1] - tim, "(n =", nrow (Xt), ")\n")

      tim <- proc.time ()[1]	## applying cor (standard R implementation)
      cor (Xt, method = "kendall")
      cat ("cor runtime [s]:", proc.time ()[1] - tim, "(n =", nrow (Xt), ")\n")
}

test_6 <- function() {
      # multivariate data with outliers
      library(mvtnorm)
      x <- rbind(rmvnorm(200, rep(0, 6), diag(c(5, rep(1,5)))),
                 rmvnorm( 15, c(0, rep(20, 5)), diag(rep(1, 6))))
      pc <- princomp(x)
      covPC(pc, k=2)
}

test_7 <- function() {
      # multivariate data with outliers
      library(mvtnorm)
      x <- rbind(rmvnorm(200, rep(0, 6), diag(c(5, rep(1,5)))),
                 rmvnorm( 15, c(0, rep(20, 5)), diag(rep(1, 6))))
      covPCAproj(x)
      # compare with classical covariance matrix:
      cov(x)
}

test_8 <- function() {
                       ##  data generation
      set.seed (0)
      x <- data.Zou ()

                       ##  applying PCA
      pc <-  princomp (x)
                       ##  the corresponding non-sparse loadings
      unclass (pc$load[,1:3])
      pc$sdev[1:3]

                       ##  lambda as calculated in the opt.TPO - example
      lambda <- c (0.23, 0.34, 0.005)
                       ##  applying sparse PCA
      spc <- sPCAgrid (x, k = 3, lambda = lambda, method = "sd")
      unclass (spc$load)
      spc$sdev[1:3]

                       ## comparing the non-sparse and sparse biplot
      par (mfrow = 1:2)
      biplot (pc, main = "non-sparse PCs")
      biplot (spc, main = "sparse PCs")
}

test_9 <- function() {
      l1median(rnorm(100), trace = -1) # this returns the median of the sample

      # multivariate data with outliers
      library(mvtnorm)
      x <- rbind(rmvnorm(200, rep(0, 4), diag(c(1, 1, 2, 2))), 
                 rmvnorm( 50, rep(3, 4), diag(rep(2, 4))))
      l1median(x, trace = -1)
      # compare with coordinate-wise median:
      apply(x,2,median)
}

test_10 <- function() {

      # multivariate data with outliers
      library(mvtnorm)
      x <- rbind(rmvnorm(200, rep(0, 4), diag(c(1, 1, 2, 2))), 
                 rmvnorm( 50, rep(3, 4), diag(rep(2, 4))))

      l1median_NM (x)$par
      l1median_CG (x)$par
      l1median_BFGS (x)$par
      l1median_NLM (x)$par
      l1median_HoCr (x)$par
      l1median_VaZh (x)$par

      # compare with coordinate-wise median:
      apply(x,2,median)
}

test_11 <- function() {

      set.seed (0)
                          ##  generate test data
      x <- data.Zou (n = 250)

      k.max <- 3          ##  max number of considered sparse PCs

                          ##  arguments for the sPCAgrid algorithm
      maxiter <- 25       ##    the maximum number of iterations
      method <- "sd"      ##    using classical estimations

                          ##  Optimizing the TPO criterion
      oTPO <- opt.TPO (x, k.max = k.max, method = method, maxiter = maxiter)

                          ##  Optimizing the BIC criterion
      oBIC <- opt.BIC (x, k.max = k.max, method = method, maxiter = maxiter)

              ##  Objective function vs. lambda
      par (mfrow = c (2, k.max))
      for (i in 1:k.max)        objplot (oTPO, k = i)
      for (i in 1:k.max)        objplot (oBIC, k = i)
}

test_12 <- function() {

      set.seed (0)
                          ##  generate test data
      x <- data.Zou (n = 250)

      k.max <- 3          ##  max number of considered sparse PCs

                          ##  arguments for the sPCAgrid algorithm
      maxiter <- 25       ##    the maximum number of iterations
      method <- "sd"      ##    using classical estimations

                          ##  Optimizing the TPO criterion
      oTPO <- opt.TPO (x, k.max = k.max, method = method, maxiter = maxiter)

      oTPO$pc             ##  the model selected by opt.TPO
      oTPO$pc$load        ##  and the according sparse loadings.

                          ##  Optimizing the BIC criterion
      oBIC <- opt.BIC (x, k.max = k.max, method = method, maxiter = maxiter)

      oBIC$pc[[1]]        ##  the first model selected by opt.BIC (k = 1)

              ##  Tradeoff Curves: Explained Variance vs. sparseness
      par (mfrow = c (2, k.max))
      for (i in 1:k.max)        plot (oTPO, k = i)
      for (i in 1:k.max)        plot (oBIC, k = i)

              ##  Tradeoff Curves: Explained Variance vs. lambda
      par (mfrow = c (2, k.max))
      for (i in 1:k.max)        plot (oTPO, k = i, f.x = "lambda")
      for (i in 1:k.max)        plot (oBIC, k = i, f.x = "lambda")

              ##  Objective function vs. lambda
      par (mfrow = c (2, k.max))
      for (i in 1:k.max)        objplot (oTPO, k = i)
      for (i in 1:k.max)        objplot (oBIC, k = i)
}

test_13 <- function() {

      set.seed (0)
                          ##  generate test data
      x <- data.Zou (n = 250)

      k.max <- 3          ##  max number of considered sparse PCs

                          ##  arguments for the sPCAgrid algorithm
      maxiter <- 25       ##    the maximum number of iterations
      method <- "sd"      ##    using classical estimations

                          ##  Optimizing the TPO criterion
      oTPO <- opt.TPO (x, k.max = k.max, method = method, maxiter = maxiter)

                          ##  Optimizing the BIC criterion
      oBIC <- opt.BIC (x, k.max = k.max, method = method, maxiter = maxiter)

              ##  Tradeoff Curves: Explained Variance vs. sparseness
      par (mfrow = c (2, k.max))
      for (i in 1:k.max)        plot (oTPO, k = i)
      for (i in 1:k.max)        plot (oBIC, k = i)

              ##  Explained Variance vs. lambda
      par (mfrow = c (2, k.max))
      for (i in 1:k.max)        plot (oTPO, k = i, f.x = "lambda")
      for (i in 1:k.max)        plot (oBIC, k = i, f.x = "lambda")
}

test_14 <- function() {
      # multivariate data with outliers
      library(mvtnorm)
      x <- rbind(rmvnorm(200, rep(0, 6), diag(c(5, rep(1,5)))),
                 rmvnorm( 15, c(0, rep(20, 5)), diag(rep(1, 6))))
      plotcov(covPCAproj(x),covPCAgrid(x))
}

test_15 <- function() {
      # data with outliers
      x <- c(rnorm(100), rnorm(10, 10))
      qn(x)
}

cat("Running test_1\n")
test_1()

cat("Running test_2\n")
test_2()

cat("Running test_3\n")
test_3()

cat("Running test_4\n")
test_4()

cat("Running test_5\n")
test_5()

cat("Running test_6\n")
test_6()

cat("Running test_7\n")
test_7()

cat("Running test_8\n")
test_8()

cat("Running test_9\n")
test_9()

cat("Running test_10\n")
test_10()

cat("Running test_11\n")
test_11()

cat("Running test_12\n")
test_12()

cat("Running test_13\n")
test_13()

cat("Running test_14\n")
test_14()

cat("Running test_15\n")
test_15()

