library(mclust)
test_1 <- function() {

    # Clustering
    mod1 <- Mclust(iris[,1:4])
    summary(mod1)
    plot(mod1,  what = c("BIC", "classification"))

    # Classification
    data(banknote)
    mod2 <- MclustDA(banknote[,2:7], banknote$Status)
    summary(mod2)
    plot(mod2)

    # Density estimation
    mod3 <- densityMclust(faithful$waiting)
    summary(mod3)
}

test_2 <- function() {

    data(Baudry_etal_2010_JCGS_examples)

    output <- clustCombi(data = ex4.4.1)
    output # is of class clustCombi

    # plots the hierarchy of combined solutions, then some "entropy plots" which 
    # may help one to select the number of classes
    plot(output)
}

test_3 <- function() {
    # multi-class case
    class <- factor(c(5,5,5,2,5,3,1,2,1,1), levels = 1:5)
    probs <- matrix(c(0.15, 0.01, 0.08, 0.23, 0.01, 0.23, 0.59, 0.02, 0.38, 0.45, 
                      0.36, 0.05, 0.30, 0.46, 0.15, 0.13, 0.06, 0.19, 0.27, 0.17, 
                      0.40, 0.34, 0.18, 0.04, 0.47, 0.34, 0.32, 0.01, 0.03, 0.11, 
                      0.04, 0.04, 0.09, 0.05, 0.28, 0.27, 0.02, 0.03, 0.12, 0.25, 
                      0.05, 0.56, 0.35, 0.22, 0.09, 0.03, 0.01, 0.75, 0.20, 0.02),
                    nrow = 10, ncol = 5)
    cbind(class, probs, map = map(probs))
    BrierScore(probs, class)

    # two-class case
    class <- factor(c(1,1,1,2,2,1,1,2,1,1), levels = 1:2)
    probs <- matrix(c(0.91, 0.4, 0.56, 0.27, 0.37, 0.7, 0.97, 0.22, 0.68, 0.43, 
                      0.09, 0.6, 0.44, 0.73, 0.63, 0.3, 0.03, 0.78, 0.32, 0.57),
                    nrow = 10, ncol = 2)
    cbind(class, probs, map = map(probs))
    BrierScore(probs, class)

    # two-class case when predicted probabilities are constrained to be equal to 
    # 0 or 1, then the (normalized) Brier Score is equal to the classification
    # error rate
    probs <- ifelse(probs > 0.5, 1, 0)
    cbind(class, probs, map = map(probs))
    BrierScore(probs, class)
    classError(map(probs), class)$errorRate

    # plot Brier score for predicted probabilities in range [0,1]
    class <- factor(rep(1, each = 100), levels = 0:1)
    prob  <- seq(0, 1, by = 0.01)
    brier <- sapply(prob, function(p) 
      { z <- matrix(c(1-p,p), nrow = length(class), ncol = 2, byrow = TRUE)
        BrierScore(z, class)
      })
    plot(prob, brier, type = "l", main = "Scoring all one class",
         xlab = "Predicted probability", ylab = "Brier score")

    # brier score for predicting balanced data with constant prob
    class <- factor(rep(c(1,0), each = 50), levels = 0:1)
    prob  <- seq(0, 1, by = 0.01)
    brier <- sapply(prob, function(p) 
      { z <- matrix(c(1-p,p), nrow = length(class), ncol = 2, byrow = TRUE)
        BrierScore(z, class)
      })
    plot(prob, brier, type = "l", main = "Scoring balanced classes",
         xlab = "Predicted probability", ylab = "Brier score")

    # brier score for predicting unbalanced data with constant prob
    class <- factor(rep(c(0,1), times = c(90,10)), levels = 0:1)
    prob  <- seq(0, 1, by = 0.01)
    brier <- sapply(prob, function(p) 
      { z <- matrix(c(1-p,p), nrow = length(class), ncol = 2, byrow = TRUE)
        BrierScore(z, class)
      })
    plot(prob, brier, type = "l", main = "Scoring unbalanced classes",
         xlab = "Predicted probability", ylab = "Brier score")
}

test_4 <- function() {

    data(GvHD)
    dat <- GvHD.pos[1:500,] # only a few lines for a quick example
    output <- clustCombi(data = dat) 
    output # is of class clustCombi
    # plot the hierarchy of combined solutions
    plot(output, what = "classification") 
    # plot some "entropy plots" which may help one to select the number of classes
    plot(output, what = "entropy") 
    # plot the tree structure obtained from combining mixture components
    plot(output, what = "tree")
}

test_5 <- function() {
    mod1 <- Mclust(iris[,1:4])
    summary(mod1)

    mod2 <- Mclust(iris[,1:4], G = 3)
    summary(mod2, parameters = TRUE)

    # Using prior
    mod3 <- Mclust(iris[,1:4], prior = priorControl())
    summary(mod3)

    mod4 <- Mclust(iris[,1:4], prior = priorControl(functionName="defaultPrior", shrinkage=0.1))
    summary(mod4)

    # Clustering of faithful data with some artificial noise added 
    nNoise <- 100
    set.seed(0) # to make it reproducible
    Noise <- apply(faithful, 2, function(x) 
                  runif(nNoise, min = min(x)-.1, max = max(x)+.1))
    data <- rbind(faithful, Noise)
    plot(faithful)
    points(Noise, pch = 20, cex = 0.5, col = "lightgrey")
    set.seed(0)
    NoiseInit <- sample(c(TRUE,FALSE), size = nrow(faithful)+nNoise, 
              replace = TRUE, prob = c(3,1)/4)
    mod5 <- Mclust(data, initialization = list(noise = NoiseInit))
    summary(mod5, parameter = TRUE)
    plot(mod5, what = "classification")
}

test_6 <- function() {

    data(diabetes)
    X <- diabetes[,-1]
    modClust <- Mclust(X) 
    bootClust <- MclustBootstrap(modClust)
    summary(bootClust, what = "se")
    summary(bootClust, what = "ci")

    data(acidity)
    modDens <- densityMclust(acidity, plot = FALSE)
    modDens <- MclustBootstrap(modDens)
    summary(modDens, what = "se")
    summary(modDens, what = "ci")
}

test_7 <- function() {
    odd <- seq(from = 1, to = nrow(iris), by = 2)
    even <- odd + 1
    X.train <- iris[odd,-5]
    Class.train <- iris[odd,5]
    X.test <- iris[even,-5]
    Class.test <- iris[even,5]

    # common EEE covariance structure (which is essentially equivalent to linear discriminant analysis)
    irisMclustDA <- MclustDA(X.train, Class.train, modelType = "EDDA", modelNames = "EEE")
    summary(irisMclustDA, parameters = TRUE)
    summary(irisMclustDA, newdata = X.test, newclass = Class.test)

    # common covariance structure selected by BIC
    irisMclustDA <- MclustDA(X.train, Class.train, modelType = "EDDA")
    summary(irisMclustDA, parameters = TRUE)
    summary(irisMclustDA, newdata = X.test, newclass = Class.test)

    # general covariance structure selected by BIC
    irisMclustDA <- MclustDA(X.train, Class.train)
    summary(irisMclustDA, parameters = TRUE)
    summary(irisMclustDA, newdata = X.test, newclass = Class.test)

    plot(irisMclustDA)
    plot(irisMclustDA, dimens = 3:4)
    plot(irisMclustDA, dimens = 4)

    plot(irisMclustDA, what = "classification")
    plot(irisMclustDA, what = "classification", newdata = X.test)
    plot(irisMclustDA, what = "classification", dimens = 3:4)
    plot(irisMclustDA, what = "classification", newdata = X.test, dimens = 3:4)
    plot(irisMclustDA, what = "classification", dimens = 4)
    plot(irisMclustDA, what = "classification", dimens = 4, newdata = X.test)

    plot(irisMclustDA, what = "train&test", newdata = X.test)
    plot(irisMclustDA, what = "train&test", newdata = X.test, dimens = 3:4)
    plot(irisMclustDA, what = "train&test", newdata = X.test, dimens = 4)

    plot(irisMclustDA, what = "error")
    plot(irisMclustDA, what = "error", dimens = 3:4)
    plot(irisMclustDA, what = "error", dimens = 4)
    plot(irisMclustDA, what = "error", newdata = X.test, newclass = Class.test)
    plot(irisMclustDA, what = "error", newdata = X.test, newclass = Class.test, dimens = 3:4)
    plot(irisMclustDA, what = "error", newdata = X.test, newclass = Class.test, dimens = 4)


    # simulated 1D data
    n <- 250 
    set.seed(1)
    triModal <- c(rnorm(n,-5), rnorm(n,0), rnorm(n,5))
    triClass <- c(rep(1,n), rep(2,n), rep(3,n))
    odd <- seq(from = 1, to = length(triModal), by = 2)
    even <- odd + 1
    triMclustDA <- MclustDA(triModal[odd], triClass[odd])
    summary(triMclustDA, parameters = TRUE)
    summary(triMclustDA, newdata = triModal[even], newclass = triClass[even])
    plot(triMclustDA, what = "scatterplot")
    plot(triMclustDA, what = "classification")
    plot(triMclustDA, what = "classification", newdata = triModal[even])
    plot(triMclustDA, what = "train&test", newdata = triModal[even])
    plot(triMclustDA, what = "error")
    plot(triMclustDA, what = "error", newdata = triModal[even], newclass = triClass[even])

    # simulated 2D cross data
    data(cross)
    odd <- seq(from = 1, to = nrow(cross), by = 2)
    even <- odd + 1
    crossMclustDA <- MclustDA(cross[odd,-1], cross[odd,1])
    summary(crossMclustDA, parameters = TRUE)
    summary(crossMclustDA, newdata = cross[even,-1], newclass = cross[even,1])
    plot(crossMclustDA, what = "scatterplot")
    plot(crossMclustDA, what = "classification")
    plot(crossMclustDA, what = "classification", newdata = cross[even,-1])
    plot(crossMclustDA, what = "train&test", newdata = cross[even,-1])
    plot(crossMclustDA, what = "error")
    plot(crossMclustDA, what = "error", newdata =cross[even,-1], newclass = cross[even,1])
}

test_8 <- function() {
    # clustering
    data(diabetes)
    mod <- Mclust(diabetes[,-1])
    summary(mod)

    dr <- MclustDR(mod)
    summary(dr)
    plot(dr, what = "scatterplot")
    plot(dr, what = "evalues")

    dr <- MclustDR(mod, lambda = 0.5) 
    summary(dr)
    plot(dr, what = "scatterplot")
    plot(dr, what = "evalues")

    # classification
    data(banknote)

    da <- MclustDA(banknote[,2:7], banknote$Status, modelType = "EDDA")
    dr <- MclustDR(da)
    summary(dr)

    da <- MclustDA(banknote[,2:7], banknote$Status)
    dr <- MclustDR(da)
    summary(dr)
}

test_9 <- function() {

    # clustering
    data(crabs, package = "MASS")
    x <- crabs[,4:8]
    class <- paste(crabs$sp, crabs$sex, sep = "|")
    mod <- Mclust(x)
    table(class, mod$classification)
    dr <- MclustDR(mod)
    summary(dr)
    plot(dr)
    drs <- MclustDRsubsel(dr)
    summary(drs)
    table(class, drs$classification)
    plot(drs, what = "scatterplot")
    plot(drs, what = "pairs")
    plot(drs, what = "contour")
    plot(drs, what = "boundaries")
    plot(drs, what = "evalues")

    # classification
    data(banknote)
    da <- MclustDA(banknote[,2:7], banknote$Status)
    table(banknote$Status, predict(da)$class)
    dr <- MclustDR(da)
    summary(dr)
    drs <- MclustDRsubsel(dr)
    summary(drs)
    table(banknote$Status, predict(drs)$class)
    plot(drs, what = "scatterplot")
    plot(drs, what = "classification")
    plot(drs, what = "boundaries")
}

test_10 <- function() {
    # Simulate two overlapping groups
    n <- 200
    pars <- list(pro = c(0.5, 0.5),
                 mean = matrix(c(-1,1), nrow = 2, ncol = 2, byrow = TRUE),
                 variance = mclustVariance("EII", d = 2, G = 2))
    pars$variance$sigmasq <- 1
    data <- sim("EII", parameters = pars, n = n, seed = 12)
    class <- data[,1]
    X <- data[,-1]
    clPairs(X, class, symbols = c(1,2), main = "Full classified data")

    # Randomly remove labels
    cl <- class; cl[sample(1:n, size = 195)] <- NA
    table(cl, useNA = "ifany")
    clPairs(X, ifelse(is.na(cl), 0, class),
            symbols = c(0, 16, 17), colors = c("grey", 4, 2),
            main = "Partially classified data")

    # Fit semi-supervised classification model
    mod_SSC  <- MclustSSC(X, cl)
    summary(mod_SSC, parameters = TRUE)

    pred_SSC <- predict(mod_SSC)
    table(Predicted = pred_SSC$classification, Actual = class)

    ngrid <- 50
    xgrid <- seq(-3, 3, length.out = ngrid)
    ygrid <- seq(-4, 4.5, length.out = ngrid)
    xygrid <- expand.grid(xgrid, ygrid)
    pred_SSC  <- predict(mod_SSC, newdata = xygrid)
    col <- mclust.options("classPlotColors")[class]
    pch <- class
    pch[!is.na(cl)] = ifelse(cl[!is.na(cl)] == 1, 19, 17)
    plot(X, pch = pch, col = col)
    contour(xgrid, ygrid, matrix(pred_SSC$z[,1], ngrid, ngrid), 
            add = TRUE, levels = 0.5, drawlabels = FALSE, lty = 2, lwd = 2)
}

test_11 <- function() {
    a <- rep(1:3, 3)
    a
    b <- rep(c("A", "B", "C"), 3)
    b
    adjustedRandIndex(a, b)

    a <- sample(1:3, 9, replace = TRUE)
    a
    b <- sample(c("A", "B", "C"), 9, replace = TRUE)
    b
    adjustedRandIndex(a, b)

    a <- rep(1:3, 4)
    a
    b <- rep(c("A", "B", "C", "D"), 3)
    b
    adjustedRandIndex(a, b)

    irisHCvvv <- hc(modelName = "VVV", data = iris[,-5])
    cl3 <- hclass(irisHCvvv, 3)
    adjustedRandIndex(cl3,iris[,5])

    irisBIC <- mclustBIC(iris[,-5])
    adjustedRandIndex(summary(irisBIC,iris[,-5])$classification,iris[,5])
    adjustedRandIndex(summary(irisBIC,iris[,-5],G=3)$classification,iris[,5])
}

test_12 <- function() {

    n <- nrow(iris)
    d <- ncol(iris)-1
    G <- 3

    emEst <- me(modelName="VVI", data=iris[,-5], unmap(iris[,5]))
    names(emEst)

    args(bic)
    bic(modelName="VVI", loglik=emEst$loglik, n=n, d=d, G=G)
    # do.call("bic", emEst)    ## alternative call
}

test_13 <- function() {
    z2 <- unmap(hclass(hcVVV(faithful),2)) # initial value for 2 class case

    model <- me(modelName = "EEE", data = faithful, z = z2)
    cdens(modelName = "EEE", data = faithful, logarithm = TRUE, 
          parameters = model$parameters)[1:5,]

    data(cross)
    odd <- seq(1, nrow(cross), by = 2)
    oddBIC <- mclustBIC(cross[odd,-1]) 
    oddModel <- mclustModel(cross[odd,-1], oddBIC) ## best parameter estimates
    names(oddModel)

    even <- odd + 1
    densities <- cdens(modelName = oddModel$modelName, data = cross[even,-1], 
                       parameters = oddModel$parameters)
    cbind(class = cross[even,1], densities)[1:5,]
}

test_14 <- function() {

    z2 <- unmap(hclass(hcVVV(faithful),2)) # initial value for 2 class case

    model <- meVVV(data=faithful, z=z2)
    cdensVVV(data=faithful, logarithm = TRUE, parameters = model$parameters)

    data(cross)
    z2 <- unmap(cross[,1])

    model <- meEEV(data = cross[,-1], z = z2)

    EEVdensities <- cdensEEV( data = cross[,-1], parameters = model$parameters)

    cbind(cross[,-1],map(EEVdensities))
}

test_15 <- function() {

    x <- c(rnorm(100), rnorm(100, 3, 2))
    dens <- densityMclust(x, plot = FALSE)
    summary(dens, parameters = TRUE)
    cdf <- cdfMclust(dens)
    str(cdf)
    q <- quantileMclust(dens, p = c(0.01, 0.1, 0.5, 0.9, 0.99))
    cbind(quantile = q, cdf = cdfMclust(dens, q)$y)
    plot(cdf, type = "l", xlab = "x", ylab = "CDF")
    points(q, cdfMclust(dens, q)$y, pch = 20, col = "red3")

    par(mfrow = c(2,2))
    dens.waiting <- densityMclust(faithful$waiting)
    plot(cdfMclust(dens.waiting), type = "l", 
         xlab = dens.waiting$varname, ylab = "CDF")
    dens.eruptions <- densityMclust(faithful$eruptions)
    plot(cdfMclust(dens.eruptions), type = "l", 
         xlab = dens.eruptions$varname, ylab = "CDF")
    par(mfrow = c(1,1))
}

test_16 <- function() {
    clPairs(iris[,1:4], cl = iris$Species)

    clp <- clPairs(iris[,1:4], cl = iris$Species, lower.panel = NULL)
    clPairsLegend(0.1, 0.4, class = clp$class, 
                  col = clp$col, pch = clp$pch, 
                  title = "Iris data")
}

test_17 <- function() {
    (a <- rep(1:3, 3))
    (b <- rep(c("A", "B", "C"), 3))
    classError(a, b)

    (a <- sample(1:3, 9, replace = TRUE))
    (b <- sample(c("A", "B", "C"), 9, replace = TRUE))
    classError(a, b)

    class <- factor(c(5,5,5,2,5,3,1,2,1,1), levels = 1:5)
    probs <- matrix(c(0.15, 0.01, 0.08, 0.23, 0.01, 0.23, 0.59, 0.02, 0.38, 0.45, 
                      0.36, 0.05, 0.30, 0.46, 0.15, 0.13, 0.06, 0.19, 0.27, 0.17, 
                      0.40, 0.34, 0.18, 0.04, 0.47, 0.34, 0.32, 0.01, 0.03, 0.11, 
                      0.04, 0.04, 0.09, 0.05, 0.28, 0.27, 0.02, 0.03, 0.12, 0.25, 
                      0.05, 0.56, 0.35, 0.22, 0.09, 0.03, 0.01, 0.75, 0.20, 0.02),
                    nrow = 10, ncol = 5)
    cbind(class, probs, map = map(probs))
    classError(map(probs), class)
}

test_18 <- function() {

    # generate data from a mixture f(x) = 0.9 * N(0,1) + 0.1 * N(3,1)
    n <- 10000
    mixpro <- c(0.9, 0.1)
    class <- factor(sample(0:1, size = n, prob = mixpro, replace = TRUE))
    x <- ifelse(class == 1, rnorm(n, mean = 3, sd = 1), 
                            rnorm(n, mean = 0, sd = 1))

    hist(x[class==0], breaks = 11, xlim = range(x), main = "", xlab = "x", 
         col = adjustcolor("dodgerblue2", alpha.f = 0.5), border = "white")
    hist(x[class==1], breaks = 11, add = TRUE,
         col = adjustcolor("red3", alpha.f = 0.5), border = "white")
    box()

    # generate training data from a balanced case-control sample, i.e.
    # f(x) = 0.5 * N(0,1) + 0.5 * N(3,1)
    n_train <- 1000
    class_train <- factor(sample(0:1, size = n_train, prob = c(0.5, 0.5), replace = TRUE))
    x_train <- ifelse(class_train == 1, rnorm(n_train, mean = 3, sd = 1), 
                                        rnorm(n_train, mean = 0, sd = 1))

    hist(x_train[class_train==0], breaks = 11, xlim = range(x_train), 
         main = "", xlab = "x", 
         col = adjustcolor("dodgerblue2", alpha.f = 0.5), border = "white")
    hist(x_train[class_train==1], breaks = 11, add = TRUE,
         col = adjustcolor("red3", alpha.f = 0.5), border = "white")
    box()

    # fit a MclustDA model
    mod <- MclustDA(x_train, class_train)
    summary(mod, parameters = TRUE)

    # test set performance
    pred <- predict(mod, newdata = x)
    classError(pred$classification, class)$error
    BrierScore(pred$z, class)

    # compute performance over a grid of prior probs
    priorProp <- seq(0.01, 0.99, by = 0.01)
    CE <- BS <- rep(as.double(NA), length(priorProp))
    for(i in seq(priorProp))
    {
      pred <- predict(mod, newdata = x, prop = c(1-priorProp[i], priorProp[i]))
      CE[i] <- classError(pred$classification, class = class)$error
      BS[i] <- BrierScore(pred$z, class)
    }

    # estimate the optimal class prior probs
    (priorProbs <- classPriorProbs(mod, x))
    pred <- predict(mod, newdata = x, prop = priorProbs)
    # compute performance at the estimated class prior probs
    classError(pred$classification, class = class)$error
    BrierScore(pred$z, class)

    matplot(priorProp, cbind(CE,BS), type = "l", lty = 1, lwd = 2,
            xlab = "Class prior probability", ylab = "", ylim = c(0,max(CE,BS)), 
            panel.first = 
              { abline(h = seq(0,1,by=0.05), col = "grey", lty = 3)
                abline(v = seq(0,1,by=0.05), col = "grey", lty = 3) 
              })
    abline(v = mod$prop[2], lty = 2)              # training prop
    abline(v = mean(class==1), lty = 4)           # test prop (usually unknown) 
    abline(v = priorProbs[2], lty = 3, lwd = 2)      # estimated prior probs
    legend("topleft", legend = c("ClassError", "BrierScore"),
           col = 1:2, lty = 1, lwd = 2, inset = 0.02)

    # Summary of results:
    priorProp[which.min(CE)] # best prior of class 1 according to classification error
    priorProp[which.min(BS)] # best prior of class 1 according to Brier score
    priorProbs               # optimal estimated class prior probabilities
}

test_19 <- function() {
    data(Baudry_etal_2010_JCGS_examples)

    # run Mclust using provided data
    output <- clustCombi(data = ex4.1) 

    # or run Mclust and then clustcombi on the returned object
    mod <- Mclust(ex4.1)
    output <- clustCombi(mod)


    output
    summary(output)


    # run Mclust using provided data and any further optional argument provided
    output <- clustCombi(data = ex4.1, modelName = "EEV", G = 1:15)


    # plot the hierarchy of combined solutions
    plot(output, what = "classification") 
    # plot some "entropy plots" which may help one to select the number of classes
    plot(output, what = "entropy") 
    # plot the tree structure obtained from combining mixture components
    plot(output, what = "tree") 

    # the selected model and number of components obtained from Mclust using BIC
    output$MclustOutput 

    # the matrix whose [i,k]th entry is the probability that i-th observation in 
    # the data belongs to the k-th class according to the BIC solution
    head( output$combiz[[output$MclustOutput$G]] ) 
    # the matrix whose [i,k]th entry is the probability that i-th observation in 
    # the data belongs to the k-th class according to the first combined solution
    head( output$combiz[[output$MclustOutput$G-1]] ) 
    # the matrix describing how to merge the 6-classes solution to get the 
    # 5-classes solution
    output$combiM[[5]] 
    # for example the following code returns the label of the class (in the 
    # 5-classes combined solution) to which the 4th class (in the 6-classes
    # solution) is assigned. Only two classes in the (K+1)-classes solution 
    # are assigned the same class in the K-classes solution: the two which 
    # are merged at this step 
    output$combiM[[5]] 
    # recover the 5-classes soft clustering from the 6-classes soft clustering 
    # and the 6 -> 5 combining matrix
    all( output$combiz[[5]] == t( output$combiM[[5]] %*% t(output$combiz[[6]]) ) ) 
    # the hard clustering under the 5-classes solution
    head( output$classification[[5]] )
}

test_20 <- function() {
    data(Baudry_etal_2010_JCGS_examples)
    output <- clustCombi(data = ex4.1) 
    combiOptim <- clustCombiOptim(output)
    str(combiOptim)

    # plot optimal clustering with alpha color transparency proportional to uncertainty
    zmax <- apply(combiOptim$z.combi, 1, max)
    col <- mclust.options("classPlotColors")[combiOptim$cluster.combi]
    vadjustcolor <- Vectorize(adjustcolor)
    alphacol = (zmax - 1/combiOptim$numClusters.combi)/(1-1/combiOptim$numClusters.combi)
    col <- vadjustcolor(col, alpha.f = alphacol)
    plot(ex4.1, col = col, pch = mclust.options("classPlotSymbols")[combiOptim$cluster.combi])
}

test_21 <- function() {

    data(Baudry_etal_2010_JCGS_examples)
    MclustOutput <- Mclust(ex4.1) 

    MclustOutput$G # Mclust/BIC selected 6 classes

    par(mfrow=c(2,2))

    combiM0 <- diag(6) # is the identity matrix
    # no merging: plot the initial solution, given by z
    combiPlot(ex4.1, MclustOutput$z, combiM0, cex = 3) 
    title("No combining")

    combiM1 <- combMat(6, 1, 2) # let's merge classes labeled 1 and 2
    combiM1
    combiPlot(ex4.1, MclustOutput$z, combiM1)
    title("Combine 1 and 2")

    # let's merge classes labeled 1 and 2, and then components labeled (in this 
    # new 5-classes combined solution) 1 and 2
    combiM2 <- combMat(5, 1, 2) %*% combMat(6, 1, 2) 
    combiM2 
    combiPlot(ex4.1, MclustOutput$z, combiM2)
    title("Combine 1, 2 and then 1 and 2 again")

    plot(0,0,type="n", xlab = "", ylab = "", axes = FALSE)
    legend("center", legend = 1:6,
           col = mclust.options("classPlotColors"), 
           pch = mclust.options("classPlotSymbols"), 
           title = "Class labels:")
}

test_22 <- function() {

    data(Baudry_etal_2010_JCGS_examples)
    output <- clustCombi(data = ex4.1) 
    combiTree(output)
    combiTree(output, type = "rectangle")
    combiTree(output, yaxis = "step")
    combiTree(output, type = "rectangle", yaxis = "step")
}

test_23 <- function() {

    est <- meVVV(iris[,-5], unmap(iris[,5]))
    par(pty = "s", mfrow = c(1,1))
    coordProj(iris[,-5], dimens=c(2,3), parameters = est$parameters, z = est$z,
              what = "classification", main = TRUE) 
    coordProj(iris[,-5], dimens=c(2,3), parameters = est$parameters, z = est$z,
              truth = iris[,5], what = "error", main = TRUE) 
    coordProj(iris[,-5], dimens=c(2,3), parameters = est$parameters, z = est$z,
              what = "uncertainty", main = TRUE)
}

test_24 <- function() {
    # Z as an indicator matrix
    X <- iris[,1:4]
    Z <- unmap(iris$Species)
    str(covw(X, Z))
    # Z as a matrix of weights
    mod <- Mclust(X, G = 3, modelNames = "VVV")
    str(covw(X, mod$z))
}

test_25 <- function() {
    # discriminant coordinates for the iris data using known classes 
    data("iris")
    CRIMCOORDS = crimcoords(iris[,-5], iris$Species)
    summary(CRIMCOORDS)
    plot(CRIMCOORDS)

    # banknote data
    data("banknote")

    # discriminant coordinate on known classes 
    CRIMCOORDS = crimcoords(banknote[,-1], banknote$Status)
    summary(CRIMCOORDS)
    plot(CRIMCOORDS)

    #  discriminant coordinates on estimated clusters
    mod = Mclust(banknote[,-1])
    CRIMCOORDS = crimcoords(banknote[,-1], mod$classification)
    summary(CRIMCOORDS)
    plot(CRIMCOORDS)
    plot(CRIMCOORDS$projection, type = "n")
    text(CRIMCOORDS$projection, cex = 0.8,
         labels = strtrim(banknote$Status, 2), 
         col = mclust.options("classPlotColors")[1:mod$G][mod$classification])
}

test_26 <- function() {
    # This dataset was created as follows

    n <- 250 
    set.seed(0)
    cross <- rbind(matrix(rnorm(n*2), n, 2) %*% diag(c(1,9)),
                   matrix(rnorm(n*2), n, 2) %*% diag(c(1,9))[,2:1])
    cross <- cbind(c(rep(1,n),rep(2,n)), cross)
}

test_27 <- function() {

    # Iris data
    Class <- iris$Species
    X <- iris[,1:4]

    ## EDDA model with common covariance (essentially equivalent to linear discriminant analysis)
    irisEDDA <- MclustDA(X, Class, modelType = "EDDA", modelNames = "EEE")
    cv <- cvMclustDA(irisEDDA)                         # 10-fold CV (default)
    str(cv)
    cv <- cvMclustDA(irisEDDA, nfold = length(Class))  # LOO-CV
    str(cv)

    ## MclustDA model selected by BIC
    irisMclustDA <- MclustDA(X, Class)
    cv <- cvMclustDA(irisMclustDA)                     # 10-fold CV (default)
    str(cv)

    # Banknote data
    data("banknote")
    Class <- banknote$Status
    X <- banknote[,2:7]

    ## EDDA model selected by BIC
    banknoteEDDA <- MclustDA(X, Class, modelType = "EDDA")
    cv <- cvMclustDA(banknoteEDDA)                     # 10-fold CV (default)
    str(cv)

    (ConfusionMatrix <- table(Pred = cv$classification, Class))
    TP <- ConfusionMatrix[1,1]
    FP <- ConfusionMatrix[1,2]
    FN <- ConfusionMatrix[2,1]
    TN <- ConfusionMatrix[2,2]
    (Sensitivity <- TP/(TP+FN))
    (Specificity <- TN/(FP+TN))
}

test_28 <- function() {
    meEst <- meVEV(iris[,-5], unmap(iris[,5])) 
    names(meEst)
    meEst$parameters$variance

    dec <- meEst$parameters$variance
    decomp2sigma(d=dec$d, G=dec$G, shape=dec$shape, scale=dec$scale,
                 orientation = dec$orientation)

    do.call("decomp2sigma", dec)  ## alternative call
}

test_29 <- function() {
    # default prior
    irisBIC <- mclustBIC(iris[,-5], prior = priorControl())
    summary(irisBIC, iris[,-5])

    # equivalent to previous example
    irisBIC <- mclustBIC(iris[,-5], 
                         prior = priorControl(functionName = "defaultPrior"))
    summary(irisBIC, iris[,-5])

    # no prior on the mean; default prior on variance
    irisBIC <- mclustBIC(iris[,-5], prior = priorControl(shrinkage = 0))
    summary(irisBIC, iris[,-5])

    # equivalent to previous example
    irisBIC <- mclustBIC(iris[,-5], prior =
                         priorControl(functionName="defaultPrior", shrinkage=0))
    summary(irisBIC, iris[,-5])

    defaultPrior( iris[-5], G = 3, modelName = "VVV")
}

test_30 <- function() {

    faithfulModel <- Mclust(faithful)
    Dens <- dens(modelName = faithfulModel$modelName, data = faithful,
                 parameters = faithfulModel$parameters)
    Dens

    ## alternative call
    do.call("dens", faithfulModel)
}

test_31 <- function() {
    dens <- densityMclust(faithful$waiting)
    summary(dens)
    summary(dens, parameters = TRUE)
    plot(dens, what = "BIC", legendArgs = list(x = "topright"))
    plot(dens, what = "density", data = faithful$waiting)

    dens <- densityMclust(faithful, modelNames = "EEE", G = 3, plot = FALSE)
    summary(dens)
    summary(dens, parameters = TRUE)
    plot(dens, what = "density", data = faithful, 
         drawlabels = FALSE, points.pch = 20)
    plot(dens, what = "density", type = "hdr")
    plot(dens, what = "density", type = "hdr", prob = c(0.1, 0.9))
    plot(dens, what = "density", type = "hdr", data = faithful)
    plot(dens, what = "density", type = "persp")


    dens <- densityMclust(iris[,1:4], G = 2)
    summary(dens, parameters = TRUE)
    plot(dens, what = "density", data = iris[,1:4], 
         col = "slategrey", drawlabels = FALSE, nlevels = 7)
    plot(dens, what = "density", type = "hdr", data = iris[,1:4])
    plot(dens, what = "density", type = "persp", col = grey(0.9))
}

test_32 <- function() {

    x <- faithful$waiting
    dens <- densityMclust(x, plot = FALSE)
    plot(dens, x, what = "diagnostic")
    # or
    densityMclust.diagnostic(dens, type = "cdf")
    densityMclust.diagnostic(dens, type = "qq")
}

test_33 <- function() {
    # univariate
    ngrid <- 101
    x <- seq(-5, 5, length = ngrid)
    dens <- dmvnorm(x, mean = 1, sigma = 5)
    plot(x, dens, type = "l")

    # bivariate
    ngrid <- 101
    x1 <- x2 <- seq(-5, 5, length = ngrid)
    mu <- c(1,0)
    sigma <- matrix(c(1,0.5,0.5,2), 2, 2)
    dens <- dmvnorm(as.matrix(expand.grid(x1, x2)), mu, sigma)
    dens <- matrix(dens, ngrid, ngrid)
    image(x1, x2, dens)
    contour(x1, x2, dens, add = TRUE)
}

test_34 <- function() {

    dupPartition(iris[,1:4])
    dupPartition(iris)
    dupPartition(iris$Species)
}

test_35 <- function() {

    msEst <- mstep(modelName = "EEE", data = iris[,-5], 
                   z = unmap(iris[,5]))
    names(msEst)

    em(modelName = msEst$modelName, data = iris[,-5],
       parameters = msEst$parameters)
}

test_36 <- function() {
    irisBIC <- mclustBIC(iris[,-5], control = emControl(tol = 1.e-6))
    summary(irisBIC, iris[,-5])
}

test_37 <- function() {

    msEst <- mstepEEE(data = iris[,-5], z = unmap(iris[,5]))
    names(msEst)

    emEEE(data = iris[,-5], parameters = msEst$parameters)
}

test_38 <- function() {

    data(Baudry_etal_2010_JCGS_examples)
    # run Mclust to get the MclustOutput
    output <- clustCombi(data = ex4.2, modelNames = "VII") 

    entPlot(output$MclustOutput$z, output$combiM, reg = c(2,3)) 
    # legend: in red, the single-change-point piecewise linear regression;
    #         in blue, the two-change-point piecewise linear regression.
}

test_39 <- function() {
    par(mfrow=c(2,2))
    # Create a simple example dataset
    x <- 1:5
    n <- c(10, 15, 12, 6, 3)
    se <- c(1, 1.2, 2, 1, .5)
    # upper and lower bars
    b <- barplot(n, ylim = c(0, max(n)*1.5))
    errorBars(b, lower = n-se, upper = n+se, lwd = 2, col = "red3")
    # one side bars
    b <- barplot(n, ylim = c(0, max(n)*1.5))
    errorBars(b, lower = n, upper = n+se, lwd = 2, col = "red3", code = 1)
    # 
    plot(x, n, ylim = c(0, max(n)*1.5), pch = 0)
    errorBars(x, lower = n-se, upper = n+se, lwd = 2, col = "red3")
    #
    dotchart(n, labels = x, pch = 19, xlim = c(0, max(n)*1.5))
    errorBars(x, lower = n-se, upper = n+se, col = "red3", horizontal = TRUE)
}

test_40 <- function() {

    msEst <- mstep(modelName = "VVV", data = iris[,-5], z = unmap(iris[,5]))
    names(msEst)

    estep(modelName = msEst$modelName, data = iris[,-5],
          parameters = msEst$parameters)
}

test_41 <- function() {

    msEst <- mstepEII(data = iris[,-5], z = unmap(iris[,5]))
    names(msEst)

    estepEII(data = iris[,-5], parameters = msEst$parameters)
}

test_42 <- function() {

    data(faithful)
    mod <- Mclust(faithful)
    summary(mod)
    plot(as.densityMclust(mod), faithful, what = "density", 
         points.pch = mclust.options("classPlotSymbols")[mod$classification], 
         points.col = mclust.options("classPlotColors")[mod$classification])

    GMMHD <- gmmhd(mod)
    summary(GMMHD)

    plot(GMMHD, what = "mode")
    plot(GMMHD, what = "cores")
    plot(GMMHD, what = "clusters")
}

test_43 <- function() {
    hcTree <- hc(modelName = "VVV", data = iris[,-5])
    hcTree
    cl <- hclass(hcTree,c(2,3))
    table(cl[,"2"])
    table(cl[,"3"])


    clPairs(iris[,-5], classification = cl[,"2"])
    clPairs(iris[,-5], classification = cl[,"3"])
}

test_44 <- function() {
    hcTree <- hcEII(data = iris[,-5])
    cl <- hclass(hcTree,c(2,3))


    par(pty = "s", mfrow = c(1,1))
    clPairs(iris[,-5],cl=cl[,"2"])
    clPairs(iris[,-5],cl=cl[,"3"])

    par(mfrow = c(1,2))
    dimens <- c(1,2)
    coordProj(iris[,-5], classification=cl[,"2"], dimens=dimens)
    coordProj(iris[,-5], classification=cl[,"3"], dimens=dimens)
}

test_45 <- function() {
    data <- iris[,1:4]
    randPairs <- hcRandomPairs(data)
    str(randPairs)
    # start model-based clustering from a random partition
    mod <- Mclust(data, initialization = list(hcPairs = randPairs))
    summary(mod)
}

test_46 <- function() {
    hcTree <- hc(modelName="VVV", data = iris[,-5])
    cl <- hclass(hcTree,c(2,3))


    par(pty = "s", mfrow = c(1,1))
    clPairs(iris[,-5],cl=cl[,"2"])
    clPairs(iris[,-5],cl=cl[,"3"])
}

test_47 <- function() {
    # Example: univariate Gaussian
    x <- rnorm(1000)
    f <- dnorm(x)
    a <- c(0.5, 0.25, 0.1)
    (f_a <- hdrlevels(f, prob = 1-a))

    plot(x, f)
    abline(h = f_a, lty = 2)
    text(max(x), f_a, labels = paste0("f_", a), pos = 3)

    mean(f > f_a[1])
    range(x[which(f > f_a[1])])
    qnorm(1-a[1]/2)

    mean(f > f_a[2])
    range(x[which(f > f_a[2])])
    qnorm(1-a[2]/2)

    mean(f > f_a[3])
    range(x[which(f > f_a[3])])
    qnorm(1-a[3]/2)

    # Example 2: univariate Gaussian mixture
    set.seed(1)
    cl <- sample(1:2, size = 1000, prob = c(0.7, 0.3), replace = TRUE)
    x <- ifelse(cl == 1, 
                rnorm(1000, mean = 0, sd = 1),
                rnorm(1000, mean = 4, sd = 1))
    f <- 0.7*dnorm(x, mean = 0, sd = 1) + 0.3*dnorm(x, mean = 4, sd = 1)

    a <- 0.25
    (f_a <- hdrlevels(f, prob = 1-a))

    plot(x, f)
    abline(h = f_a, lty = 2)
    text(max(x), f_a, labels = paste0("f_", a), pos = 3)

    mean(f > f_a)

    # find the regions of HDR
    ord <- order(x)
    f <- f[ord]
    x <- x[ord]
    x_a <- x[f > f_a]
    j <- which.max(diff(x_a))
    region1 <- x_a[c(1,j)]
    region2 <- x_a[c(j+1,length(x_a))]
    plot(x, f, type = "l")
    abline(h = f_a, lty = 2)
    abline(v = region1, lty = 3, col = 2)
    abline(v = region2, lty = 3, col = 3)
}

test_48 <- function() {
    hypvol(iris[,-5])
}

test_49 <- function() {
    mod <- Mclust(iris[,1:4])
    icl(mod)
}

test_50 <- function() {

    # Note that package 'mix' must be installed
    data(stlouis, package = "mix")
 
    # impute the continuos variables in the stlouis data
    stlimp <- imputeData(stlouis[,-(1:3)])

    # plot imputed values
    imputePairs(stlouis[,-(1:3)], stlimp)
}

test_51 <- function() {

    # Note that package 'mix' must be installed
    data(stlouis, package = "mix")
 
    # impute the continuos variables in the stlouis data
    stlimp <- imputeData(stlouis[,-(1:3)])

    # plot imputed values
    imputePairs(stlouis[,-(1:3)], stlimp)
}

test_52 <- function() {

    irisMclust <- Mclust(iris[,1:4])
    summary(irisMclust)
    logLik(irisMclust)
}

test_53 <- function() {

    irisMclustDA <- MclustDA(iris[,1:4], iris$Species)
    summary(irisMclustDA)
    logLik(irisMclustDA)
}

test_54 <- function() {
    x = matrix(rnorm(15), 5, 3)
    v = log(c(0.5, 0.3, 0.2))
    logsumexp(x, v)
}

test_55 <- function() {
    x <- c("A", "C", "A", "B", "C", "B", "A")
    majorityVote(x)
}

test_56 <- function() {
    emEst <- me(modelName = "VVV", data = iris[,-5], z = unmap(iris[,5]))

    map(emEst$z)
}

test_57 <- function() {
    a <- rep(1:3, 3)
    a
    b <- rep(c("A", "B", "C"), 3)
    b
    mapClass(a, b)
    a <- sample(1:3, 9, replace = TRUE)
    a
    b <- sample(c("A", "B", "C"), 9, replace = TRUE)
    b
    mapClass(a, b)
}

test_58 <- function() {
    opt <- mclust.options() # save default values
    irisBIC <- mclustBIC(iris[,-5])
    summary(irisBIC, iris[,-5])

    mclust.options(emModelNames = c("EII", "EEI", "EEE"))
    irisBIC <- mclustBIC(iris[,-5])
    summary(irisBIC, iris[,-5])

    mclust.options(opt)    # restore default values
    mclust.options()

    oldpar <- par(mfrow = c(2,1), no.readonly = TRUE)
    n <- with(mclust.options(), 
              max(sapply(list(bicPlotSymbols, bicPlotColors),length)))
    plot(seq(n), rep(1,n), ylab = "", xlab = "", yaxt = "n", 
         pch = mclust.options("bicPlotSymbols"), 
         col = mclust.options("bicPlotColors"))
    title("mclust.options(\"bicPlotSymbols\") \n mclust.options(\"bicPlotColors\")")
    n <- with(mclust.options(), 
              max(sapply(list(classPlotSymbols, classPlotColors),length)))
    plot(seq(n), rep(1,n), ylab = "", xlab = "", yaxt = "n", 
         pch = mclust.options("classPlotSymbols"), 
         col = mclust.options("classPlotColors"))
    title("mclust.options(\"classPlotSymbols\") \n mclust.options(\"classPlotColors\")")
    par(oldpar)
}

test_59 <- function() {

    n <- 250 ## create artificial data
    set.seed(1)
    y <- c(rnorm(n,-5), rnorm(n,0), rnorm(n,5))
    yclass <- c(rep(1,n), rep(2,n), rep(3,n))

    yModel <- Mclust(y)

    mclust1Dplot(y, parameters = yModel$parameters, z = yModel$z, 
                 what = "classification")

    mclust1Dplot(y, parameters = yModel$parameters, z = yModel$z, 
                 what = "error", truth = yclass)

    mclust1Dplot(y, parameters = yModel$parameters, z = yModel$z, 
                 what = "density")

    mclust1Dplot(y, z = yModel$z, parameters = yModel$parameters,
                what = "uncertainty")
}

test_60 <- function() {

    faithfulModel <- Mclust(faithful)

    mclust2Dplot(faithful, parameters=faithfulModel$parameters, 
                 z=faithfulModel$z, what = "classification", main = TRUE)

    mclust2Dplot(faithful, parameters=faithfulModel$parameters, 
                 z=faithfulModel$z, what = "uncertainty", main = TRUE)
}

test_61 <- function() {
    irisBIC <- mclustBIC(iris[,-5])
    irisBIC
    plot(irisBIC)


    subset <- sample(1:nrow(iris), 100)
    irisBIC <- mclustBIC(iris[,-5], initialization=list(subset = subset))
    irisBIC
    plot(irisBIC)

    irisBIC1 <- mclustBIC(iris[,-5], G=seq(from=1,to=9,by=2), 
                        modelNames=c("EII", "EEI", "EEE"))
    irisBIC1
    plot(irisBIC1)
    irisBIC2  <- mclustBIC(iris[,-5], G=seq(from=2,to=8,by=2), 
                           modelNames=c("VII", "VVI", "VVV"), x= irisBIC1)
    irisBIC2
    plot(irisBIC2)


    nNoise <- 450
    set.seed(0)
    poissonNoise <- apply(apply( iris[,-5], 2, range), 2, function(x, n) 
                          runif(n, min = x[1]-.1, max = x[2]+.1), n = nNoise)
    set.seed(0)
    noiseInit <- sample(c(TRUE,FALSE),size=nrow(iris)+nNoise,replace=TRUE,
                        prob=c(3,1))
    irisNdata <- rbind(iris[,-5], poissonNoise)
    irisNbic <- mclustBIC(data = irisNdata, G = 1:5,
                          initialization = list(noise = noiseInit))
    irisNbic
    plot(irisNbic)
}

test_62 <- function() {

    data(galaxies, package = "MASS") 
    galaxies <- galaxies / 1000

    # use several random starting points
    BIC <- NULL
    for(j in 1:100)
    {
      rBIC <- mclustBIC(galaxies, verbose = FALSE,
                        initialization = list(hcPairs = hcRandomPairs(galaxies)))
      BIC <- mclustBICupdate(BIC, rBIC)
    }
    pickBIC(BIC)
    plot(BIC)

    mod <- Mclust(galaxies, x = BIC)
    summary(mod)
}

test_63 <- function() {

    data(faithful)
    faithful.boot = mclustBootstrapLRT(faithful, model = "VVV")
    faithful.boot
    plot(faithful.boot, G = 1)
    plot(faithful.boot, G = 2)
}

test_64 <- function() {
    data(faithful)
    faithful.ICL <- mclustICL(faithful)
    faithful.ICL
    summary(faithful.ICL)
    plot(faithful.ICL)

    # compare with
    faithful.BIC <- mclustBIC(faithful)
    faithful.BIC
    plot(faithful.BIC)
}

test_65 <- function() {

    BIC <- mclustBIC(iris[,1:4])
    mclustLoglik(BIC)
}

test_66 <- function() {
    irisBIC <- mclustBIC(iris[,-5])
    mclustModel(iris[,-5], irisBIC)
    mclustModel(iris[,-5], irisBIC, G = 1:6, modelNames = c("VII", "VVI", "VVV"))
}

test_67 <- function() {
    mclustModelNames("E")
    mclustModelNames("EEE")
    mclustModelNames("VVV")
    mclustModelNames("XXI")
}

test_68 <- function() {

    me(modelName = "VVV", data = iris[,-5], z = unmap(iris[,5]))
}

test_69 <- function() {
    w = rexp(nrow(iris))
    w = w/mean(w)
    c(summary(w), sum = sum(w))
    z = unmap(sample(1:3, size = nrow(iris), replace = TRUE))
    MEW = me.weighted(data = iris[,-5], modelName = "VVV", 
                      z = z, weights = w)
    str(MEW,1)
}

test_70 <- function() {
    meVVV(data = iris[,-5], z = unmap(iris[,5]))
}

test_71 <- function() {

    mstep(modelName = "VII", data = iris[,-5], z = unmap(iris[,5]))
}

test_72 <- function() {

    mstepVII(data = iris[,-5], z = unmap(iris[,5]))
}

test_73 <- function() {
    n <- 1000

    set.seed(0)
    x <- rnorm(n, mean = -1, sd = 2)
    mvn(modelName = "X", x) 

    mu <- c(-1, 0, 1)

    set.seed(0)
    x <- sweep(matrix(rnorm(n*3), n, 3) %*% (2*diag(3)), 
               MARGIN = 2, STATS = mu, FUN = "+")
    mvn(modelName = "XII", x) 
    mvn(modelName = "Spherical", x) 

    set.seed(0)
    x <- sweep(matrix(rnorm(n*3), n, 3) %*% diag(1:3), 
               MARGIN = 2, STATS = mu, FUN = "+")
    mvn(modelName = "XXI", x)
    mvn(modelName = "Diagonal", x)

    Sigma <- matrix(c(9,-4,1,-4,9,4,1,4,9), 3, 3)
    set.seed(0)
    x <- sweep(matrix(rnorm(n*3), n, 3) %*% chol(Sigma), 
               MARGIN = 2, STATS = mu, FUN = "+")
    mvn(modelName = "XXX", x) 
    mvn(modelName = "Ellipsoidal", x)
}

test_74 <- function() {

    n <- 1000

    set.seed(0)
    x <- rnorm(n, mean = -1, sd = 2)
    mvnX(x) 

    mu <- c(-1, 0, 1)

    set.seed(0)
    x <- sweep(matrix(rnorm(n*3), n, 3) %*% (2*diag(3)), 
               MARGIN = 2, STATS = mu, FUN = "+")
    mvnXII(x) 

    set.seed(0)
    x <- sweep(matrix(rnorm(n*3), n, 3) %*% diag(1:3), 
               MARGIN = 2, STATS = mu, FUN = "+")
    mvnXXI(x)

    Sigma <- matrix(c(9,-4,1,-4,9,4,1,4,9), 3, 3)
    set.seed(0)
    x <- sweep(matrix(rnorm(n*3), n, 3) %*% chol(Sigma), 
               MARGIN = 2, STATS = mu, FUN = "+")
    mvnXXX(x)
}

test_75 <- function() {
    mapply(nMclustParams, mclust.options("emModelNames"), d = 2, G = 3)
}

test_76 <- function() {
    mapply(nVarParams, mclust.options("emModelNames"), d = 2, G = 3)
}

test_77 <- function() {
    partconv(iris[,5])

    set.seed(0)
    cl <- sample(LETTERS[1:9], 25, replace=TRUE)
    partconv(cl, consec=FALSE)
    partconv(cl, consec=TRUE)
}

test_78 <- function() {
    set.seed(0)

    mat <- data.frame(lets = sample(LETTERS[1:2],9,TRUE), nums = sample(1:2,9,TRUE))
    mat

    ans <- partuniq(mat)
    ans

    partconv(ans,consec=TRUE)
}

test_79 <- function() {

    precipMclust <- Mclust(precip)
    plot(precipMclust)

    faithfulMclust <- Mclust(faithful)
    plot(faithfulMclust)

    irisMclust <- Mclust(iris[,-5])
    plot(irisMclust)
}

test_80 <- function() {

    data(diabetes)
    X <- diabetes[,-1]
    modClust <- Mclust(X, G = 3, modelNames = "VVV")
    bootClust <- MclustBootstrap(modClust, nboot = 99)
    par(mfrow = c(1,3), mar = c(4,2,2,0.5))
    plot(bootClust, what = "pro")
    par(mfrow = c(3,3), mar = c(4,2,2,0.5))
    plot(bootClust, what = "mean")
}

test_81 <- function() {

    odd <- seq(from = 1, to = nrow(iris), by = 2)
    even <- odd + 1
    X.train <- iris[odd,-5]
    Class.train <- iris[odd,5]
    X.test <- iris[even,-5]
    Class.test <- iris[even,5]

    # common EEE covariance structure (which is essentially equivalent to linear discriminant analysis)
    irisMclustDA <- MclustDA(X.train, Class.train, modelType = "EDDA", modelNames = "EEE")
    summary(irisMclustDA, parameters = TRUE)
    summary(irisMclustDA, newdata = X.test, newclass = Class.test)

    # common covariance structure selected by BIC
    irisMclustDA <- MclustDA(X.train, Class.train, modelType = "EDDA")
    summary(irisMclustDA, parameters = TRUE)
    summary(irisMclustDA, newdata = X.test, newclass = Class.test)

    # general covariance structure selected by BIC
    irisMclustDA <- MclustDA(X.train, Class.train)
    summary(irisMclustDA, parameters = TRUE)
    summary(irisMclustDA, newdata = X.test, newclass = Class.test)

    plot(irisMclustDA)
    plot(irisMclustDA, dimens = 3:4)
    plot(irisMclustDA, dimens = 4)

    plot(irisMclustDA, what = "classification")
    plot(irisMclustDA, what = "classification", newdata = X.test)
    plot(irisMclustDA, what = "classification", dimens = 3:4)
    plot(irisMclustDA, what = "classification", newdata = X.test, dimens = 3:4)
    plot(irisMclustDA, what = "classification", dimens = 4)
    plot(irisMclustDA, what = "classification", dimens = 4, newdata = X.test)

    plot(irisMclustDA, what = "train&test", newdata = X.test)
    plot(irisMclustDA, what = "train&test", newdata = X.test, dimens = 3:4)
    plot(irisMclustDA, what = "train&test", newdata = X.test, dimens = 4)

    plot(irisMclustDA, what = "error")
    plot(irisMclustDA, what = "error", dimens = 3:4)
    plot(irisMclustDA, what = "error", dimens = 4)
    plot(irisMclustDA, what = "error", newdata = X.test, newclass = Class.test)
    plot(irisMclustDA, what = "error", newdata = X.test, newclass = Class.test, dimens = 3:4)
    plot(irisMclustDA, what = "error", newdata = X.test, newclass = Class.test, dimens = 4)

    # simulated 1D data
    n <- 250 
    set.seed(1)
    triModal <- c(rnorm(n,-5), rnorm(n,0), rnorm(n,5))
    triClass <- c(rep(1,n), rep(2,n), rep(3,n))
    odd <- seq(from = 1, to = length(triModal), by = 2)
    even <- odd + 1
    triMclustDA <- MclustDA(triModal[odd], triClass[odd])
    summary(triMclustDA, parameters = TRUE)
    summary(triMclustDA, newdata = triModal[even], newclass = triClass[even])
    plot(triMclustDA)
    plot(triMclustDA, what = "classification")
    plot(triMclustDA, what = "classification", newdata = triModal[even])
    plot(triMclustDA, what = "train&test", newdata = triModal[even])
    plot(triMclustDA, what = "error")
    plot(triMclustDA, what = "error", newdata = triModal[even], newclass = triClass[even])

    # simulated 2D cross data
    data(cross)
    odd <- seq(from = 1, to = nrow(cross), by = 2)
    even <- odd + 1
    crossMclustDA <- MclustDA(cross[odd,-1], cross[odd,1])
    summary(crossMclustDA, parameters = TRUE)
    summary(crossMclustDA, newdata = cross[even,-1], newclass = cross[even,1])
    plot(crossMclustDA)
    plot(crossMclustDA, what = "classification")
    plot(crossMclustDA, what = "classification", newdata = cross[even,-1])
    plot(crossMclustDA, what = "train&test", newdata = cross[even,-1])
    plot(crossMclustDA, what = "error")
    plot(crossMclustDA, what = "error", newdata =cross[even,-1], newclass = cross[even,1])
}

test_82 <- function() {

    mod <- Mclust(iris[,1:4], G = 3)
    dr <- MclustDR(mod, lambda = 0.5)
    plot(dr, what = "evalues")
    plot(dr, what = "pairs")
    plot(dr, what = "scatterplot", dimens = c(1,3))
    plot(dr, what = "contour")
    plot(dr, what = "classification", ngrid = 200)
    plot(dr, what = "boundaries", ngrid = 200)
    plot(dr, what = "density")
    plot(dr, what = "density", dimens = 2)

    data(banknote)
    da <- MclustDA(banknote[,2:7], banknote$Status, G = 1:3)
    dr <- MclustDR(da)
    plot(dr, what = "evalues")
    plot(dr, what = "pairs")
    plot(dr, what = "contour")
    plot(dr, what = "classification", ngrid = 200)
    plot(dr, what = "boundaries", ngrid = 200)
    plot(dr, what = "density")
    plot(dr, what = "density", dimens = 2)
}

test_83 <- function() {
    X <- iris[,1:4]
    class <- iris$Species
    # randomly remove class labels
    set.seed(123)
    class[sample(1:length(class), size = 120)] <- NA
    table(class, useNA = "ifany")
    clPairs(X, ifelse(is.na(class), 0, class),
            symbols = c(0, 16, 17, 18), colors = c("grey", 4, 2, 3),
            main = "Partially classified data")

    # Fit semi-supervised classification model
    mod_SSC  <- MclustSSC(X, class)
    summary(mod_SSC, parameters = TRUE)

    pred_SSC <- predict(mod_SSC)
    table(Predicted = pred_SSC$classification, Actual = class, useNA = "ifany")

    plot(mod_SSC, what = "BIC")
    plot(mod_SSC, what = "classification")
    plot(mod_SSC, what = "uncertainty")
}

test_84 <- function() {

    data(Baudry_etal_2010_JCGS_examples)

    ## 1D Example 
    output <- clustCombi(data = Test1D, G=1:15)

    # plots the hierarchy of combined solutions, then some "entropy plots" which 
    # may help one to select the number of classes (please see the article cited 
    # in the references)
    plot(output) 

    ## 2D Example 
    output <- clustCombi(data = ex4.1) 

    # plots the hierarchy of combined solutions, then some "entropy plots" which 
    # may help one to select the number of classes (please see the article cited 
    # in the references)
    plot(output) 

    ## 3D Example 
    output <- clustCombi(data = ex4.4.2)

    # plots the hierarchy of combined solutions, then some "entropy plots" which 
    # may help one to select the number of classes (please see the article cited 
    # in the references)
    plot(output)
}

test_85 <- function() {

    dens <- densityMclust(faithful$waiting, plot = FALSE)
    summary(dens)
    summary(dens, parameters = TRUE)
    plot(dens, what = "BIC", legendArgs = list(x = "topright"))
    plot(dens, what = "density", data = faithful$waiting)

    dens <- densityMclust(faithful, plot = FALSE)
    summary(dens)
    summary(dens, parameters = TRUE)
    plot(dens, what = "density", data = faithful, 
         drawlabels = FALSE, points.pch = 20)
    plot(dens, what = "density", type = "hdr")
    plot(dens, what = "density", type = "hdr", prob = seq(0.1, 0.9, by = 0.1))
    plot(dens, what = "density", type = "hdr", data = faithful)
    plot(dens, what = "density", type = "persp")

    dens <- densityMclust(iris[,1:4], plot = FALSE)
    summary(dens, parameters = TRUE)
    plot(dens, what = "density", data = iris[,1:4], 
         col = "slategrey", drawlabels = FALSE, nlevels = 7)
    plot(dens, what = "density", type = "hdr", data = iris[,1:4])
    plot(dens, what = "density", type = "persp", col = grey(0.9))
}

test_86 <- function() {
    data(EuroUnemployment)
    hcTree <- hc(modelName = "VVV", data = EuroUnemployment)
    plot(hcTree, what = "loglik")
    plot(hcTree, what = "loglik", labels = TRUE)
    plot(hcTree, what = "loglik", maxG = 5, labels = TRUE)
    plot(hcTree, what = "merge")
    plot(hcTree, what = "merge", labels = TRUE)
    plot(hcTree, what = "merge", labels = TRUE, hang = 0.1)
    plot(hcTree, what = "merge", labels = TRUE, hang = -1)
    plot(hcTree, what = "merge", labels = TRUE, maxG = 5)
}

test_87 <- function() {

    plot(mclustBIC(precip), legendArgs =  list(x = "bottomleft"))

    plot(mclustBIC(faithful))

    plot(mclustBIC(iris[,-5]))
}

test_88 <- function() {

    data(faithful)
    faithful.ICL = mclustICL(faithful)
    plot(faithful.ICL)
}

test_89 <- function() {
    model <- Mclust(faithful)

    # predict cluster for the observed data
    pred <- predict(model) 
    str(pred)
    pred$z              # equal to model$z
    pred$classification # equal to 
    plot(faithful, col = pred$classification, pch = pred$classification)

    # predict cluster over a grid
    grid <- apply(faithful, 2, function(x) seq(min(x), max(x), length = 50))
    grid <- expand.grid(eruptions = grid[,1], waiting = grid[,2])
    pred <- predict(model, grid)
    plot(grid, col = mclust.options("classPlotColors")[pred$classification], pch = 15, cex = 0.5)
    points(faithful, pch = model$classification)
}

test_90 <- function() {

    odd <- seq(from = 1, to = nrow(iris), by = 2)
    even <- odd + 1
    X.train <- iris[odd,-5]
    Class.train <- iris[odd,5]
    X.test <- iris[even,-5]
    Class.test <- iris[even,5]

    irisMclustDA <- MclustDA(X.train, Class.train)

    predTrain <- predict(irisMclustDA)
    predTrain
    predTest <- predict(irisMclustDA, X.test)
    predTest
}

test_91 <- function() {
    mod = Mclust(iris[,1:4])
    dr = MclustDR(mod)
    pred = predict(dr)
    str(pred)

    data(banknote)
    mod = MclustDA(banknote[,2:7], banknote$Status)
    dr = MclustDR(mod)
    pred = predict(dr)
    str(pred)
}

test_92 <- function() {

    X <- iris[,1:4]
    class <- iris$Species
    # randomly remove class labels
    set.seed(123)
    class[sample(1:length(class), size = 120)] <- NA
    table(class, useNA = "ifany")
    clPairs(X, ifelse(is.na(class), 0, class),
            symbols = c(0, 16, 17, 18), colors = c("grey", 4, 2, 3),
            main = "Partially classified data")

    # Fit semi-supervised classification model
    mod_SSC  <- MclustSSC(X, class)

    pred_SSC <- predict(mod_SSC)
    table(Predicted = pred_SSC$classification, Actual = class, useNA = "ifany")

    X_new = data.frame(Sepal.Length = c(5, 8),
                       Sepal.Width  = c(3.1, 4),
                       Petal.Length = c(2, 5),
                       Petal.Width  = c(0.5, 2))
    predict(mod_SSC, newdata = X_new)
}

test_93 <- function() {

    x <- faithful$waiting
    dens <- densityMclust(x, plot = FALSE)
    x0 <- seq(50, 100, by = 10)
    d0 <- predict(dens, x0)
    plot(dens, what = "density")
    points(x0, d0, pch = 20)
}

test_94 <- function() {
    # default prior
    irisBIC <- mclustBIC(iris[,-5], prior = priorControl())
    summary(irisBIC, iris[,-5])

    # no prior on the mean; default prior on variance
    irisBIC <- mclustBIC(iris[,-5], prior = priorControl(shrinkage = 0))
    summary(irisBIC, iris[,-5])
}

test_95 <- function() {

    est <- meVVV(iris[,-5], unmap(iris[,5]))
    par(pty = "s", mfrow = c(1,1))
    randProj(iris[,-5], seeds=1:3, parameters = est$parameters, z = est$z,
              what = "classification", main = TRUE) 
    randProj(iris[,-5], seeds=1:3, parameters = est$parameters, z = est$z,
              truth = iris[,5], what = "error", main = TRUE) 
    randProj(iris[,-5], seeds=1:3, parameters = est$parameters, z = est$z,
              what = "uncertainty", main = TRUE)
}

test_96 <- function() {
    B <- randomOrthogonalMatrix(10,3)
    zapsmall(crossprod(B))
}

test_97 <- function() {
    meEst <- meEEE(iris[,-5], unmap(iris[,5])) 
    names(meEst$parameters$variance)
    meEst$parameters$variance$Sigma

    sigma2decomp(meEst$parameters$variance$Sigma, G = length(unique(iris[,5])))
}

test_98 <- function() {
    irisBIC <- mclustBIC(iris[,-5])
    irisModel <- mclustModel(iris[,-5], irisBIC)
    names(irisModel)
    irisSim <- sim(modelName = irisModel$modelName, 
                   parameters = irisModel$parameters, 
                   n = nrow(iris))


      do.call("sim", irisModel) # alternative call


    par(pty = "s", mfrow = c(1,2))

    dimnames(irisSim) <- list(NULL, c("dummy", (dimnames(iris)[[2]])[-5]))

    dimens <- c(1,2)
    lim1 <- apply(iris[,dimens],2,range)
    lim2 <- apply(irisSim[,dimens+1],2,range)
    lims <- apply(rbind(lim1,lim2),2,range)
    xlim <- lims[,1]
    ylim <- lims[,2]

    coordProj(iris[,-5], parameters=irisModel$parameters, 
              classification=map(irisModel$z), 
              dimens=dimens, xlim=xlim, ylim=ylim)

    coordProj(iris[,-5], parameters=irisModel$parameters, 
              classification=map(irisModel$z), truth = irisSim[,-1],
              dimens=dimens, xlim=xlim, ylim=ylim)

    irisModel3 <- mclustModel(iris[,-5], irisBIC, G=3)
    irisSim3 <- sim(modelName = irisModel3$modelName, 
                   parameters = irisModel3$parameters, n = 500, seed = 1)

     irisModel3$n <- NULL
     irisSim3 <- do.call("sim",c(list(n=500,seed=1),irisModel3)) # alternative call

    clPairs(irisSim3[,-1], cl = irisSim3[,1])
}

test_99 <- function() {

    d <- 2
    G <- 2
    scale <- 1
    shape <- c(1, 9)

    O1 <- diag(2)
    O2 <- diag(2)[,c(2,1)]
    O <- array(cbind(O1,O2), c(2, 2, 2))
    O

    variance <- list(d= d, G = G, scale = scale, shape = shape, orientation = O)
    mu <- matrix(0, d, G) ## center at the origin
    simdat <- simEEV( n = 200, 
                      parameters = list(pro=c(1,1),mean=mu,variance=variance),
                      seed = NULL)

    cl <- simdat[,1]

    sigma <- array(apply(O, 3, function(x,y) crossprod(x*y), 
                     y = sqrt(scale*shape)), c(2,2,2))
    paramList <- list(mu = mu, sigma = sigma)
    coordProj( simdat, parameters = paramList, classification = cl)
}

test_100 <- function() {
    mod <- Mclust(iris[,-5])
    iris_sim <- simulate(mod, n = 1000)
    str(iris_sim)
    clPairs(iris_sim[,-1], iris_sim[,1])

    x <- iris$Petal.Length
    mod <- densityMclust(x, plot = FALSE)
    x_sim <- simulate(mod, n = 1000)
    str(x_sim)
    hist(x_sim, breaks = 31, main = NULL, probability = TRUE)
    rug(x_sim)
    x0 = seq(0.5, 9, length = 101)
    lines(x0, predict(mod, newdata = x0))
}

test_101 <- function() {
    x = matrix(rnorm(15), 5, 3)
    v = log(c(0.5, 0.3, 0.2))
    (z = softmax(x, v))
    rowSums(z)
}

test_102 <- function() {

    mod1 = Mclust(iris[,1:4])
    summary(mod1)
    summary(mod1, parameters = TRUE, classification = FALSE)

    mod2 = densityMclust(faithful, plot = FALSE)
    summary(mod2)
    summary(mod2, parameters = TRUE)
}

test_103 <- function() {

    data(diabetes)
    X = diabetes[,-1]
    modClust = Mclust(X) 
    bootClust = MclustBootstrap(modClust)
    summary(bootClust, what = "se")
    summary(bootClust, what = "ci")

    data(acidity)
    modDens = densityMclust(acidity, plot = FALSE)
    modDens = MclustBootstrap(modDens)
    summary(modDens, what = "se")
    summary(modDens, what = "ci")
}

test_104 <- function() {
    mod = MclustDA(data = iris[,1:4], class = iris$Species)
    summary(mod)
    summary(mod, parameters = TRUE)
}

test_105 <- function() {
    irisBIC <- mclustBIC(iris[,-5])
    summary(irisBIC, iris[,-5])
    summary(irisBIC, iris[,-5], G = 1:6, modelNames = c("VII", "VVI", "VVV"))
}

test_106 <- function() {

    faithfulModel <- Mclust(faithful)
    surfacePlot(faithful, parameters = faithfulModel$parameters,
                type = "contour", what = "density", transformation = "none",
                drawlabels = FALSE)
    surfacePlot(faithful, parameters = faithfulModel$parameters,
                type = "persp", what = "density", transformation = "log")
    surfacePlot(faithful, parameters = faithfulModel$parameters,
                type = "contour", what = "uncertainty", transformation = "log")
}

test_107 <- function() {
    irisModel3 <-  Mclust(iris[,-5], G = 3)

    uncerPlot(z = irisModel3$z)
 
    uncerPlot(z = irisModel3$z, truth = iris[,5])
}

test_108 <- function() {
    z <- unmap(iris[,5])
    z[1:5, ]
  
    emEst <- me(modelName = "VVV", data = iris[,-5], z = z)
    emEst$z[1:5,]
  
    map(emEst$z)
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

cat("Running test_22\n")
test_22()

cat("Running test_23\n")
test_23()

cat("Running test_24\n")
test_24()

cat("Running test_25\n")
test_25()

cat("Running test_26\n")
test_26()

cat("Running test_27\n")
test_27()

cat("Running test_28\n")
test_28()

cat("Running test_29\n")
test_29()

cat("Running test_30\n")
test_30()

cat("Running test_31\n")
test_31()

cat("Running test_32\n")
test_32()

cat("Running test_33\n")
test_33()

cat("Running test_34\n")
test_34()

cat("Running test_35\n")
test_35()

cat("Running test_36\n")
test_36()

cat("Running test_37\n")
test_37()

cat("Running test_38\n")
test_38()

cat("Running test_39\n")
test_39()

cat("Running test_40\n")
test_40()

cat("Running test_41\n")
test_41()

cat("Running test_42\n")
test_42()

cat("Running test_43\n")
test_43()

cat("Running test_44\n")
test_44()

cat("Running test_45\n")
test_45()

cat("Running test_46\n")
test_46()

cat("Running test_47\n")
test_47()

cat("Running test_48\n")
test_48()

cat("Running test_49\n")
test_49()

cat("Running test_50\n")
test_50()

cat("Running test_51\n")
test_51()

cat("Running test_52\n")
test_52()

cat("Running test_53\n")
test_53()

cat("Running test_54\n")
test_54()

cat("Running test_55\n")
test_55()

cat("Running test_56\n")
test_56()

cat("Running test_57\n")
test_57()

cat("Running test_58\n")
test_58()

cat("Running test_59\n")
test_59()

cat("Running test_60\n")
test_60()

cat("Running test_61\n")
test_61()

cat("Running test_62\n")
test_62()

cat("Running test_63\n")
test_63()

cat("Running test_64\n")
test_64()

cat("Running test_65\n")
test_65()

cat("Running test_66\n")
test_66()

cat("Running test_67\n")
test_67()

cat("Running test_68\n")
test_68()

cat("Running test_69\n")
test_69()

cat("Running test_70\n")
test_70()

cat("Running test_71\n")
test_71()

cat("Running test_72\n")
test_72()

cat("Running test_73\n")
test_73()

cat("Running test_74\n")
test_74()

cat("Running test_75\n")
test_75()

cat("Running test_76\n")
test_76()

cat("Running test_77\n")
test_77()

cat("Running test_78\n")
test_78()

cat("Running test_79\n")
test_79()

cat("Running test_80\n")
test_80()

cat("Running test_81\n")
test_81()

cat("Running test_82\n")
test_82()

cat("Running test_83\n")
test_83()

cat("Running test_84\n")
test_84()

cat("Running test_85\n")
test_85()

cat("Running test_86\n")
test_86()

cat("Running test_87\n")
test_87()

cat("Running test_88\n")
test_88()

cat("Running test_89\n")
test_89()

cat("Running test_90\n")
test_90()

cat("Running test_91\n")
test_91()

cat("Running test_92\n")
test_92()

cat("Running test_93\n")
test_93()

cat("Running test_94\n")
test_94()

cat("Running test_95\n")
test_95()

cat("Running test_96\n")
test_96()

cat("Running test_97\n")
test_97()

cat("Running test_98\n")
test_98()

cat("Running test_99\n")
test_99()

cat("Running test_100\n")
test_100()

cat("Running test_101\n")
test_101()

cat("Running test_102\n")
test_102()

cat("Running test_103\n")
test_103()

cat("Running test_104\n")
test_104()

cat("Running test_105\n")
test_105()

cat("Running test_106\n")
test_106()

cat("Running test_107\n")
test_107()

cat("Running test_108\n")
test_108()

