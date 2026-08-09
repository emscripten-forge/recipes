print('Loading spatial package')
library(spatial)
print('... spatial package loaded successfully')

test_1 <- function() {
    towns <- ppinit("towns.dat")
    par(pty="s")
    plot(Kfn(towns, 40), type="b")
    plot(Kfn(towns, 10), type="b", xlab="distance", ylab="L(t)")
    for(i in 1:10) lines(Kfn(Psim(69), 10))
    lims <- Kenvl(10,100,Psim(69))
    lines(lims$x,lims$lower, lty=2, col="green")
    lines(lims$x,lims$upper, lty=2, col="green")
    lines(Kaver(10,25,Strauss(69,0.5,3.5)),  col="red")
}

test_2 <- function() {
    towns <- ppinit("towns.dat")
    par(pty="s")
    plot(Kfn(towns, 40), type="b")
    plot(Kfn(towns, 10), type="b", xlab="distance", ylab="L(t)")
    for(i in 1:10) lines(Kfn(Psim(69), 10))
    lims <- Kenvl(10,100,Psim(69))
    lines(lims$x,lims$lower, lty=2, col="green")
    lines(lims$x,lims$upper, lty=2, col="green")
    lines(Kaver(10,25,Strauss(69,0.5,3.5)), col="red")
}

test_3 <- function() {
    towns <- ppinit("towns.dat")
    par(pty="s")
    plot(Kfn(towns, 10), type="s", xlab="distance", ylab="L(t)")
}

test_4 <- function() {
    towns <- ppinit("towns.dat")
    par(pty="s")
    plot(Kfn(towns, 10), type="s", xlab="distance", ylab="L(t)")
    for(i in 1:10) lines(Kfn(Psim(69), 10))
}

test_5 <- function() {
    towns <- ppinit("towns.dat")
    par(pty = "s")
    plot(Kfn(towns, 10), type = "b", xlab = "distance", ylab = "L(t)")
    lines(Kaver(10, 25, SSI(69, 1.2)))
}

test_6 <- function() {
    towns <- ppinit("towns.dat")
    par(pty="s")
    plot(Kfn(towns, 10), type="b", xlab="distance", ylab="L(t)")
    lines(Kaver(10, 25, Strauss(69,0.5,3.5)))
}

test_7 <- function() {
    library(stats)
    data(topo, package="MASS")
    topo0 <- surf.ls(0, topo)
    topo1 <- surf.ls(1, topo)
    topo2 <- surf.ls(2, topo)
    topo3 <- surf.ls(3, topo)
    topo4 <- surf.ls(4, topo)
    anova(topo0, topo1, topo2, topo3, topo4)
    summary(topo4)
}

test_8 <- function() {
    data(topo, package="MASS")
    topo.kr <- surf.ls(2, topo)
    correlogram(topo.kr, 25)
    d <- seq(0, 7, 0.1)
    lines(d, expcov(d, 0.7))
}

test_9 <- function() {
    data(topo, package="MASS")
    topo.kr <- surf.ls(2, topo)
    correlogram(topo.kr, 25)
    d <- seq(0, 7, 0.1)
    lines(d, expcov(d, 0.7))
}

test_10 <- function() {
    towns <- ppinit("towns.dat")
    par(pty="s")
    plot(Kfn(towns, 10), type="b", xlab="distance", ylab="L(t)")
}

test_11 <- function() {
    pines <- ppinit("pines.dat")
    pplik(pines, 0.7)
}

test_12 <- function() {
    data(topo, package="MASS")
    topo2 <- surf.ls(2, topo)
    topo4 <- surf.ls(4, topo)
    x <- c(1.78, 2.21)
    y <- c(6.15, 6.15)
    z2 <- predict(topo2, x, y)
    z4 <- predict(topo4, x, y)
    cat("2nd order predictions:", z2, "\n4th order predictions:", z4, "\n")
}

test_13 <- function() {
    data(topo, package="MASS")
    topo.kr <- surf.gls(2, expcov, topo, d=0.7)
    prsurf <- prmat(topo.kr, 0, 6.5, 0, 6.5, 50)
    contour(prsurf, levels=seq(700, 925, 25))
}

test_14 <- function() {
    data(topo, package="MASS")
    topo.kr <- surf.gls(2, expcov, topo, d=0.7)
    prsurf <- prmat(topo.kr, 0, 6.5, 0, 6.5, 50)
    contour(prsurf, levels=seq(700, 925, 25))
    sesurf <- semat(topo.kr, 0, 6.5, 0, 6.5, 30)
    contour(sesurf, levels=c(22,25))
}

test_15 <- function() {
    library(MASS)  # for eqscplot
    data(topo, package="MASS")
    topo.kr <- surf.gls(2, expcov, topo, d=0.7)
    trsurf <- trmat(topo.kr, 0, 6.5, 0, 6.5, 50)
    eqscplot(trsurf, type = "n")
    contour(trsurf, add = TRUE)

    prsurf <- prmat(topo.kr, 0, 6.5, 0, 6.5, 50)
    contour(prsurf, levels=seq(700, 925, 25))
    sesurf <- semat(topo.kr, 0, 6.5, 0, 6.5, 30)
    eqscplot(sesurf, type = "n")
    contour(sesurf, levels = c(22, 25), add = TRUE)
}

test_16 <- function() {
    library(MASS)  # for eqscplot
    data(topo, package="MASS")
    topo.kr <- surf.ls(2, topo)
    trsurf <- trmat(topo.kr, 0, 6.5, 0, 6.5, 50)
    eqscplot(trsurf, type = "n")
    contour(trsurf, add = TRUE)
    points(topo)

    eqscplot(trsurf, type = "n")
    contour(trsurf, add = TRUE)
    plot(topo.kr, add = TRUE)
    title(xlab= "Circle radius proportional to Cook's influence statistic")
}

test_17 <- function() {
    library(MASS)  # for eqscplot
    data(topo, package = "MASS")
    topo2 <- surf.ls(2, topo)
    infl.topo2 <- trls.influence(topo2)
    (cand <- as.data.frame(infl.topo2)[abs(infl.topo2$stresid) > 1.5, ])
    cand.xy <- topo[as.integer(rownames(cand)), c("x", "y")]
    trsurf <- trmat(topo2, 0, 6.5, 0, 6.5, 50)
    eqscplot(trsurf, type = "n")
    contour(trsurf, add = TRUE, col = "grey")
    plot(topo2, add = TRUE, div = 3)
    points(cand.xy, pch = 16, col = "orange")
    text(cand.xy, labels = rownames(cand.xy), pos = 4, offset = 0.5)
}

test_18 <- function() {
    data(topo, package="MASS")
    topo.kr <- surf.ls(2, topo)
    trsurf <- trmat(topo.kr, 0, 6.5, 0, 6.5, 50)
}

test_19 <- function() {
    data(topo, package="MASS")
    topo.kr <- surf.ls(2, topo)
    variogram(topo.kr, 25)
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

