library(flexclust)
test_1 <- function() {
    data(Nclus)
    cl <- cclust(Nclus, k=4, simple=FALSE, save.data=TRUE)
    plot(cl)
}

test_2 <- function() {
    data(auto)
    summary(auto)
}

test_3 <- function() {
      cl <- cclust(iris[,-5], k=3)
      barplot(cl)
      barplot(cl, bycluster=FALSE)

      ## plot the maximum instead of mean value per cluster:
      barplot(cl, bycluster=FALSE, data=iris[,-5],
              FUN=function(x) apply(x,2,max))

      ## use lattice for plotting:
      barchart(cl)
      ## automatic abbreviation of labels
      barchart(cl, scales=list(abbreviate=TRUE))
      ## origin of bars at zero
      barchart(cl, scales=list(abbreviate=TRUE), origin=0)

      ## Use manual labels. Note that the flexclust barchart orders bars
      ## from top to bottom (the default does it the other way round), hence
      ## we have to rev() the labels:
      LAB <- c("SL", "SW", "PL", "PW")
      barchart(cl, scales=list(y=list(labels=rev(LAB))), origin=0)

      ## deviation of each cluster center from the population means
      barchart(cl, origin=rev(cl@xcent), mlcol=NULL)

      ## use shading to highlight large deviations from population mean
      barchart(cl, shade=TRUE)

      ## use smaller deviation limit than default and add a legend
      barchart(cl, shade=TRUE, diff=0.2, legend=TRUE)
}

test_4 <- function() {
    data(iris)
    bc1 <- bclust(iris[,1:4], 3, base.k=5)
    plot(bc1)

    table(clusters(bc1, k=3))
    parameters(bc1, k=3)
}

test_5 <- function() {
    p02 <- bundestag(2002)
    pairs(p02)
    p05 <- bundestag(2005)
    pairs(p05)
    p09 <- bundestag(2009)
    pairs(p09)

    state <- bundestag(2002, state=TRUE)
    table(state)

    start.with.b <- bundestag(2002, state="^B")
    table(start.with.b)

    pairs(p09, col=2-(state=="Bayern"))
}

test_6 <- function() {
      set.seed(1)
      cl <- cclust(iris[,-5], k=3, save.data=TRUE)
      bwplot(cl)
      bwplot(cl, byvar=TRUE)

      ## fill only boxes with color which do not contain the overall median
      ## (grey dot of background box)
      bwplot(cl, shade=TRUE)

      ## fill only boxes with color which do not overlap with the box of the
      ## complete sample (grey background box)
      bwplot(cl, shadefun="boxOverlap")
}

test_7 <- function() {
    ## a 2-dimensional example
    x <- rbind(matrix(rnorm(100, sd=0.3), ncol=2),
               matrix(rnorm(100, mean=1, sd=0.3), ncol=2))
    cl <- cclust(x,2)
    plot(x, col=predict(cl))
    points(cl@centers, pch="x", cex=2, col=3) 

    ## a 3-dimensional example 
    x <- rbind(matrix(rnorm(150, sd=0.3), ncol=3),
               matrix(rnorm(150, mean=2, sd=0.3), ncol=3),
               matrix(rnorm(150, mean=4, sd=0.3), ncol=3))
    cl <- cclust(x, 6, method="neuralgas", save.data=TRUE)
    pairs(x, col=predict(cl))
    plot(cl)
}

test_8 <- function() {
    example(Nclus)

    clusterSim(cl)
    clusterSim(cl, symmetric=TRUE)

    ## should have similar structure but will be numerically different:
    clusterSim(cl, symmetric=TRUE, data=Nclus[sample(1:550, 200),])

    ## different concept of cluster similarity
    clusterSim(cl, method="centers")
}

test_9 <- function() {
    data(Nclus)

    cl1 <- kmeans(Nclus, 4)
    cl1
    cl1a <- as.kcca(cl1, Nclus)
    cl1a
    cl1b <- as(cl1a, "kmeans")



    library("cluster")
    cl2 <- pam(Nclus, 4)
    cl2
    cl2a <- as.kcca(cl2)
    cl2a
    ## the same
    cl2b <- as.kcca(cl2, Nclus)
    cl2b



    ## hierarchical clustering
    hc <- hclust(dist(USArrests))
    plot(hc)
    rect.hclust(hc, k=3)
    c3 <- Cutree(hc, k=3)
    k3 <- as.kcca(hc, USArrests, k=3)
    barchart(k3)
    table(c3, clusters(k3))
}

test_10 <- function() {
    x <- matrix(rnorm(20), ncol=4)
    rownames(x) = paste("X", 1:nrow(x), sep=".")
    y <- matrix(rnorm(12), ncol=4)
    rownames(y) = paste("Y", 1:nrow(y), sep=".")

    dist2(x, y)
    dist2(x, y, "man")

    data(milk)
    dist2(milk[1:5,], milk[4:6,])
}

test_11 <- function() {
    ## have a look at the defaults
    new("flexclustControl")

    ## corce a list
    mycont <- list(iter=500, tol=0.001, class="w")
    as(mycont, "flexclustControl")

    ## some additional slots
    as(mycont, "cclustControl")

    ## default values for ng.rate
    new("cclustControl")@ng.rate
}

test_12 <- function() {
    opar <- par(c("mfrow", "mar", "xaxt"))
    par(mfrow=c(2, 2), mar=c(0, 0, 2, 0), yaxt="n")

    x <- rep(1, 8)

    barplot(x, col = flxColors(color="full"), main="full")
    barplot(x, col = flxColors(color="dark"), main="dark")
    barplot(x, col = flxColors(color="medium"), main="medium")
    barplot(x, col = flxColors(color="light"), main="light")

    par(opar)
}

test_13 <- function() {
    data("Nclus")
    plot(Nclus)

    cl1 <- cclust(Nclus, k=4)
    summary(cl1)

    ## these two are the same
    info(cl1)
    info(cl1, "help")

    ## cluster sizes
    i1 <- info(cl1, "size")
    i1

    ## average within cluster distances
    i2 <- info(cl1, "av_dist")
    i2

    ## the sum of all within-cluster distances
    i3 <- info(cl1, "distsum")
    i3

    ## sum(i1*i2) must of course be the same as i3
    stopifnot(all.equal(sum(i1*i2), i3))



    ## This should return TRUE
    modeltools::infoCheck(cl1, "size")
    ## and this FALSE
    modeltools::infoCheck(cl1, "Homer Simpson")
    ## both combined
    i4 <- modeltools::infoCheck(cl1, c("size", "Homer Simpson"))
    i4

    stopifnot(all.equal(i4, c(TRUE, FALSE)))
}

test_14 <- function() {
    data("Nclus")
    plot(Nclus)

    ## try kmeans 
    cl1 <- kcca(Nclus, k=4)
    cl1

    image(cl1)
    points(Nclus)

    ## A barplot of the centroids 
    barplot(cl1)


    ## now use k-medians and kmeans++ initialization, cluster centroids
    ## should be similar...

    cl2 <- kcca(Nclus, k=4, family=kccaFamily("kmedians"),
               control=list(initcent="kmeanspp"))
    cl2

    ## ... but the boundaries of the partitions have a different shape
    image(cl2)
    points(Nclus)
}

test_15 <- function() {
    c.iris <- cclust(iris[,-5], 3, save.data=TRUE)
    df.c.iris <- kcca2df(c.iris)
    summary(df.c.iris)
    densityplot(~value|variable+group, data=df.c.iris)
}

test_16 <- function() {
    plot(priceFeature(200, "2clust"))
    plot(priceFeature(200, "3clust"))
    plot(priceFeature(200, "3clustold"))
    plot(priceFeature(200, "5clust"))
    plot(priceFeature(200, "ell"))
    plot(priceFeature(200, "tri"))
    plot(priceFeature(200, "circ"))
    plot(priceFeature(200, "square"))
    plot(priceFeature(200, "largesmall"))
}

test_17 <- function() {
     ## create a binary matrix from the iris data plus a random noise column
     x <- apply(iris[,-5], 2, function(z) z>median(z))
     x <- cbind(x, Noise=sample(0:1, 150, replace=TRUE))

     ## There are significant differences in all 4 original variables, Noise
     ## has most likely no significant difference (of course the difference
     ## will be significant in alpha percent of all random samples).
     p <- propBarchart(x, iris$Species)
     p
     summary(p)
     propBarchart(x, iris$Species, byvar=TRUE)
 
     x <- iris[,-5]
     x <- cbind(x, Noise=rnorm(150, mean=3))
     groupBWplot(x, iris$Species)
     groupBWplot(x, iris$Species, shade=TRUE)
     groupBWplot(x, iris$Species, shadefun="medianInside")
     groupBWplot(x, iris$Species, shade=TRUE, byvar=TRUE)
}

test_18 <- function() {
    x <- matrix(10*runif(1000), ncol=2)

    ## maximum distrance of point to cluster center is 3
    cl1 <- qtclust(x, radius=3)

    ## maximum distrance of point to cluster center is 1
    ## -> more clusters, longer runtime
    cl2 <- qtclust(x, radius=1)

    opar <- par(c("mfrow","mar"))
    par(mfrow=c(2,1), mar=c(2.1,2.1,1,1))
    plot(x, col=predict(cl1), xlab="", ylab="")
    plot(x, col=predict(cl2), xlab="", ylab="")
    par(opar)
}

test_19 <- function() {
    ## no class correlations: corrected Rand almost zero
    g1 <- sample(1:5, size=1000, replace=TRUE)
    g2 <- sample(1:5, size=1000, replace=TRUE)
    tab <- table(g1, g2)
    randIndex(tab)

    ## uncorrected version will be large, because there are many points
    ## which are assigned to different clusters in both cases
    randIndex(tab, correct=FALSE)
    comPart(g1, g2)

    ## let pairs (g1=1,g2=1) and (g1=3,g2=3) agree better
    k <- sample(1:1000, size=200)
    g1[k] <- 1
    g2[k] <- 1
    k <- sample(1:1000, size=200)
    g1[k] <- 3
    g2[k] <- 3
    tab <- table(g1, g2)

    ## the index should be larger than before
    randIndex(tab, correct=TRUE, original=TRUE)
    comPart(g1, g2)
}

test_20 <- function() {
    if(interactive()){
      par(ask=FALSE)
      randomTour(iris[,1:4], axiscol=2:5)
      randomTour(iris[,1:4], col=as.numeric(iris$Species), axiscol=4)

      x <- matrix(runif(300), ncol=3)
      x <- rbind(x, x+1, x+2)
      cl <- cclust(x, k=3, save.data=TRUE)

      randomTour(cl, center=0, axiscol="black")

      ## now use predicted cluster membership for new data as colors
      randomTour(cl, center=0, axiscol="black",
                 data=matrix(rnorm(3000, mean=1, sd=2), ncol=3))
    }
}

test_21 <- function() {
    data(Nclus)
    set.seed(1)
    c5 <- cclust(Nclus, 5, save.data=TRUE)
    c5
    plot(c5)

    ## high shadow values indicate clusters with *bad* separation
    shadow(c5)
    plot(shadow(c5))

    ## high Silhouette values indicate clusters with *good* separation
    Silhouette(c5)
    plot(Silhouette(c5))
}

test_22 <- function() {
    data(Nclus)
    set.seed(1)
    c5 <- cclust(Nclus, 5, save.data=TRUE)
    c5
    plot(c5)

    shadowStars(c5)
    shadowStars(c5, varwidth=TRUE)

    shadowStars(c5, panel=panelShadowViolin)
    shadowStars(c5, panel=panelShadowBP)

    ## always use varwidth=TRUE with panelShadowSkeleton, otherwise a few
    ## large shadow values can lead to misleading results:
    shadowStars(c5, panel=panelShadowSkeleton)
    shadowStars(c5, panel=panelShadowSkeleton, varwidth=TRUE)
}

test_23 <- function() {
    data("Nclus")
    cl25 <- stepFlexclust(Nclus, k=2:5)
    slsaplot(cl25)
    cl25 <- relabel(cl25)
    slsaplot(cl25)
}

test_24 <- function() {
    data("Nclus")
    cl3 <- kcca(Nclus, k = 3)
    slsw.cl3 <- slswFlexclust(Nclus, cl3, nsamp = 20)
    plot(Nclus, col = clusters(cl3))
    plot(slsw.cl3)
    densityplot(slsw.cl3)
    boxplot(slsw.cl3)
}

test_25 <- function() {
    data("Nclus")
    plot(Nclus)

    ## multicore off for CRAN checks
    cl1 <- stepFlexclust(Nclus, k=2:7, FUN=cclust, multicore=FALSE)
    cl1

    plot(cl1)

    # two ways to do the same:
    getModel(cl1, 4)
    cl1[[4]]

    opar <- par("mfrow")
    par(mfrow=c(2, 2))
    for(k in 3:6){
      image(getModel(cl1, as.character(k)), data=Nclus)
      title(main=paste(k, "clusters"))
    }
    par(opar)
}

test_26 <- function() {
    bw05 <- bundestag(2005)
    bavaria <- bundestag(2005, state="Bayern")

    set.seed(1)
    c4 <- cclust(bw05, k=4, save.data=TRUE)
    plot(c4)

    stripes(c4)
    stripes(c4, beside=TRUE)

    stripes(c4, type="sec")
    stripes(c4, type="sec", beside=FALSE)
    stripes(c4, type="all")

    stripes(c4, groups=bavaria)

    ## ugly, but shows how colors of all parts can be changed
    library("grid")
    stripes(c4, type="all",
            gp.bar=gpar(col="red", lwd=3, fill="white"),
            gp.bar2=gpar(col="green", lwd=3, fill="black"))
}

test_27 <- function() {
    data(vacmot)
    summary(vacmotdesc)
    dotchart(sort(colMeans(vacmot)))

    ## reproduce Figure 6 from Dolnicar & Leisch (2008)
    cl6 <- kcca(vacmot, k=vacmot6, control=list(iter=0))
    barchart(cl6)
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

