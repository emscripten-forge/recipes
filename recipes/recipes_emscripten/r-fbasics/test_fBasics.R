print('Loading fBasics package')
library(fBasics)
print('... fBasics package loaded successfully')

test_1 <- function() {

    ## Simulated Monthly Return Data
    tS <- timeSeries(matrix(rnorm(12)), timeDate::timeCalendar())
    basicStats(tS)
}

test_2 <- function() {
    ## data
    data(LPP2005REC, package = "timeSeries")
    LPP <- LPP2005REC[, 1:6]
    plot(LPP, type = "l", col = "steelblue", main = "SP500")
    abline(h = 0, col = "grey")
   
    boxPlot(LPP)
}

test_3 <- function() {
    set.seed(1953)
    s <- rnorm(n = 1000, 0.5, 2) 

    nFit(s, doplot = TRUE)
}

test_4 <- function() {
    x <- sort(round(c(-1, -0.5, 0, 0.5, 1, 5*rnorm(5)), 2))

    h <- Heaviside(x)
    s <- Sign(x)
    d <- Delta(x)
    Pi <- Boxcar(x)
    r <- Ramp(x)

    cbind(x = x, Step = h, Signum = s, Delta = d, Pi = Pi, R = r)
}

test_5 <- function() {
    ## data
    data(LPP2005REC, package = "timeSeries")
    SPI <- LPP2005REC[, "SPI"]
    plot(SPI, type = "l", col = "steelblue", main = "SP500")
    abline(h = 0, col = "grey")
   
    histPlot(SPI) 
   
    densityPlot(SPI)
}

test_6 <- function() {
    ## Create Pascal Matrix:
    P <- pascal(3)
    P
 
    rownames(P) <- letters[1:3]
    P   
   
    colIds(P) <- as.character(1:3)
    P
}

test_7 <- function() {

    x <- rnorm(100)

    ## Kolmogorov-Smirnov one-sampe test
    ksnormTest(x)

    ## Shapiro-Wilk test
    shapiroTest(x)

    ## Jarque-Bera Test
    jarqueberaTest(x)
    jbTest(x)
}

test_8 <- function() {
    ## data
    data(LPP2005REC, package = "timeSeries")
    SPI <- LPP2005REC[, "SPI"]
    plot(SPI, type = "l", col = "steelblue", main = "SP500")
    abline(h = 0, col = "grey")
   
    qqnormPlot(SPI)
}

test_9 <- function() {
    ## data
    data(LPP2005REC, package = "timeSeries")
    SPI <- LPP2005REC[, "SPI"]
    plot(SPI, type = "l", col = "steelblue", main = "SP500")
    abline(h = 0, col = "grey")

    ## Scaling Law Effect
    scalinglawPlot(SPI)
}

test_10 <- function() {
    if(dev.interactive())
       stableSlider()
}

test_11 <- function() {
    data(LPP2005REC, package = "timeSeries")
    tS <- as.timeSeries(LPP2005REC)

    seriesPlot(tS)
}

test_12 <- function() {
    ## data
    data(LPP2005REC, package = "timeSeries")
    SPI <- LPP2005REC[, "SPI"]
    plot(SPI, type = "l", col = "steelblue", main = "SP500")
    abline(h = 0, col = "grey")

    ## Taylor Effect:
    teffectPlot(SPI)
}

test_13 <- function() {
    ## Character Table for Font 1:
    # characterTable(font = 1)
}

test_14 <- function() {
    x = rnorm(5)
   
    colVec(x)
    rowVec(x)
}

test_15 <- function() {
     colorLocator()
}

test_16 <- function() {
    greyPalette()
}

test_17 <- function() {
    colorTable()
}

test_18 <- function() {

    x <- rnorm(50)
    y <- rnorm(50)
  
    correlationTest(x, y, "pearson")
    correlationTest(x, y, "kendall")

    spearmanTest(x, y)
}

test_19 <- function() {
    plot(x = rnorm(100), type = "l", col = "red", 
         xlab = "", ylab = "Variates", las = 1)
    title("Normal Deviates", adj = 0)
    hgrid()
    boxL()
    copyright()
}

test_20 <- function() {
    distCheck("norm", mean = 1, sd = 1)

    distCheck("lnorm", meanlog = 0.5, sdlog = 2, robust=FALSE)
    ## here, true E(X) = exp(mu + 1/2 sigma^2) = exp(.5 + 2) = exp(2.5) = 12.182
    ## and      Var(X) = exp(2*mu + sigma^2)*(exp(sigma^2) - 1) =       7954.67
}

test_21 <- function() {
    ## Plot DowJones30 Example Data Set
    series <- timeSeries::as.timeSeries(DowJones30)
    head(series)
    plot(series[,1:6], type = "l")

    ## msft.dat contains (almost?) the same data as MSFT in package timeSeries
    data(MSFT, package = "timeSeries")

    m1 <- as.matrix(msft.dat[, -1]) # drop date stamps in column 1
    m2 <- as.matrix(MSFT)
    all.equal(m1, m2, check.attributes = FALSE) # TRUE
    ## compare the dates:
    all.equal(format(msft.dat[ , 1]), format(time(MSFT))) # TRUE
}

test_22 <- function() {
    showClass("fDISTFIT")
}

test_23 <- function() {
    showClass("fHTEST")
}

test_24 <- function() {
    ## Example S4 Representation:
    ## Hyothesis Testing with Control Settings
    setClass("hypTest",
             representation(
                 call = "call",
                 data = "numeric",
                 test = "list",
                 description = "character")
             )

    ## Shapiro Wilk Normaility Test
    swTest = function(x, description = "") {
        ans = shapiro.test(x)
        class(ans) = "list"
        new("hypTest",
            call = match.call(),
            data = x,
            test = ans,
            description = description)
    }
    test = swTest(x = rnorm(500), description = "500 RVs")

    ## Extractor Functions:
    isS4(test)
    getCall(test)
    getDescription(test)

    ## get arguments
    args(returns)
    getArgs(returns)
    getArgs("returns")
    getArgs(returns, "timeSeries")
    getArgs("returns", "timeSeries")
}

test_25 <- function() {
   
    ## rgh -
       set.seed(1953)
       r = rgh(5000, alpha = 1, beta = 0.3, delta = 1)
       plot(r, type = "l", col = "steelblue",
         main = "gh: alpha=1 beta=0.3 delta=1")
 
    ## dgh - 
       # Plot empirical density and compare with true density:
       hist(r, n = 25, probability = TRUE, border = "white", col = "steelblue")
       x = seq(-5, 5, 0.25)
       lines(x, dgh(x, alpha = 1, beta = 0.3, delta = 1))
 
    ## pgh -  
       # Plot df and compare with true df:
       plot(sort(r), (1:5000/5000), main = "Probability", col = "steelblue")
       lines(x, pgh(x, alpha = 1, beta = 0.3, delta = 1))
   
    ## qgh -
       # Compute Quantiles:
       qgh(pgh(seq(-5, 5, 1), alpha = 1, beta = 0.3, delta = 1), 
         alpha = 1, beta = 0.3, delta = 1)
}

test_26 <- function() {
    set.seed(1953)
    s <- rgh(n = 1000, alpha = 1.5, beta = 0.3, delta = 0.5, mu = -1.0) 

    ghFit(s, alpha = 1, beta = 0, delta = 1, mu = mean(s), doplot = TRUE, trace = FALSE)
}

test_27 <- function() {
   
    ## ghMode -
       ghMode()
}

test_28 <- function() {
   
    ## ghMean -
       ghMean(alpha=1.1, beta=0.1, delta=0.8, mu=-0.3, lambda=1)
   
    ## ghKurt -
       ghKurt(alpha=1.1, beta=0.1, delta=0.8, mu=-0.3, lambda=1)
   
    ## ghMoments -
       ghMoments(4, 
         alpha=1.1, beta=0.1, delta=0.8, mu=-0.3, lambda=1)
       ghMoments(4, "central",
         alpha=1.1, beta=0.1, delta=0.8, mu=-0.3, lambda=1)
}

test_29 <- function() {
    ## ghMED -
       # Median:
       ghMED(alpha = 1, beta = 0, delta = 1, mu = 0, lambda = -1/2)

    ## ghIQR -
       # Inter-quartile Range:
       ghIQR(alpha = 1, beta = 0, delta = 1, mu = 0, lambda = -1/2)

    ## ghSKEW -
       # Robust Skewness:
       ghSKEW(alpha = 1, beta = 0, delta = 1, mu = 0, lambda = -1/2)

    ## ghKURT -
       # Robust Kurtosis:
       ghKURT(alpha = 1, beta = 0, delta = 1, mu = 0, lambda = -1/2)
}

test_30 <- function() {
   
    ## ghSlider -
       # ghSlider()
}

test_31 <- function() {
   
    ## ght -
       #
}

test_32 <- function() {
    ## ghtFit -
       # Simulate Random Variates:
       set.seed(1953)
   
    ## ghtFit -  
       # Fit Parameters:
}

test_33 <- function() {
   
    ## ghtMode -
       ghtMode()
}

test_34 <- function() {
   
    ## ghtMean -
       ghtMean(beta=0.2, delta=1.2, mu=-0.5, nu=4)
   
    ## ghtKurt -
       ghtKurt(beta=0.2, delta=1.2, mu=-0.5, nu=4)
   
    ## ghtMoments -
       ghtMoments(4, 
         beta=0.2, delta=1.2, mu=-0.5, nu=4)
       ghtMoments(4, "central",
         beta=0.2, delta=1.2, mu=-0.5, nu=4)
}

test_35 <- function() {
    ## ghtMED -
       # Median:
       ghtMED(beta = 0.1, delta = 1, mu = 0, nu = 10)

    ## ghtIQR -
       # Inter-quartile Range:
       ghtIQR(beta = 0.1, delta = 1, mu = 0, nu = 10)

    ## ghtSKEW -
       # Robust Skewness:
       ghtSKEW(beta = 0.1, delta = 1, mu = 0, nu = 10)

    ## ghtKURT -
       # Robust Kurtosis:
       ghtKURT(beta = 0.1, delta = 1, mu = 0, nu = 10)
}

test_36 <- function() {
   
    ## rgld -
       set.seed(1953)
       r = rgld(500, 
         lambda1=0, lambda2=-1, lambda3=-1/8, lambda4=-1/8)
       plot(r, type = "l", col = "steelblue",
         main = "gld: lambda1=0 lambda2=-1 lambda3/4=-1/8")
 
    ## dgld - 
       # Plot empirical density and compare with true density:
       hist(r, n = 25, probability = TRUE, border = "white", 
         col = "steelblue")
       x = seq(-5, 5, 0.25)
       lines(x, dgld(x, 
         lambda1=0, lambda2=-1, lambda3=-1/8, lambda4=-1/8))
 
    ## pgld -  
       # Plot df and compare with true df:
       plot(sort(r), ((1:500)-0.5)/500, main = "Probability", 
         col = "steelblue")
       lines(x, pgld(x, 
         lambda1=0, lambda2=-1, lambda3=-1/8, lambda4=-1/8))
   
    ## qgld -
       # Compute Quantiles:
       qgld(pgld(seq(-5, 5, 1), 
         lambda1=0, lambda2=-1, lambda3=-1/8, lambda4=-1/8), 
         lambda1=0, lambda2=-1, lambda3=-1/8, lambda4=-1/8)
}

test_37 <- function() {
    set.seed(1953)
    s <- rgld(n = 1000, lambda1=0, lambda2=-1, lambda3=-1/8, lambda4=-1/8) 

    gldFit(s, lambda1=0, lambda2=-1, lambda3=-1/8, lambda4=-1/8, 
           doplot = TRUE, trace = FALSE)
}

test_38 <- function() {
   
    ## gldMED -
       # Median:
       gldMED(lambda1 = 0, lambda2 = -1, lambda3 = -1/8, lambda4 = -1/8)
 
    ## gldIQR - 
       # Inter-quartile Range:
       gldIQR(lambda1 = 0, lambda2 = -1, lambda3 = -1/8, lambda4 = -1/8)
 
    ## gldSKEW -  
       # Robust Skewness:
       gldSKEW(lambda1 = 0, lambda2 = -1, lambda3 = -1/8, lambda4 = -1/8)
   
    ## gldKURT -
       # Robust Kurtosis:
       gldKURT(lambda1 = 0, lambda2 = -1, lambda3 = -1/8, lambda4 = -1/8)
}

test_39 <- function() {
    ## a small grid vector with row and col transformations
    gridVector(0:2)
    data.frame(gridVector(0:2))
    do.call("rbind", gridVector(0:2))

    gridVector(0:2, 0:3)

    ## grid over a unit square
    gridVector((0:10)/10) # equivalently: gridVector((0:10)/10, (0:10)/10)
}

test_40 <- function() {
    ## Create a Hilbert Matrix:
    H = hilbert(5)
    H
}

test_41 <- function() {
   
    ## hyp -
       set.seed(1953)
       r = rhyp(5000, alpha = 1, beta = 0.3, delta = 1)
       plot(r, type = "l", col = "steelblue",
         main = "hyp: alpha=1 beta=0.3 delta=1")
 
    ## hyp - 
       # Plot empirical density and compare with true density:
       hist(r, n = 25, probability = TRUE, border = "white", col = "steelblue")
       x = seq(-5, 5, 0.25)
       lines(x, dhyp(x, alpha = 1, beta = 0.3, delta = 1))
 
    ## hyp -  
       # Plot df and compare with true df:
       plot(sort(r), (1:5000/5000), main = "Probability", col = "steelblue")
       lines(x, phyp(x, alpha = 1, beta = 0.3, delta = 1))
   
    ## hyp -
       # Compute Quantiles:
       qhyp(phyp(seq(-5, 5, 1), alpha = 1, beta = 0.3, delta = 1), 
         alpha = 1, beta = 0.3, delta = 1)
}

test_42 <- function() {
    set.seed(1953)
    s <- rhyp(n = 1000, alpha = 1.5, beta = 0.3, delta = 0.5, mu = -1.0) 

    hypFit(s, alpha = 1, beta = 0, delta = 1, mu = mean(s), doplot = TRUE,
           trace = FALSE)
}

test_43 <- function() {
   
    ## hypMode -
       hypMode()
}

test_44 <- function() {
   
    ## hypMean -
       hypMean(alpha=1.1, beta=0.1, delta=0.8, mu=-0.3)
   
    ## ghKurt -
       hypKurt(alpha=1.1, beta=0.1, delta=0.8, mu=-0.3)
   
    ## hypMoments -
       hypMoments(4, alpha=1.1, beta=0.1, delta=0.8, mu=-0.3)
       hypMoments(4, "central", alpha=1.1, beta=0.1, delta=0.8, mu=-0.3)
}

test_45 <- function() {
    ## hypMED -
       # Median:
       hypMED(alpha = 1, beta = 0, delta = 1, mu = 0)

    ## hypIQR -
       # Inter-quartile Range:
       hypIQR(alpha = 1, beta = 0, delta = 1, mu = 0)

    ## hypSKEW -
       # Robust Skewness:
       hypSKEW(alpha = 1, beta = 0, delta = 1, mu = 0)

    ## hypKURT -
       # Robust Kurtosis:
       hypKURT(alpha = 1, beta = 0, delta = 1, mu = 0)
}

test_46 <- function() {
   
    ## hypSlider -
       #
}

test_47 <- function() {
    ## Test Plot Function
    testPlot <- function(x, which = "all", ...) {   
        ## Plot Function and Addons
        plot.1 <<- function(x, ...) plot(x, ...)      
        plot.2 <<- function(x, ...) acf(x, ...)
        plot.3 <<- function(x, ...) hist(x, ...)      
        plot.4 <<- function(x, ...) qqnorm(x, ...)
        ## Plot
        interactivePlot(
            x,
            choices = c("Series Plot", "ACF", "Histogram", "QQ Plot"),
            plotFUN = c("plot.1", "plot.2", "plot.3", "plot.4"),
            which = which, ...)       
        ## Return Value
        invisible()
    }

    ## Plot
    ## prepare the window and store its previous state
    op <- par(mfrow = c(2, 2), cex = 0.7)
    ## produce the plot
    testPlot(rnorm(500))            
    ## restore the previous state
    par(op)

    ## Try:
    ## par(mfrow = c(1,1))
    ## testPlot(rnorm(500), which = "ask")

    ## similar to above but using functions for plotFUN
    testPlot_2 <- function(x, which = "all", ...) {   
        interactivePlot(
            x,
            choices = c("Series Plot", "ACF", "Histogram", "QQ Plot"),
            plotFUN = c(plot.1 = function(x, ...) plot(x, ...),
                        plot.2 = function(x, ...) acf(x, ...),
                        plot.3 = function(x, ...) hist(x, ...),
                        plot.4 = function(x, ...) qqnorm(x, ...) ),
            which = which, ...)       
   
        ## Return Value:
        invisible()
    }
    ## produce the plot
    op <- par(mfrow = c(2, 2), cex = 0.7)
    testPlot_2(rnorm(500))            
    par(op)
}

test_48 <- function() {
    ## Create Pascal Matrix:
    P = pascal(5)
    P
         
    ## Compute the Inverse Matrix:
    inv(P)
   
    ## Check:
    inv(P) %*% P    
   
    ## Alternatives:
    chol2inv(chol(P))
    solve(P)
}

test_49 <- function() {

    ## The akima library is not auto-installed because of a different licence.
    ## krigeInterp -  Kriging:
    set.seed(1953)
    x = runif(999) - 0.5
    y = runif(999) - 0.5
    z = cos(2*pi*(x^2+y^2))
    ans = krigeInterp(x, y, z, extrap = FALSE)
    persp(ans, theta = -40, phi = 30, col = "steelblue",
        xlab = "x", ylab = "y", zlab = "z")
    contour(ans)
}

test_50 <- function() {
    ## Create Pascal Matrix:
    P = pascal(3)
    P
   
    ## Return the Kronecker Product                     
    kron(P, diag(3))
    P %x% diag(3)
}

test_51 <- function() {

    x <- rnorm(50)
    y <- rnorm(50)
  
    ks2Test(x, y)
}

test_52 <- function() {
    set.lcgseed(seed = 65890)
 
    ## runif.lcg, rnorm.lcg, rt.lcg
    cbind(runif.lcg(10), rnorm.lcg(10), rt.lcg(10, df = 4))

    get.lcgseed()  
   
    ## Note, to overwrite rnorm, use
       # rnorm = rnorm.lcg
       # Going back to rnorm
       # rm(rnorm)
}

test_53 <- function() {
    ## Linear Interpolation:    
    if (requireNamespace("interp")) {
        set.seed(1953)
        x <- runif(999) - 0.5
        y <- runif(999) - 0.5
        z <- cos(2 * pi * (x^2 + y^2))
        ans = linearInterp(x, y, z, gridPoints = 41)
        persp(ans, theta = -40, phi = 30, col = "steelblue",
              xlab = "x", ylab = "y", zlab = "z")
        contour(ans)
    }
}

test_54 <- function() {
    listFunctions("fBasics")
   
    countFunctions("fBasics")
}

test_55 <- function() {

    x <- rnorm(50)
    y <- rnorm(50)
  
    locationTest(x, y, "t")
    locationTest(x, y, "kw2")
}

test_56 <- function() {
    ## rmaxdd
    ## Set a random seed
    set.seed(1953)               
    ## horizon of the investor, time T
    horizon <- 1000               
    ## number of MC samples, N -> infinity
    samples <- 1000               
    ## Range of expected Drawdons
    xlim <- c(0, 5) * sqrt(horizon) 

    ## Plot Histogram of Simulated Max Drawdowns:
    r <- rmaxdd(n = samples, mean = 0, sd = 1, horizon = horizon)
    hist(x = r, n = 40, probability = TRUE, xlim = xlim, 
         col = "steelblue4", border = "white", main = "Max. Drawdown Density") 
    points(r, rep(0, samples), pch = 20, col = "orange", cex = 0.7)
   
    ## dmaxdd
    x <- seq(0, xlim[2], length = 200)
    d <- dmaxdd(x = x, sd = 1, horizon = horizon, N = 1000)
    lines(x, d, lwd = 2)
    
    ## pmaxdd
    ## Count Frequencies of Drawdowns Greater or Equal to "h":
    n <- 50
    x <- seq(0, xlim[2], length = n)
    g <- rep(0, times = n)
    for (i in 1:n)
        g[i] <- length (r[r > x[i]]) / samples

    plot(x, g, type ="h", lwd = 3,
         xlab = "q", main = "Max. Drawdown Probability")
    ## Compare with True Probability "G_D(h)":
    x <- seq(0, xlim[2], length = 5*n)
    p <- pmaxdd(q = x, sd = 1, horizon = horizon, N = 5000)
    lines(x, p, lwd = 2, col="steelblue4") 
   
    ## maxddStats
    ## Compute expectation Value E[D]:
    maxddStats(mean = -0.5, sd = 1, horizon = 10^(1:4))
    maxddStats(mean =  0.0, sd = 1, horizon = 10^(1:4))
    maxddStats(mean =  0.5, sd = 1, horizon = 10^(1:4))
}

test_57 <- function() {
   
    ## nig -
       set.seed(1953)
       r = rnig(5000, alpha = 1, beta = 0.3, delta = 1)
       plot(r, type = "l", col = "steelblue",
         main = "nig: alpha=1 beta=0.3 delta=1")
 
    ## nig - 
       # Plot empirical density and compare with true density:
       hist(r, n = 25, probability = TRUE, border = "white", col = "steelblue")
       x = seq(-5, 5, 0.25)
       lines(x, dnig(x, alpha = 1, beta = 0.3, delta = 1))
 
    ## nig -  
       # Plot df and compare with true df:
       plot(sort(r), (1:5000/5000), main = "Probability", col = "steelblue")
       lines(x, pnig(x, alpha = 1, beta = 0.3, delta = 1))
   
    ## nig -
       # Compute Quantiles:
       qnig(pnig(seq(-5, 5, 1), alpha = 1, beta = 0.3, delta = 1), 
         alpha = 1, beta = 0.3, delta = 1)
}

test_58 <- function() {
    ## Simulate Random Variates
    set.seed(1953)
    s <- rnig(n = 1000, alpha = 1.5, beta = 0.3, delta = 0.5, mu = -1.0) 

    nigFit(s, alpha = 1, beta = 0, delta = 1, mu = mean(s), doplot = TRUE,
           trace = FALSE)
}

test_59 <- function() {
   
    ## nigMode -
       nigMode()
}

test_60 <- function() {
   
    ## nigMean -
       # Median:
       nigMean(alpha = 1, beta = 0, delta = 1, mu = 0)
 
    ## nigVar - 
       # Inter-quartile Range:
       nigVar(alpha = 1, beta = 0, delta = 1, mu = 0)
 
    ## nigSKEW -  
       # Robust Skewness:
       nigSkew(alpha = 1, beta = 0, delta = 1, mu = 0)
   
    ## nigKurt -
       # Robust Kurtosis:
       nigKurt(alpha = 1, beta = 0, delta = 1, mu = 0)
}

test_61 <- function() {
    ## nigMED -
       # Median:
       nigMED(alpha = 1, beta = 0, delta = 1, mu = 0)

    ## nigIQR -
       # Inter-quartile Range:
       nigIQR(alpha = 1, beta = 0, delta = 1, mu = 0)

    ## nigSKEW -
       # Robust Skewness:
       nigSKEW(alpha = 1, beta = 0, delta = 1, mu = 0)

    ## nigKURT -
       # Robust Kurtosis:
       nigKURT(alpha = 1, beta = 0, delta = 1, mu = 0)
}

test_62 <- function() {
   
    ## nigShapeTriangle -
       #
}

test_63 <- function() {
   
    ## nigSlider -
       # nigSlider()
}

test_64 <- function() {
    ## Create Pascal Matrix:
    P <- pascal(5)
    P                  
     
    ## Return the Norm of the Matrix:                      
    norm2(P)
}

test_65 <- function() {
    ## normMED -
       # Median:
       normMED(mean = 0, sd = 1)

    ## normIQR -
       # Inter-quartile Range:
       normIQR(mean = 0, sd = 1)

    ## normSKEW -
       # Robust Skewness:
       normSKEW(mean = 0, sd = 1)

    ## normKURT -
       # Robust Kurtosis:
       normKURT(mean = 0, sd = 1)
}

test_66 <- function() {
    ## Create Pascal Matrix:
    P = pascal(5)
    P 
   
    ## Determinant
    det(pascal(5)) 
    det(pascal(10))   
    det(pascal(15))   
    det(pascal(20))
}

test_67 <- function() {
    ## pdl -
       #
}

test_68 <- function() {
    # the 3x3 Pascal Matrix is positive define 
    isPositiveDefinite(pascal(3))
}

test_69 <- function() {
    control <- list(n = 211, seed = 54, name = "generator")
    print(control) 
    class(control) <- "control"
    print(control)
}

test_70 <- function() {
    ## Create Pascal Matrix:
    P = pascal(5)
    P
   
    ## Compute the Rank:
    rk(P)
    rk(P, "chol")
}

test_71 <- function() {
    ## Simulated Return Data in Matrix Form:
    x <- matrix(rnorm(10*10), nrow = 10)
     
    rowStats(x, FUN = mean)
    rowMaxs(x)
}

test_72 <- function() {
    x <- rt(100, 4)
   
    sampleLmoments(x)
}

test_73 <- function() {
    ## Sample
    x <- rt(100, 4)
   
    ## Median
    sampleMED(x)
 
    ## Inter-quartile Range
    sampleIQR(x)
 
    ## Robust Skewness
    sampleSKEW(x)
   
    ## Robust Kurtosis
    sampleKURT(x)
}

test_74 <- function() {

    ## Generate Series:
    x = rnorm(50)
    y = rnorm(50)
   
    scaleTest(x, y, "ansari")
    scaleTest(x, y, "mood")
}

test_75 <- function() {
   
    ## rsgh -
       set.seed(1953)
       r = rsgh(5000, zeta = 1, rho = 0.5, lambda = 1)
       plot(r, type = "l", col = "steelblue",
         main = "gh: zeta=1 rho=0.5 lambda=1")
 
    ## dsgh - 
       # Plot empirical density and compare with true density:
       hist(r, n = 50, probability = TRUE, border = "white", col = "steelblue",
         ylim = c(0, 0.6))
       x = seq(-5, 5, length = 501)
       lines(x, dsgh(x, zeta = 1, rho = 0.5, lambda = 1))
 
    ## psgh -  
       # Plot df and compare with true df:
       plot(sort(r), (1:5000/5000), main = "Probability", col = "steelblue")
       lines(x, psgh(x, zeta = 1, rho = 0.5, lambda = 1))
   
    ## qsgh -
       # Compute Quantiles:
       round(qsgh(psgh(seq(-5, 5, 1), zeta = 1, rho = 0.5), zeta = 1, rho = 0.5), 4)
}

test_76 <- function() {
    set.seed(1953)
    s <- rsgh(n = 2000, zeta = 0.7, rho = 0.5, lambda = 0) 

    sghFit(s, zeta = 1, rho = 0, lambda = 1, include.lambda = TRUE, 
           doplot = TRUE, trace = FALSE)
}

test_77 <- function() {
    ## rsght -
       set.seed(1953)
       r = rsght(5000, beta = 0.1, delta = 1, mu = 0, nu = 10)
       plot(r, type = "l", col = "steelblue",
         main = "gh: zeta=1 rho=0.5 lambda=1")

    ## dsght -
       # Plot empirical density and compare with true density:
       hist(r, n = 50, probability = TRUE, border = "white", col = "steelblue")
       x = seq(-5, 5, length = 501)
       lines(x, dsght(x, beta = 0.1, delta = 1, mu = 0, nu = 10))

    ## psght -
       # Plot df and compare with true df:
       plot(sort(r), (1:5000/5000), main = "Probability", col = "steelblue")
       lines(x, psght(x, beta = 0.1, delta = 1, mu = 0, nu = 10))

    ## qsght -
       # Compute Quantiles:
       round(qsght(psght(seq(-5, 5, 1), beta = 0.1, delta = 1, mu = 0, nu =10),
                   beta = 0.1, delta = 1, mu = 0, nu = 10), 4)
}

test_78 <- function() {
   
    ## snig -
       set.seed(1953)
       r = rsnig(5000, zeta = 1, rho = 0.5)
       plot(r, type = "l", col = "steelblue",
         main = "snig: zeta=1 rho=0.5")
 
    ## snig - 
       # Plot empirical density and compare with true density:
       hist(r, n = 50, probability = TRUE, border = "white", col = "steelblue")
       x = seq(-5, 5, length = 501)
       lines(x, dsnig(x, zeta = 1, rho = 0.5))
 
    ## snig -  
       # Plot df and compare with true df:
       plot(sort(r), (1:5000/5000), main = "Probability", col = "steelblue")
       lines(x, psnig(x, zeta = 1, rho = 0.5))
   
    ## snig -
       # Compute Quantiles:
       qsnig(psnig(seq(-5, 5, 1), zeta = 1, rho = 0.5), zeta = 1, rho = 0.5)
}

test_79 <- function() {
    ## Simulate Random Variates:
    set.seed(1953)
    s <- rsnig(n = 2000, zeta = 0.7, rho = 0.5) 

    ## snigFit -  
       # Fit Parameters:
       snigFit(s, zeta = 1, rho = 0, doplot = TRUE)
}

test_80 <- function() {
   
    ## ssdFit -
       set.seed(1953)
       r = rnorm(500)
       hist(r, breaks = "FD", probability = TRUE,
         col = "steelblue", border = "white")
 
    ## ssdFit - 
       param = ssdFit(r)
   
    ## dssd -  
       u = seq(min(r), max(r), len = 301)
       v = dssd(u, param)
       lines(u, v, col = "orange", lwd = 2)
}

test_81 <- function() {
     
    ## ssdFit -
       set.seed(1953)
       r = rnorm(500)
       hist(r, breaks = "FD", probability = TRUE,
         col = "steelblue", border = "white")
 
    ## ssdFit - 
       param = ssdFit(r)
   
    ## dssd -  
       u = seq(min(r), max(r), len = 301)
       v = dssd(u, param)
       lines(u, v, col = "orange", lwd = 2)
}

test_82 <- function() {
  
    # symbolTable()
}

test_83 <- function() {
    ## Create Pascal Matrix:
    P = pascal(3)
    P
  
    tr(P)
}

test_84 <- function() {
    ## Create Pascal Matrix:
    P = pascal(3)
    P
   
    ## Create lower triangle matrix
    L = triang(P)
    L
}

test_85 <- function() {
    ## tslag -
}

test_86 <- function() {

    x <- rnorm(50)
    y <- rnorm(50)
   
    varianceTest(x, y, "varf")
    varianceTest(x, y, "bartlett")
    varianceTest(x, y, "fligner")
}

test_87 <- function() {
    ## Create Pascal Matrix:
    P = pascal(3)
   
    ## Stack the matrix
    vec(P) 
   
    ## Stack the lower triangle
    vech(P)
}

print("Running test_1")
test_1()

print("Running test_2")
test_2()

print("Running test_3")
test_3()

print("Running test_4")
test_4()

print("Running test_5")
test_5()

print("Running test_6")
test_6()

print("Running test_7")
test_7()

print("Running test_8")
test_8()

print("Running test_9")
test_9()

print("Running test_10")
test_10()

print("Running test_11")
test_11()

print("Running test_12")
test_12()

print("Running test_13")
test_13()

print("Running test_14")
test_14()

print("Running test_15")
test_15()

print("Running test_16")
test_16()

print("Running test_17")
test_17()

print("Running test_18")
test_18()

print("Running test_19")
test_19()

print("Running test_20")
test_20()

print("Running test_21")
test_21()

print("Running test_22")
test_22()

print("Running test_23")
test_23()

print("Running test_24")
test_24()

print("Running test_25")
test_25()

print("Running test_26")
test_26()

print("Running test_27")
test_27()

print("Running test_28")
test_28()

print("Running test_29")
test_29()

print("Running test_30")
test_30()

print("Running test_31")
test_31()

print("Running test_32")
test_32()

print("Running test_33")
test_33()

print("Running test_34")
test_34()

print("Running test_35")
test_35()

print("Running test_36")
test_36()

print("Running test_37")
test_37()

print("Running test_38")
test_38()

print("Running test_39")
test_39()

print("Running test_40")
test_40()

print("Running test_41")
test_41()

print("Running test_42")
test_42()

print("Running test_43")
test_43()

print("Running test_44")
test_44()

print("Running test_45")
test_45()

print("Running test_46")
test_46()

print("Running test_47")
test_47()

print("Running test_48")
test_48()

print("Running test_49")
test_49()

print("Running test_50")
test_50()

print("Running test_51")
test_51()

print("Running test_52")
test_52()

print("Running test_53")
test_53()

print("Running test_54")
test_54()

print("Running test_55")
test_55()

print("Running test_56")
test_56()

print("Running test_57")
test_57()

print("Running test_58")
test_58()

print("Running test_59")
test_59()

print("Running test_60")
test_60()

print("Running test_61")
test_61()

print("Running test_62")
test_62()

print("Running test_63")
test_63()

print("Running test_64")
test_64()

print("Running test_65")
test_65()

print("Running test_66")
test_66()

print("Running test_67")
test_67()

print("Running test_68")
test_68()

print("Running test_69")
test_69()

print("Running test_70")
test_70()

print("Running test_71")
test_71()

print("Running test_72")
test_72()

print("Running test_73")
test_73()

print("Running test_74")
test_74()

print("Running test_75")
test_75()

print("Running test_76")
test_76()

print("Running test_77")
test_77()

print("Running test_78")
test_78()

print("Running test_79")
test_79()

print("Running test_80")
test_80()

print("Running test_81")
test_81()

print("Running test_82")
test_82()

print("Running test_83")
test_83()

print("Running test_84")
test_84()

print("Running test_85")
test_85()

print("Running test_86")
test_86()

print("Running test_87")
test_87()

