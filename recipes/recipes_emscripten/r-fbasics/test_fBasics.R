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
