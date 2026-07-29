library(ks)
test_1 <- function() {
    data(unicef)
    Hbcv(unicef)
    Hbcv.diag(unicef)
}

test_2 <- function() {
    data(forbes, package="MASS")
    Hlscv(forbes)
    hlscv(forbes$bp)
}

test_3 <- function() {
    data(unicef)
    Hnm(unicef)
}

test_4 <- function() {
    data(forbes, package="MASS")
    Hns(forbes, deriv.order=2)
    hns(forbes$bp, deriv.order=2)
}

test_5 <- function() {
    data(unicef)
    Hpi(unicef, pilot="dscalar")
    hpi(unicef[,1])
}

test_6 <- function() {
    data(unicef)
    Hscv(unicef)
    hscv(unicef[,1])
}

test_7 <- function() {
    ## univariate 
    ep1 <- seq(0,1, length=401)
    est1 <- dbeta(ep1, shape1=2, shape2=5)
    f1 <- data.frame(ep1, estimate=est1)
    f1.kde <- as.kde(f1)
    plot(f1.kde)

    ## bivariate
    ep2 <- expand.grid(x=seq(-pi,pi, length=151), y=seq(-pi,pi, length=151))
    est2 <- cos(ep2[,1]*pi/2) + sin(ep2[,2]*pi/2)  
    f2 <- data.frame(ep2, estimate=est2)
    f2.kde <- as.kde(f2, density=FALSE)
    plot(f2.kde, display="filled.contour")
    plot(f2.kde, display="persp", phi=10)

    ## trivariate
    mus3 <- c(0,0,0)
    Sigmas3 <- 1/2*diag(c(1,1/3,2))
    props3 <- 1
    ep3 <- expand.grid(x=seq(-3,3, length=51), y=seq(-3,3, length=51), z=seq(-3,3, length=51))
    est3 <- dmvnorm.mixt(ep3, mus=mus3, Sigmas=Sigmas3, props=props3)
    f3 <- data.frame(ep3, estimate=est3)
    f3.kde <- as.kde(f3)
    plot(f3.kde)
}

test_8 <- function() {
    data(unicef)
    ubinned <- binning(x=unicef)
}

test_9 <- function() {
    set.seed(8192)
    x <- rmvnorm.mixt(n=1000, mus=c(0,0), Sigmas=diag(2), props=1)
    fhat <- kde(x=x, binned=TRUE)
    contourLevels(fhat, cont=c(25,50,75))
    contourProbs(fhat, abs.cont=contourLevels(fhat, cont=50))
    ## compare approx prob with target prob=0.5
    contourSizes(fhat, cont=25, approx=TRUE) 
    ## compare to approx circle of radius=0.75 with area=1.77
    contourBreaks(fhat, n=3, type="natural")
    ## natural or Jenks contour levels
}

test_10 <- function() {
    ## positive data example
    set.seed(8192)
    x <- 2^rnorm(100)
    fhat <- histde(x=x)
    plot(fhat, border=6)
    points(c(0.5, 1), predict(fhat, x=c(0.5, 1)))

    ## large data example on a non-default grid
    set.seed(8192)
    x <- rmvnorm.mixt(10000, mus=c(0,0), Sigmas=invvech(c(1,0.8,1)))
    fhat <- histde(x=x, xmin=c(-5,-5), xmax=c(5,5))
    plot(fhat)

    ## See other examples in ? plot.histde
}

test_11 <- function() {
    x <- rmvnorm.mixt(100)
    Hamise.mixt(samp=nrow(x), mus=rep(0,2), Sigmas=var(x), props=1, deriv.order=1)
}

test_12 <- function() {
    data(iris)
    Fhat <- kcde(iris[,1:2])  
    predict(Fhat, x=as.matrix(iris[,1:2]))

    ## See other examples in ? plot.kcde
}

test_13 <- function() {
    data(fgl, package="MASS")
    x <- fgl[,c("RI", "Na")]
    Chat <- kcopula(x=x)
    plot(Chat, display="filled.contour", lwd=1)
    plot(Chat, display="persp", border=1)
}

test_14 <- function() {
    set.seed(8192)
    x <- c(rnorm.mixt(n=100, mus=1), rnorm.mixt(n=100, mus=-1))
    x.gr <- rep(c(1,2), times=c(100,100))
    y <- c(rnorm.mixt(n=100, mus=1), rnorm.mixt(n=100, mus=-1))
    y.gr <- rep(c(1,2), times=c(100,100))
    kda.gr <- kda(x, x.gr)
    y.gr.est <- predict(kda.gr, x=y)
    compare(y.gr, y.gr.est)

    ## See other examples in ? plot.kda
}

test_15 <- function() {

    data(air)
    air <- air[, c("date", "time", "co2", "pm10")]
    air2 <- reshape(air, idvar="date", timevar="time", direction="wide")
    air <- as.matrix(na.omit(air2[,c("co2.20:00", "pm10.20:00")]))
    Sigma.air <- diag(c(var(air2[,"co2.19:00"] - air2["co2.21:00"], na.rm=TRUE),
       var(air2[,"pm10.19:00"] - air2[,"pm10.21:00"], na.rm=TRUE)))
    fhat.air.dec <- kdcde(x=air, Sigma=Sigma.air, reg=0.00021, verbose=TRUE)
    plot(fhat.air.dec, drawlabels=FALSE, display="filled.contour", lwd=1)
}

test_16 <- function() {
    set.seed(8192)
    x <- rmvnorm.mixt(1000, mus=c(0,0), Sigmas=invvech(c(1,0.8,1)))
    fhat <- kdde(x=x, deriv.order=1) ## gradient [df/dx, df/dy]
    predict(fhat, x=x[1:5,])

    ## See other examples in ? plot.kdde
}

test_17 <- function() {
    ## unit interval data 
    set.seed(8192)             
    fhat <- kde(runif(10000,0,1), unit.interval=TRUE)
    plot(fhat, ylim=c(0,1.2))

    ## positive data 
    data(worldbank)
    wb <- as.matrix(na.omit(worldbank[,2:3]))
    wb[,2] <- wb[,2]/1000
    fhat <- kde(x=wb)
    fhat.trans <- kde(x=wb, adj.positive=c(0,0), positive=TRUE)
    plot(fhat, col=1, xlim=c(0,20), ylim=c(0,80))
    plot(fhat.trans, add=TRUE, col=2)
    rect(0,0,100,100, lty=2)

    ## large data on non-default grid
    ## 151 x 151 grid = [-5,-4.933,..,5] x [-5,-4.933,..,5]
    set.seed(8192)
    x <- rmvnorm.mixt(10000, mus=c(0,0), Sigmas=invvech(c(1,0.8,1)))
    fhat <- kde(x=x, compute.cont=TRUE, xmin=c(-5,-5), xmax=c(5,5), bgridsize=c(151,151))
    plot(fhat)

    ## See other examples in ? plot.kde
}

test_18 <- function() {
    data(worldbank)
    wb <- as.matrix(na.omit(worldbank[,c("internet", "ag.value")]))
    fhat <- kde(x=wb)
    fhat.beta <- kde.boundary(x=wb, xmin=c(0,0), xmax=c(100,100), boundary.kernel="beta")  
    plot(fhat, col=1, xlim=c(0,100), ylim=c(0,100))
    plot(fhat.beta, add=TRUE, col=2)
    rect(0,0,100,100, lty=2)

    fhat.LB <- kde.boundary(x=wb, xmin=c(0,0), xmax=c(100,100), boundary.kernel="linear")
    plot(fhat, col=1, xlim=c(0,100), ylim=c(0,100))
    plot(fhat.LB, add=TRUE, col=3)
    rect(0,0,100,100, lty=2)
}

test_19 <- function() {
    data(crabs, package="MASS")
    x1 <- crabs[crabs$sp=="B", 4]
    x2 <- crabs[crabs$sp=="O", 4]
    loct <- kde.local.test(x1=x1, x2=x2)
    plot(loct)

    ## see examples in ? plot.kde.loctest
}

test_20 <- function() {
    set.seed(8192)
    samp <- 1000
    x <- rnorm.mixt(n=samp, mus=0, sigmas=1, props=1)
    y <- rnorm.mixt(n=samp, mus=0, sigmas=1, props=1)
    kde.test(x1=x, x2=y)$pvalue   ## accept H0: f1=f2

    data(crabs, package="MASS")
    x1 <- crabs[crabs$sp=="B", c(4,6)]
    x2 <- crabs[crabs$sp=="O", c(4,6)]
    kde.test(x1=x1, x2=x2)$pvalue  ## reject H0: f1=f2
}

test_21 <- function() {
    data(worldbank)
    wb <- as.matrix(na.omit(worldbank[,c("internet", "ag.value")]))
    fhat <- kde(x=wb)
    rectb <- cbind(x=c(0,100,100,0,0), y=c(0,0,100,100,0))
    fhat.b <- kde.truncate(fhat, boundary=rectb)
    plot(fhat, col=1, xlim=c(0,100), ylim=c(0,100))
    plot(fhat.b, add=TRUE, col=4)
    rect(0,0,100,100, lty=2)

    library(oz)
    data(grevillea)
    wa.coast <- ozRegion(section=1)
    wa.polygon <- cbind(wa.coast$lines[[1]]$x, wa.coast$lines[[1]]$y)
    fhat1 <- kdde(x=grevillea, deriv.order=1)
    fhat1 <- kdde.truncate(fhat1, wa.polygon)
    oz(section=1, xlim=c(113,122), ylim=c(-36,-29))
    plot(fhat1, add=TRUE, display="filled.contour")
}

test_22 <- function() {
    data(geyser, package="MASS")
    geyser.fs <- kfs(geyser$duration, binned=TRUE)
    plot(geyser.fs, xlab="duration")

    ## see example in ? plot.kfs
}

test_23 <- function() {
    data(crabs, package="MASS")
    kms.crabs <- kms(x=crabs[,c("FL","CW")])
    plot(kms.crabs, pch=16)
    summary(kms.crabs)

    kms.crabs <- kms(x=crabs[,c("FL","CW","RW")])
    plot(kms.crabs, pch=16)
    plot(kms.crabs, display="plot3D", pch=16)
}

test_24 <- function() {
    samp <- 1000
    x <- rnorm.mixt(n=samp, mus=0, sigmas=1, props=1)
    y <- rnorm.mixt(n=samp, mus=0.5, sigmas=1, props=1)
    Rhat <- kroc(x1=x, x2=y)
    summary(Rhat)
    predict(Rhat, x=0.5)
}

test_25 <- function() {
    data(grevillea)
    fhat <- kde(x=grevillea)
    fhat.supp <- ksupp(fhat)
    plot(fhat, display="filled.contour", cont=seq(10,90,by=10))
    plot(fhat, cont=95, add=TRUE, col=1)
    plot(fhat.supp, lty=2)

    data(iris)
    fhat <- kde(x=iris[,1:3])
    fhat.supp <- ksupp(fhat)
    plot(fhat)
    plot(fhat.supp, add=TRUE, col=3, alpha=0.1)
}

test_26 <- function() {
    ## univariate normal mixture
    x <- rnorm.mixt(1000, mus=c(-1,1), sigmas=c(0.5, 0.5), props=c(1/2, 1/2))

    ## bivariate mixtures 
    mus <- rbind(c(-1,0), c(1, 2/sqrt(3)), c(1,-2/sqrt(3)))
    Sigmas <- 1/25*rbind(invvech(c(9, 63/10, 49/4)), invvech(c(9,0,49/4)), invvech(c(9,0,49/4)))
    props <- c(3,3,1)/7
    dfs <- c(7,3,2)
    x <- rmvnorm.mixt(1000, mus=mus, Sigmas=Sigmas, props=props)
    y <- rmvt.mixt(1000, mus=mus, Sigmas=Sigmas, dfs=dfs, props=props)

    mvnorm.mixt.mode(mus=mus, Sigmas=Sigmas, props=props)
}

test_27 <- function() {
    ## univariate example
    data(iris)
    fhat <- histde(x=iris[,2])
    plot(fhat, xlab="Sepal length")

    ## bivariate example
    fhat <- histde(x=iris[,2:3])
    plot(fhat, drawpoints=TRUE)
    box()
}

test_28 <- function() {
    data(iris)
    Fhat <- kcde(x=iris[,1])
    plot(Fhat, xlab="Sepal.Length")
    Fhat <- kcde(x=iris[,1:2])
    plot(Fhat)
    Fhat <- kcde(x=iris[,1:3])
    plot(Fhat, alpha=0.3)
}

test_29 <- function() {
    ## univariate example
    data(iris)
    ir <- iris[,1]
    ir.gr <- iris[,5]
    kda.fhat <- kda(x=ir, x.group=ir.gr, xmin=3, xmax=9)
    plot(kda.fhat, xlab="Sepal length")

    ## bivariate example
    ir <- iris[,1:2]
    ir.gr <- iris[,5]
    kda.fhat <- kda(x=ir, x.group=ir.gr)
    plot(kda.fhat, alpha=0.2, drawlabels=FALSE)

    ## trivariate example
    ir <- iris[,1:3]
    ir.gr <- iris[,5]
    kda.fhat <- kda(x=ir, x.group=ir.gr)
    plot(kda.fhat) ## colour=species, transparency=density heights
}

test_30 <- function() {
    ## univariate example
    data(tempb)
    fhat1 <- kdde(x=tempb[,"tmin"], deriv.order=1)   ## gradient [df/dx, df/dy]
    plot(fhat1, xlab="Min. temp.", col.cont=4)       ## df/dx
    points(20,predict(fhat1, x=20))

    ## bivariate example
    fhat1 <- kdde(x=tempb[,c("tmin", "tmax")], deriv.order=1)
    ## gradient [df/dx, df/dy]
    plot(fhat1, display="quiver")
  

    fhat2 <- kdde(x=tempb[,c("tmin", "tmax")], deriv.order=2)
    plot(fhat2, which.deriv.ind=2, display="persp", phi=10)
    ## d^2 f/(dx dy): blue=-ve, red=+ve
    plot(fhat2, which.deriv.ind=2, display="filled.contour", lwd=1)
    ## summary curvature 
    s2 <- kcurv(fhat2)
    plot(s2, display="filled.contour", lwd=1)

    ## trivariate example  
    data(iris)
    fhat1 <- kdde(iris[,2:4], deriv.order=1)
    plot(fhat1)
}

test_31 <- function() {
    ## univariate example
    data(iris)
    fhat <- kde(x=iris[,2])
    plot(fhat, cont=50, col.cont=4, cont.lwd=2, xlab="Sepal length")

    ## bivariate example
    fhat <- kde(x=iris[,2:3])
    plot(fhat, display="filled.contour", cont=seq(10,90,by=10), lwd=1, alpha=0.5)
    plot(fhat, display="persp", border=1, alpha=0.5)

    ## trivariate example
    fhat <- kde(x=iris[,2:4])
    plot(fhat)
    if (interactive()) plot(fhat, display="rgl")
}

test_32 <- function() {
    ## bivariate
    data(air)
    air.var <- c("co2","pm10","no")
    air <- air[, c("date","time",air.var)]
    air2 <- reshape(air, idvar="date", timevar="time", direction="wide")
    a1 <- as.matrix(na.omit(air2[, paste0(air.var, ".08:00")]))
    a2 <- as.matrix(na.omit(air2[, paste0(air.var, ".20:00")]))
    colnames(a1) <- air.var
    colnames(a2) <- air.var
    air08 <- a1[,c("co2","pm10")]
    air20 <- a2[,c("co2","pm10")]

    loct <- kde.local.test(x1=air08, x2=air20)
    plot(loct, lwd=1)

    ## significant curvature regions
    air20.fs <- kfs(air20)
    plot(air20.fs, add=TRUE)

    ## trivariate
    air08 <- a1; air20 <- a2
    loct <- kde.local.test(x1=air08, x2=air20)
    plot(loct, xlim=c(0,800), ylim=c(0,300), zlim=c(0,300))
}

test_33 <- function() {
    ## normal mixture partition
    mus <- rbind(c(-1,0), c(1, 2/sqrt(3)), c(1,-2/sqrt(3)))
    Sigmas <- 1/25*rbind(invvech(c(9, 63/10, 49/4)), invvech(c(9,0,49/4)), invvech(c(9,0,49/4)))
    props <- c(3,3,1)/7
    gridsize <- c(11,11) ## small gridsize illustrative purposes only 
    nmixt.part <- mvnorm.mixt.part(mus=mus, Sigmas=Sigmas, props=props, gridsize=gridsize)
    plot(nmixt.part, asp=1, xlim=c(-3,3), ylim=c(-3,3), alpha=0.5)

    ## kernel mean shift partition
    set.seed(81928192)
    x <- rmvnorm.mixt(n=10000, mus=mus, Sigmas=Sigmas, props=props)
    msize <- round(prod(gridsize)*0.1)
    kms.nmixt.part <- kms.part(x=x, min.clust.size=msize, gridsize=gridsize)
    plot(kms.nmixt.part, asp=1, xlim=c(-3,3), ylim=c(-3,3), alpha=0.5)
}

test_34 <- function() {
    data(geyser, package="MASS")
    geyser.kde <- kde(geyser)
    geyser.fs <- kfs(geyser, binned=TRUE)
    plot(geyser.kde, col=1)
    plot(geyser.fs, add=TRUE, alpha=0.6)
}

test_35 <- function() {
    data(fgl, package="MASS")
    x1 <- fgl[fgl[,"type"]=="WinF",c("RI", "Na")]
    x2 <- fgl[fgl[,"type"]=="Head",c("RI", "Na")]
    Rhat <- kroc(x1=x1, x2=x2) 
    plot(Rhat, add.roc.ref=TRUE)
}

test_36 <- function() {
    ## bivariate 
    mus <- rbind(c(0,0), c(-1,1))
    Sigma <- matrix(c(1, 0.7, 0.7, 1), nr=2, nc=2) 
    Sigmas <- rbind(Sigma, Sigma)
    props <- c(1/2, 1/2)
    plotmixt(mus=mus, Sigmas=Sigmas, props=props, display="filled.contour", lwd=1)

    ## trivariate 
    mus <- rbind(c(0,0,0), c(-1,0.5,1.5))
    Sigma <- matrix(c(1, 0.7, 0.7, 0.7, 1, 0.7, 0.7, 0.7, 1), nr=3, nc=3) 
    Sigmas <- rbind(Sigma, Sigma)
    props <- c(1/2, 1/2)
    plotmixt(mus=mus, Sigmas=Sigmas, props=props, dfs=c(11,8), dist="t")
}

test_37 <- function() {
    data(unicef)
    unicef.sp <- pre.sphere(as.matrix(unicef))
}

test_38 <- function() {
    set.seed(8192)
    x <- rnorm.mixt(n=10000, mus=0, sigmas=1, props=1)
    fhat <- kde(x=x)
    p1 <- pkde(fhat=fhat, q=c(-1, 0, 0.5))
    qkde(fhat=fhat, p=p1)    
    y <- rkde(fhat=fhat, n=100)

    x <- rmvnorm.mixt(n=10000, mus=c(0,0), Sigmas=invvech(c(1,0.8,1)))
    fhat <- kde(x=x)
    y <- rkde(fhat=fhat, n=1000)
    fhaty <- kde(x=y)
    plot(fhat, col=1)
    plot(fhaty, add=TRUE, col=2)
}

test_39 <- function() {
    x <- matrix(1:9, nrow=3, ncol=3)
    vec(x)
    invvec(vec(x))
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

