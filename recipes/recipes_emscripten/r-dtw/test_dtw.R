print('Loading dtw package')
library(dtw)
print('... dtw package loaded successfully')

test_1 <- function() {

     library(dtw);
     ## demo(dtw);
}

test_2 <- function() {
    data(aami3a);
    data(aami3b);

    ## Plot both as a multivariate TS object
    ##  only extract the first 10 seconds

    plot( main="ECG (mV)",
     window(
      cbind(aami3a,aami3b)   ,end=10)
    )
}

test_3 <- function() {

      ds<-dtw(1:7+2,1:8,keep=TRUE,step=asymmetric);
      countPaths(ds)
      ## Result: 126
}

test_4 <- function() {


    ## A noisy sine wave as query
    idx<-seq(0,6.28,len=100);
    query<-sin(idx)+runif(100)/10;

    ## A cosine is for reference; sin and cos are offset by 25 samples
    reference<-cos(idx)
    plot(reference); lines(query,col="blue");

    ## Find the best match
    alignment<-dtw(query,reference);


    ## Display the mapping, AKA warping function - may be multiple-valued
    ## Equivalent to: plot(alignment,type="alignment")
    plot(alignment$index1,alignment$index2,main="Warping function");

    ## Confirm: 25 samples off-diagonal alignment
    lines(1:100-25,col="red")




    #########
    ##
    ## Partial alignments are allowed.
    ##

    alignmentOBE <-
      dtw(query[44:88],reference,
          keep.internals=TRUE,step.pattern=asymmetric,
          open.end=TRUE,open.begin=TRUE);
    plot(alignmentOBE,type="two",off=1);


    #########
    ##
    ## Subsetting allows warping and unwarping of
    ## timeseries according to the warping curve. 
    ## See first example below.
    ##

    ## Most useful: plot the warped query along with reference 
    plot(reference)
    lines(query[alignment$index1]~alignment$index2,col="blue")

    ## Plot the (unwarped) query and the inverse-warped reference
    plot(query,type="l",col="blue")
    points(reference[alignment$index2]~alignment$index1)



    #########
    ##
    ## Contour plots of the cumulative cost matrix
    ##    similar to: plot(alignment,type="density") or
    ##                dtwPlotDensity(alignment)
    ## See more plots in ?plot.dtw 
    ##

    ## keep.internals = TRUE so we can look into the cost matrix

    alignment<-dtw(query,reference,keep.internals=TRUE);

    contour(alignment$costMatrix,col=terrain.colors(100),x=1:100,y=1:100,
    	xlab="Query (noisy sine)",ylab="Reference (cosine)");

    lines(alignment$index1,alignment$index2,col="red",lwd=2);




    #########
    ##
    ## An hand-checkable example
    ##

    ldist<-matrix(1,nrow=6,ncol=6);  # Matrix of ones
    ldist[2,]<-0; ldist[,5]<-0;      # Mark a clear path of zeroes
    ldist[2,5]<-.01;		 # Forcely cut the corner

    ds<-dtw(ldist);			 # DTW with user-supplied local
                                     #   cost matrix
    da<-dtw(ldist,step.pattern=asymmetric);	 # Also compute the asymmetric 
    plot(ds$index1,ds$index2,pch=3); # Symmetric: alignment follows
                                     #   the low-distance marked path
    points(da$index1,da$index2,col="red");  # Asymmetric: visiting
                                            #   1 is required twice

    ds$distance;
    da$distance;



    #########
    ##
    ## A multivariate alignment example
    ##

    ## Reference: one lap around the unit circle
    t.ref <- seq(0, 2*pi, length.out = 100)
    reference <- cbind(cos(t.ref), sin(t.ref))

    ## Query: same path, traversed with a nonlinear time axis
    u <- seq(0, 1, length.out = 70)
    t.query <- 2*pi*(u^1.5)
    query <- cbind(cos(t.query), sin(t.query))

    ## Explicitly choose the local distance for the multivariate samples
    alignment.mv <- dtw(query, reference,
                        dist.method = "Euclidean",
                        keep.internals = TRUE)

    ## Equivalent precomputed local cost matrix:
    ## local.cost <- proxy::dist(query, reference, method = "Euclidean")
    ## alignment.mv <- dtw(local.cost, keep.internals = TRUE)

    plot(reference, type = "l", asp = 1, col = "black",
         xlab = "x", ylab = "y",
         main = "Multivariate alignment: same path, different timing")
    lines(query, col = "blue")

    plot(alignment.mv$index1, alignment.mv$index2, type = "l",
         xlab = "query index", ylab = "reference index",
         main = "Warping function for multivariate alignment")
}

test_5 <- function() {


    ## Symmetric step pattern => symmetric dissimilarity matrix;
    ## no problem coercing it to a dist object:

    m <- matrix(0,ncol=3,nrow=4)
    m <- row(m)
    dist(m,method="DTW");

    # Old-fashioned call style would be:
    #   dtwDist(m)
    #   as.dist(dtwDist(m))



    ## Find the optimal warping _and_ scale factor at the same time.
    ## (There may be a better, analytic way)

    # Prepare a query and a reference

    query<-sin(seq(0,4*pi,len=100))
    reference<-cos(seq(0,4*pi,len=100))

    # Make a set of several references, scaled from 0 to 3 in .1 increments.
    # Put them in a matrix, in rows

    scaleSet <- seq(0.1,3,by=.1)
    referenceSet<-outer(1/scaleSet,reference)

    # The query has to be made into a 1-row matrix.
    # Perform all of the alignments at once, and normalize the result.

    dist(t(query),referenceSet,meth="DTW")->distanceSet

    # The optimal scale for the reference is 1.0
    plot(scaleSet,scaleSet*distanceSet,
      xlab="Reference scale factor (denominator)",
      ylab="DTW distance",type="o",
      main="Sine vs scaled cosine alignment, 0 to 4 pi")





    ## Asymmetric step pattern: we can either disregard part of the pairs
    ## (as.dist), or average with the transpose

    mm <- matrix(runif(12),ncol=3)
    dm <- dist(mm,mm,method="DTW",step=asymmetric); # a crossdist object

    # Old-fashioned call style would be:
    #   dm <- dtwDist(mm,step=asymmetric)
    #   as.dist(dm)


    ## Symmetrize by averaging:
    (dm+t(dm))/2


    ## check definition
    stopifnot(dm[2,1]==dtw(mm[2,],mm[1,],step=asymmetric)$distance)
}

test_6 <- function() {

    ## Same example as in dtw

    idx<-seq(0,6.28,len=100);
    query<-sin(idx)+runif(100)/10;
    reference<-cos(idx)

    alignment<-dtw(query,reference,keep=TRUE);

    # A sample of the plot styles. See individual plotting functions for details

    plot(alignment, type="alignment",
      main="DTW sine/cosine: simple alignment plot")
  
    plot(alignment, type="twoway",
      main="DTW sine/cosine: dtwPlotTwoWay")

    plot(alignment, type="threeway",
      main="DTW sine/cosine: dtwPlotThreeWay")
  
    plot(alignment, type="density",
      main="DTW sine/cosine: dtwPlotDensity")
}

test_7 <- function() {

    ## A study of the "Itakura" parallelogram
    ##
    ## A widely held misconception is that the "Itakura parallelogram" (as
    ## described in the original article) is a global constraint.  Instead,
    ## it arises from local slope restrictions. Anyway, an "itakuraWindow",
    ## is provided in this package. A comparison between the two follows.

    ## The local constraint: three sides of the parallelogram are seen
    idx<-seq(0,6.28,len=100);
    query<-sin(idx)+runif(100)/10;
    reference<-cos(idx)

    ita <- dtw(query,reference,keep=TRUE,step=typeIIIc)
    dtwPlotDensity(ita, main="Slope-limited asymmetric step (Itakura)")

    ## Symmetric step with global parallelogram-shaped constraint. Note how
    ## long (>2 steps) horizontal stretches are allowed within the window.

    dtw(query,reference,keep=TRUE,window=itakuraWindow)->ita;
    dtwPlotDensity(ita,
            main="Symmetric step with Itakura parallelogram window")
}

test_8 <- function() {


    ## A noisy sine wave as query
    ## A cosine is for reference; sin and cos are offset by 25 samples

    idx<-seq(0,6.28,len=100);
    query<-sin(idx)+runif(100)/10;
    reference<-cos(idx)
    dtw(query,reference,keep=TRUE)->alignment;


    ## Beware of the reference's y axis, may be confusing
    ## Equivalent to plot(alignment,type="three");
    dtwPlotThreeWay(alignment);


    ## Highlight matches of chosen QUERY indices. We will do some index
    ## arithmetics to recover the corresponding indices along the warping
    ## curve

    hq <- (0:8)/8              
    hq <- round(hq*100)      #  indices in query for  pi/4 .. 7/4 pi

    hw <- (alignment$index1 %in% hq)   # where are they on the w. curve?
    hi <- (1:length(alignment$index1))[hw];   # get the indices of TRUE elems

    dtwPlotThreeWay(alignment,match.indices=hi);
}

test_9 <- function() {


    ## A noisy sine wave as query
    ## A cosine is for reference; sin and cos are offset by 25 samples

    idx<-seq(0,6.28,len=100);
    query<-sin(idx)+runif(100)/10;
    reference<-cos(idx)
    dtw(query,reference,step=asymmetricP1,keep=TRUE)->alignment;


    ## Equivalent to plot(alignment,type="two");
    dtwPlotTwoWay(alignment);


    ## Highlight matches of chosen QUERY indices. We will do some index
    ## arithmetics to recover the corresponding indices along the warping
    ## curve

    hq <- (0:8)/8              
    hq <- round(hq*100)      #  indices in query for  pi/4 .. 7/4 pi

    hw <- (alignment$index1 %in% hq)   # where are they on the w. curve?
    hi <- (1:length(alignment$index1))[hw];   # get the indices of TRUE elems


    ## Beware of the reference's y axis, may be confusing
    plot(alignment,offset=-2,type="two", lwd=3, match.col="grey50",
         match.indices=hi,main="Match lines shown every pi/4 on query");

    legend("topright",c("Query","Reference (rt. axis)"), pch=21, col=1:6)
}

test_10 <- function() {


    ## Display some windowing functions
    dtwWindow.plot(itakuraWindow, main="So-called Itakura parallelogram window")
    dtwWindow.plot(slantedBandWindow, window.size=2,
      reference=13, query=17, main="The slantedBandWindow at window.size=2")


    ## Asymmetric step with Sakoe-Chiba band

    idx<-seq(0,6.28,len=100); 
    query<-sin(idx)+runif(100)/10;
    reference<-cos(idx);

    asyband<-dtw(query,reference,keep=TRUE,
                 step=asymmetric,
                 window.type=sakoeChibaWindow,
                 window.size=30                  );

    dtwPlot(asyband,type="density",main="Sine/cosine: asymmetric step, S-C window")
}

test_11 <- function() {


    ## The hand-checkable example given in Fig. 5, ref. [1] above
    diffmx <- matrix( byrow=TRUE, nrow=5, c(
      0,  1,  8,  2,  2,  4,  8,
      1,  0,  7,  1,  1,  3,  7,
     -7, -6,  1, -5, -5, -3,  1,
     -5, -4,  3, -3, -3, -1,  3,
     -7, -6,  1, -5, -5, -3,  1 ) ) ;

    ## Cost matrix
    costmx <- diffmx^2;

    ## Compute the alignment
    al <- dtw(costmx,step.pattern=mvmStepPattern(10))

    ## Elements 4,5 are skipped
    print(al$index2)

    plot(al,main="Minimum Variance Matching alignment")
}

test_12 <- function() {


    #########
    ##
    ## The usual (normalizable) symmetric step pattern
    ## Step pattern recursion, defined as:
    ## g[i,j] = min(
    ##      g[i,j-1] + d[i,j] ,
    ##      g[i-1,j-1] + 2 * d[i,j] ,
    ##      g[i-1,j] + d[i,j] ,
    ##   )

    print(symmetric2)   # or just "symmetric2"



    #########
    ##
    ## The well-known plotting style for step patterns

    plot(symmetricP2,main="Sakoe's Symmetric P=2 recursion")



    #########
    ##
    ## Same example seen in ?dtw , now with asymmetric step pattern

    idx<-seq(0,6.28,len=100);
    query<-sin(idx)+runif(100)/10;
    reference<-cos(idx);

    ## Do the computation 
    asy<-dtw(query,reference,keep=TRUE,step=asymmetric);

    dtwPlot(asy,type="density",main="Sine and cosine, asymmetric step")


    #########
    ##
    ##  Hand-checkable example given in [Myers1980] p 61
    ##

    `tm` <-
    structure(c(1, 3, 4, 4, 5, 2, 2, 3, 3, 4, 3, 1, 1, 1, 3, 4, 2,
    3, 3, 2, 5, 3, 4, 4, 1), .Dim = c(5L, 5L))
}

test_13 <- function() {

    idx<-seq(0,6.28,len=100);
    query<-sin(idx)+runif(100)/10;
    reference<-cos(idx)

    alignment<-dtw(query,reference);


    wq<-warp(alignment,index.reference=FALSE);
    wt<-warp(alignment,index.reference=TRUE);

    old.par <- par(no.readonly = TRUE);
    par(mfrow=c(2,1));

    plot(reference,main="Warping query");
      lines(query[wq],col="blue");

    plot(query,type="l",col="blue",
      main="Warping reference");
      points(reference[wt]);

    par(old.par);


    ##############
    ##
    ## Asymmetric step makes it "natural" to warp
    ## the reference, because every query index has
    ## exactly one image (q->t is a function)
    ##

    alignment<-dtw(query,reference,step=asymmetric)
    wt<-warp(alignment,index.reference=TRUE);

    plot(query,type="l",col="blue",
      main="Warping reference, asymmetric step");
      points(reference[wt]);
}

test_14 <- function() {

      ds<-dtw(1:4,1:8);

      plot(ds);lines(seq(1,8,len=4),col="red");

      warpArea(ds)

      ## Result: 6
      ##  index 2 is 2 while diag is 3.3  (+1.3)
      ##        3    3               5.7  (+2.7)
      ##        4   4:8 (avg to 6)    8   (+2  )
      ##                                 --------
      ##                                     6
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

