library(energy)
test_1 <- function() {
    x <- matrix(rnorm(20), 10, 2)
    D <- calc_dist(x)
    is.dmatrix(D)
    is.dmatrix(cov(x))
}

test_2 <- function() {
     x <- rpois(50, 2)
     poisson.m(x)
     poisson.e(x)
 
     poisson.etest(x, R=199)
     poisson.mtest(x, R=199)
     poisson.tests(x, R=199)
}

test_3 <- function() {
     x <- iris[1:10, 1:4]
     y <- iris[11:20, 1:4]
     M1 <- as.matrix(dist(x))
     M2 <- as.matrix(dist(y))
     U <- U_center(M1)
     V <- U_center(M2)

     U_product(U, V)
     dcovU_stats(M1, M2)
}

test_4 <- function() {
     x <- iris[1:50, 1:4]
     y <- iris[51:100, 1:4]
     dcovU(x, y)
     bcdcor(x, y)
}

test_5 <- function() {
     x <- iris[1:10, 1:4]
     dx <- dist(x)
     Dx <- as.matrix(dx)
     M <- U_center(Dx)

     all.equal(M, U_center(M))     #idempotence
     all.equal(M, D_center(M))     #invariance
}

test_6 <- function() {
     x <- matrix(rnorm(100), 10, 10)
     y <- matrix(runif(100), 10, 10)
     dcorT(x, y)
     dcorT.test(x, y)
}

test_7 <- function() {
     x <- iris[1:50, 1:4]
     y <- iris[51:100, 1:4]
     set.seed(1)
     dcor.test(dist(x), dist(y), R=199)
     set.seed(1)
     dcov.test(x, y, R=199)
}

test_8 <- function() {
  
        ## these are equivalent, but 2d is faster for n > 50
        n <- 100
        x <- rnorm(100)
        y <- rnorm(100)
        all.equal(dcov(x, y)^2, dcov2d(x, y), check.attributes = FALSE)
        all.equal(bcdcor(x, y), dcor2d(x, y, "U"), check.attributes = FALSE)

        x <- rlnorm(400)
        y <- rexp(400)
        dcov.test(x, y, R=199)    #permutation test
        dcor.test(x, y, R=199)
}

test_9 <- function() {
     x <- iris[1:50, 1:4]
     y <- iris[51:100, 1:4]
     Dx <- as.matrix(dist(x))
     Dy <- as.matrix(dist(y))
     dcovU_stats(Dx, Dy)
}

test_10 <- function() {
          ## warpbreaks one-way decompositions
          data(warpbreaks)
          attach(warpbreaks)
          disco(breaks, factors=wool, R=99)
      
          ## warpbreaks two-way wool+tension
          disco(breaks, factors=data.frame(wool, tension), R=0)

          ## warpbreaks two-way wool*tension
          disco(breaks, factors=data.frame(wool, tension, wool:tension), R=0)

          ## When index=2 for univariate data, we get ANOVA decomposition
          disco(breaks, factors=tension, index=2.0, R=99)
          aov(breaks ~ tension)

          ## Multivariate response
          ## Example on producing plastic film from Krzanowski (1998, p. 381)
          tear <- c(6.5, 6.2, 5.8, 6.5, 6.5, 6.9, 7.2, 6.9, 6.1, 6.3,
                    6.7, 6.6, 7.2, 7.1, 6.8, 7.1, 7.0, 7.2, 7.5, 7.6)
          gloss <- c(9.5, 9.9, 9.6, 9.6, 9.2, 9.1, 10.0, 9.9, 9.5, 9.4,
                     9.1, 9.3, 8.3, 8.4, 8.5, 9.2, 8.8, 9.7, 10.1, 9.2)
          opacity <- c(4.4, 6.4, 3.0, 4.1, 0.8, 5.7, 2.0, 3.9, 1.9, 5.7,
                       2.8, 4.1, 3.8, 1.6, 3.4, 8.4, 5.2, 6.9, 2.7, 1.9)
          Y <- cbind(tear, gloss, opacity)
          rate <- factor(gl(2,10), labels=c("Low", "High"))

    	    ## test for equal distributions by rate
          disco(Y, factors=rate, R=99)
    	    disco(Y, factors=rate, R=99, method="discoB")

          ## Just extract the decomposition table
          disco(Y, factors=rate, R=0)$stats

    	    ## Compare eqdist.e methods for rate
    	    ## disco between stat is half of original when sample sizes equal
    	    eqdist.e(Y, sizes=c(10, 10), method="original")
    	    eqdist.e(Y, sizes=c(10, 10), method="discoB")

          ## The between-sample distance component
          disco.between(Y, factors=rate, R=0)
}

test_11 <- function() {
     x <- iris[1:50, 1:4]
     y <- iris[51:100, 1:4]
     dcov(x, y)
     dcov(dist(x), dist(y))  #same thing
}

test_12 <- function() {
         ## compute cluster e-distances for 3 samples of iris data
         data(iris)
         edist(iris[,1:4], c(50,50,50))
    
         ## pairwise disco statistics
         edist(iris[,1:4], c(50,50,50), method="discoB")  

         ## compute e-distances from a distance object
         data(iris)
         edist(dist(iris[,1:4]), c(50, 50, 50), distance=TRUE, alpha = 1)

         ## compute e-distances from a distance matrix
         data(iris)
         d <- as.matrix(dist(iris[,1:4]))
         edist(d, c(50, 50, 50), distance=TRUE, alpha = 1)
}

test_13 <- function() {
     data(iris)

     ## test if the 3 varieties of iris data (d=4) have equal distributions
     eqdist.etest(iris[,1:4], c(50,50,50), R = 199)

     ## example that uses method="disco"
      x <- matrix(rnorm(100), nrow=20)
      y <- matrix(rnorm(100), nrow=20)
      X <- rbind(x, y)
      d <- dist(X)

      # should match edist default statistic
      set.seed(1234)
      eqdist.etest(d, sizes=c(20, 20), distance=TRUE, R = 199)

      # comparison with edist
      edist(d, sizes=c(20, 10), distance=TRUE)

      # for comparison
      g <- as.factor(rep(1:2, c(20, 20)))
      set.seed(1234)
      disco(d, factors=g, distance=TRUE, R=199)

      # should match statistic in edist method="discoB", above
      set.seed(1234)
      disco.between(d, factors=g, distance=TRUE, R=199)
}

test_14 <- function() {

     ## independent multivariate data
     x <- matrix(rnorm(60), nrow=20, ncol=3)
     y <- matrix(rnorm(40), nrow=20, ncol=2)
     indep.test(x, y, method = "dcov", R = 99)
     indep.test(x, y, method = "mvI", R = 99)

     ## dependent multivariate data
     if (require(MASS)) {
       Sigma <- matrix(c(1, .1, 0, 0 , 1, 0, 0 ,.1, 1), 3, 3)
       x <- mvrnorm(30, c(0, 0, 0), diag(3))
       y <- mvrnorm(30, c(0, 0, 0), Sigma) * x
       indep.test(x, y, R = 99)    #dcov method
       indep.test(x, y, method = "mvI", R = 99)
        }
}

test_15 <- function() {
      x <- as.matrix(iris[ ,1:4])
      set.seed(123)
      kg <- kgroups(x, k = 3, iter.max = 5, nstart = 2)
      kg
      fitted(kg)
  
  
        d <- dist(x)
        set.seed(123)
        kg <- kgroups(d, k = 3, iter.max = 5, nstart = 2)
        kg
    
        kg$cluster
  
        fitted(kg)
        fitted(kg, method = "groups")
}

test_16 <- function() {
    x <- matrix(rnorm(100), nrow=20, ncol=5)
    mutualIndep.test(x, 199)
}

test_17 <- function() {
    mvI(iris[1:25, 1], iris[1:25, 2])

    mvI.test(iris[1:25, 1], iris[1:25, 2], R=99)
}

test_18 <- function() {
     ## compute normality test statistic for iris Setosa data
     data(iris)
     mvnorm.e(iris[1:50, 1:4])

     ## test if the iris Setosa data has multivariate normal distribution
     mvnorm.test(iris[1:50,1:4], R = 199)
}

test_19 <- function() {
      x <- iris[1:50, 1]
      normal.e(x)
      normal.test(x, R=199)
      normal.test(x, method="limit")
}

test_20 <- function() {
      n = 30
      R <- 199

      ## mutually independent standard normal vectors
      x <- rnorm(n)
      y <- rnorm(n)
      z <- rnorm(n)

      pdcor(x, y, z)
      pdcov(x, y, z)
      set.seed(1)
      pdcov.test(x, y, z, R=R)
      set.seed(1)
      pdcor.test(x, y, z, R=R)


      if (require(MASS)) {
        p = 4
        mu <- rep(0, p)
        Sigma <- diag(p)
  
        ## linear dependence
        y <- mvrnorm(n, mu, Sigma) + x
        print(pdcov.test(x, y, z, R=R))
  
        ## non-linear dependence
        y <- mvrnorm(n, mu, Sigma) * x
        print(pdcov.test(x, y, z, R=R))
        }
}

test_21 <- function() {
    sortrank(rnorm(5))
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

cat("Running test_16\n")
test_16()

cat("Running test_17\n")
test_17()

cat("Running test_18\n")
test_18()

cat("Running test_19\n")
test_19()

cat("Running test_20\n")
test_20()

cat("Running test_21\n")
test_21()

