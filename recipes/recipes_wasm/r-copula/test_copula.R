print('Loading copula package')
library(copula)
print('... copula package loaded successfully')

# mass library
library(MASS)

test_1 <- function() {
    ## Some of the more important functions (and their examples) are

    example(fitCopula)## fitting Copulas
    example(fitMvdc)  ## fitting multivariate distributions via Copulas
    example(nacopula) ## nested Archimedean Copulas

    ## Independence Tests:  These also draw a 'Dependogram':
    example(indepTest)       ## Testing for Independence
    example(serialIndepTest) ## Testing for Serial Independence
}

test_2 <- function() {
    ## True Pickands dependence functions
    curve(A(gumbelCopula(4   ), x), 0, 1)
    curve(A(gumbelCopula(2   ), x), add=TRUE, col=2)
    curve(A(gumbelCopula(1.33), x), add=TRUE, col=3)

    ## CFG estimator
    curve(An.biv(rCopula(1000, gumbelCopula(4   )), x), lty=2, add=TRUE)
    curve(An.biv(rCopula(1000, gumbelCopula(2   )), x), lty=2, add=TRUE, col=2)
    curve(An.biv(rCopula(1000, gumbelCopula(1.33)), x), lty=2, add=TRUE, col=3)

    ## Pickands estimator
    curve(An.biv(rCopula(1000, gumbelCopula(4   )), x, estimator="Pickands"),
          lty=3, add=TRUE)
    curve(An.biv(rCopula(1000, gumbelCopula(2   )), x, estimator="Pickands"),
          lty=3, add=TRUE, col=2)
    curve(An.biv(rCopula(1000, gumbelCopula(1.33)), x, estimator="Pickands"),
          lty=3, add=TRUE, col=3)

    legend("bottomleft",  paste0("Gumbel(", format(c(4, 2, 1.33)),")"),
           lwd=1, col=1:3, bty="n")
    legend("bottomright", c("true", "CFG est.", "Pickands est."), lty=1:3, bty="n")

    ## Relationship between An.biv and An
    u <- c(runif(100),0,1) # include 0 and 1
    x <- rCopula(1000, gumbelCopula(4))
    r <- An(x, cbind(1-u, u))
    all.equal(r$CFG, An.biv(x, u))
    all.equal(r$P, An.biv(x, u, estimator="Pickands"))

    ## A trivariate example
    x <- rCopula(1000, gumbelCopula(4, dim = 3))
    u <- matrix(runif(300), 100, 3)
    w <- u / apply(u, 1, sum)
    r <- An(x, w)

    ## Endpoint corrections are applied
    An(x, cbind(1, 0, 0))
    An(x, cbind(0, 1, 0))
    An(x, cbind(0, 0, 1))
}

test_3 <- function() {
    ## The example for the paper
    MASS::fractions(Bernoulli.all(8, verbose=TRUE))

    B10 <- Bernoulli.all(10)
    MASS::fractions(B10)

    system.time(B50  <- Bernoulli.all(50))#  {does not cache} -- still "no time"
    system.time(B100 <- Bernoulli.all(100))# still less than a milli second

    ## Using Bernoulli() is not much slower, but hopefully *more* accurate!
    ## Check first - TODO
    system.time(B.1c <- Bernoulli(100))# caches ..
    system.time(B1c. <- Bernoulli(100))# ==> now much faster
    stopifnot(identical(B.1c, B1c.))

    if(FALSE)## reset the cache:
    assign("Bern.tab", list(), envir = copula:::.nacopEnv)

    ## More experiments in the source of the copula package ../tests/Stirling-etc.R
}

test_4 <- function() {
    norm.cop <- normalCopula(0.5)
    norm.cop
    ## one d-vector =^= 1-row matrix, works too :
    dCopula(c(0.5, 0.5), norm.cop)
    pCopula(c(0.5, 0.5), norm.cop)

    u <- rCopula(100, norm.cop)
    plot(u)
    dCopula(u, norm.cop)
    pCopula(u, norm.cop)
    persp  (norm.cop, dCopula)
    contour(norm.cop, pCopula)

    ## a 3-dimensional normal copula
    u <- rCopula(1000, normalCopula(0.5, dim = 3))
    if(require(scatterplot3d))
      scatterplot3d(u)

    ## a 3-dimensional clayton copula
    cl3 <- claytonCopula(2, dim = 3)
    v <- rCopula(1000, cl3)
    pairs(v)
    if(require(scatterplot3d))
      scatterplot3d(v)

    ## Compare with the "nacopula" version :
    fu1 <- dCopula(v, cl3)
    fu2 <- copClayton@dacopula(v, theta = 2)
    Fu1 <- pCopula(v, cl3)
    Fu2 <- pCopula(v, onacopula("Clayton", C(2.0, 1:3)))
    ## The density and cumulative values are the same:
    stopifnot(all.equal(fu1, fu2, tolerance= 1e-14),
              all.equal(Fu1, Fu2, tolerance= 1e-15))

    ## NA and "outside" u[]
    u <- v[1:12,]
    ## replace some by values outside (0,1) and some by NA/NaN
    u[1, 2:3] <- c(1.5, NaN); u[2, 1] <- 2; u[3, 1:2] <- c(NA, -1)
    u[cbind(4:9, 1:3)] <- c(NA, NaN)
    f <- dCopula(u, cl3)
    cbind(u, f) # note: f(.) == 0 at [1] and [3] inspite of NaN/NA
    stopifnot(f[1:3] == 0, is.na(f[4:9]), 0 < f[10:12])
}

test_5 <- function() {
    tau <- 0.5
    (theta <- copGumbel@iTau(tau)) # 2
    d <- 20
    (cop <- onacopulaL("Gumbel", list(theta,1:d)))

    ## Basic check of the empirical Kendall distribution function
    set.seed(271)
    n <- 1000
    U <- rCopula(n, copula = cop)
    X <- qnorm(U)
    K.sample <- pCopula(U, copula = cop)
    u <- seq(0, 1, length.out = 256)
    edfK <- ecdf(K.sample)
    plot(u, edfK(u), type = "l", ylim = 0:1,
         xlab = quote(italic(u)), ylab = quote(K[n](italic(u)))) # simulated
    K.n <- Kn(u, x = X)
    lines(u, K.n, col = "royalblue3") # Kn
    ## Difference at 0
    edfK(0) # edf of K at 0
    K.n[1] # K_n(0); this is > 0 since K.n is the edf of a discrete distribution
    ## => therefore, Kn(K.sample, x = X) is not uniform
    plot(Kn(K.sample, x = X), ylim = 0:1)
    ## Note: Kn(0) -> 0 for n -> Inf

    ## Compute Kendall distribution function
    u <- seq(0,1, length.out = 255)
    Ku    <- pK(u, copula = cop@copula, d = d) # exact
    Ku.MC <- pK(u, copula = cop@copula, d = d, n.MC = 1000) # via Monte Carlo
    stopifnot(all.equal(log(Ku),
    		    pK(u, copula = cop@copula, d = d, log.p=TRUE)))# rel.err 3.2e-16

    ## Build sample from K
    set.seed(1)
    n <- 200
    W <- rK(n, copula = cop)

    ## Plot empirical distribution function based on W
    ## and the corresponding theoretical Kendall distribution function
    ## (exact and via Monte Carlo)
    plot(ecdf(W), col = "blue", xlim = 0:1, verticals=TRUE,
         main = quote("Empirical"~ F[n](C(U)) ~
                         "and its Kendall distribution" ~ K(u)),
         do.points = FALSE, asp = 1)
    abline(0,1, lty = 2); abline(h = 0:1, v = 0:1, lty = 3, col = "gray")
    lines(u, Ku.MC, col = "red") # not quite monotone
    lines(u, Ku, col = "black")  # strictly  monotone:
    stopifnot(diff(Ku) >= 0)
    legend(.25, .75, expression(F[n], K[MC](u), K(u)),
           col=c("blue" , "red", "black"), lty = 1, lwd = 1.5, bty = "n")

    if(require("Rmpfr")) { # pK() now also works with high precision numbers:
     uM <- mpfr(0:255, 99)/256
     if(FALSE) {
       # not yet, now fails in  polyG() :
       KuM <- pK(uM, copula = cop@copula, d = d)
      ##  debug(copula:::.pK)
      debug(copula:::polyG)
     }
    }# if( Rmpfr )


    ## Testing qK
    pexpr <- quote( 0:63/63 );  p <- eval(pexpr)
    d <- 10
    cop <- onacopulaL("Gumbel", list(theta = 2, 1:d))
    system.time(qK0 <- qK(p, copula = cop@copula, d = d)) # "default" - fast


    system.time(qK1  <- qK(p, copula= cop@copula, d=d, method = "simple"))
    system.time(qK1. <- qK(p, copula= cop@copula, d=d, method = "simple", tol = 1e-12))
    system.time(qK2  <- qK(p, copula= cop@copula, d=d, method = "sort"))
    system.time(qK2. <- qK(p, copula= cop@copula, d=d, method = "sort",   tol = 1e-12))
    system.time(qK3  <- qK(p, copula= cop@copula, d=d, method = "discrete", u.grid = 0:1e4/1e4))
    system.time(qK4  <- qK(p, copula= cop@copula, d=d, method = "monoH.FC",
                           u.grid = 0:5e2/5e2))
    system.time(qK4. <- qK(p, copula= cop@copula, d=d, method = "monoH.FC",
                           u.grid = 0:5e2/5e2, tol = 1e-12))
    system.time(qK5  <- qK(p, copula= cop@copula, d=d, method = "monoH.FC",
                           u.grid = 0:5e3/5e3))
    system.time(qK5. <- qK(p, copula= cop@copula, d=d, method = "monoH.FC",
                           u.grid = 0:5e3/5e3, tol = 1e-12))
    system.time(qK6  <- qK(p, copula= cop@copula, d=d, method = "monoH.FC",
                           u.grid = (0:5e3/5e3)^2))
    system.time(qK6. <- qK(p, copula= cop@copula, d=d, method = "monoH.FC",
                           u.grid = (0:5e3/5e3)^2, tol = 1e-12))

    ## Visually they all coincide :
    cols <- adjustcolor(c("gray50", "gray80", "light blue",
                          "royal blue", "purple3", "purple4", "purple"), 0.6)
    matplot(p, cbind(qK0, qK1, qK2, qK3, qK4, qK5, qK6), type = "l", lwd = 2*7:1, lty = 1:7, col = cols,
            xlab = bquote(p == .(pexpr)), ylab = quote({K^{-1}}(u)),
            main = "qK(p, method = *)")
    legend("topleft", col = cols, lwd = 2*7:1, lty = 1:7, bty = "n", inset = .03,
           legend= paste0("method= ",
                 sQuote(c("default", "simple", "sort",
                          "discrete(1e4)", "monoH.FC(500)", "monoH.FC(5e3)", "monoH.FC(*^2)"))))

    ## See they *are* inverses  (but only approximately!):
    eqInv <- function(qK) all.equal(p, pK(qK, cop@copula, d=d), tol=0)

    eqInv(qK0 ) # "default"	       0.03  worst
    eqInv(qK1 ) # "simple"	       0.0011 - best
    eqInv(qK1.) # "simple", e-12   0.00000 (8.73 e-13) !
    eqInv(qK2 ) # "sort"	       0.0013 (close)
    eqInv(qK2.) # "sort", e-12     0.00000 (7.32 e-12)
    eqInv(qK3 ) # "discrete"       0.0026
    eqInv(qK4 ) # "monoH.FC(500)"  0.0095
    eqInv(qK4.) # "m.H.FC(5c)e-12" 0.00963
    eqInv(qK5 ) # "monoH.FC(5e3)"  0.001148
    eqInv(qK5.) # "m.H.FC(5k)e-12" 0.000989
    eqInv(qK6 ) # "monoH.FC(*^2)"  0.001111
    eqInv(qK6.) # "m.H.FC(*^2)e-12"0.00000 (1.190 e-09)

    ## and ensure the differences are not too large
    stopifnot(
     all.equal(qK0, qK1, tol = 1e-2) # !
     ,
     all.equal(qK1, qK2, tol = 1e-4)
     ,
     all.equal(qK2, qK3, tol = 1e-3)
     ,
     all.equal(qK3, qK4, tol = 1e-3)
     ,
     all.equal(qK4, qK0, tol = 1e-2) # !
    )


    stopifnot(all.equal(p, pK(qK0, cop@copula, d=d), tol = 0.04))
}

test_6 <- function() {
    ## construct a bivariate distribution whose marginals
    ## are normal and exponential respectively, coupled
    ## together via a normal copula
    mv.NE <- mvdc(normalCopula(0.75), c("norm", "exp"),
                  list(list(mean = 0, sd =2), list(rate = 2)))
    dim(mv.NE)
    mv.NE  # using its print() / show() method

    persp  (mv.NE, dMvdc, xlim = c(-4, 4), ylim=c(0, 2), main = "dMvdc(mv.NE)")
    persp  (mv.NE, pMvdc, xlim = c(-4, 4), ylim=c(0, 2), main = "pMvdc(mv.NE)")
    contour(mv.NE, dMvdc, xlim = c(-4, 4), ylim=c(0, 2))

    # Generate (bivariate) random numbers from that, and visualize
    x.samp <- rMvdc(250, mv.NE)
    plot(x.samp)
    summary(fx <- dMvdc(x.samp, mv.NE))
    summary(Fx <- pMvdc(x.samp, mv.NE))
    op <- par(mfcol=c(1,2))
    pp <- persp(mv.NE, pMvdc, xlim = c(-5,5), ylim=c(0,2),
                main = "pMvdc(mv.NE)", ticktype="detail")
    px <- copula:::perspMvdc(x.samp, FUN = F.n, xlim = c(-5, 5), ylim = c(0, 2),
                             main = "F.n(x.samp)", ticktype="detail")
    par(op)
    all.equal(px, pp)# about 5% difference
}

test_7 <- function() {
    set.seed(100)
    n <- 250 # sample size
    d <- 5 # dimension
    nu <- 3 # degrees of freedom

    ## Build a mean vector and a dispersion matrix,
    ## and generate multivariate t_nu data:
    mu <- rev(seq_len(d)) # d, d-1, .., 1
    L <- diag(d) # identity in dim d
    L[lower.tri(L)] <- 1:(d*(d-1)/2)/d # Cholesky factor (diagonal > 0)
    Sigma <- crossprod(L) # pos.-def. dispersion matrix (*not* covariance of X)
    X <- rep(mu, each=n) + mvtnorm::rmvt(n, sigma=Sigma, df=nu) # multiv. t_nu data
    ## note: this is *wrong*: mvtnorm::rmvt(n, mean=mu, sigma=Sigma, df=nu)

    ## compute pseudo-observations of the radial part and uniform distribution
    ## once for 1a), once for 1b) below
    RS.t    <- RSpobs(X, method="ellip", qQg=function(p) qt(p, df=nu)) # 'correct'
    RS.norm <- RSpobs(X, method="ellip", qQg=qnorm) # for testing 'wrong' distribution
    stopifnot(length(RS.norm$R) == n, length(RS.t$R) == n,
              dim(RS.norm$S) == c(n,d), dim(RS.t$S) == c(n,d))

    ## 1) Graphically testing the radial part

    ## 1a) Q-Q plot of R against the correct quantiles
    qqplot2(RS.t$R, qF=function(p) sqrt(d*qf(p, df1=d, df2=nu)),
            main.args=list(text= substitute(bold(italic(F[list(d.,nu.)](r^2/d.))~~"Q-Q Plot"),
                                            list(d.=d, nu.=nu)),
    		       side=3, cex=1.3, line=1.1, xpd=NA))

    ## 1b) Q-Q plot of R against the quantiles of F_R for a multivariate normal
    ##     distribution
    qqplot2(RS.norm$R, qF=function(p) sqrt(qchisq(p, df=d)),
            main.args=list(text= substitute(bold(italic(chi[D_]) ~~ "Q-Q Plot"), list(D_=d)),
                   side=3, cex=1.3, line=1.1, xpd=NA))

    ## 2) Graphically testing the angular distribution

    ## auxiliary function
    qqp <- function(k, Bmat) {
        d <- ncol(Bmat) + 1
        qqplot2(Bmat[,k],
                qF = function(p) qbeta(p, shape1=k/2, shape2=(d-k)/2),
                main.args=list(text= substitute(plain("Beta")(s1,s2) ~~ bold("Q-Q Plot"),
                                                list(s1 = k/2, s2 = (d-k)/2)),
      	                   side=3, cex=1.3, line=1.1, xpd=NA))
    }

    ## 2a) Q-Q plot of the 'correct' angular distribution
    ##     (Bmat[,k] should follow a Beta(k/2, (d-k)/2) distribution)
    Bmat.t <- gofBTstat(RS.t$S)
    qqp(1, Bmat=Bmat.t) # k=1
    qqp(3, Bmat=Bmat.t) # k=3

    ## 2b) Q-Q plot of the 'wrong' angular distribution
    Bmat.norm <- gofBTstat(RS.norm$S)
    qqp(1, Bmat=Bmat.norm) # k=1
    qqp(3, Bmat=Bmat.norm) # k=3

    ## 3) Graphically check independence between radial part and B_1 and B_3

    ## 'correct' distributions (multivariate t)
    plot(pobs(cbind(RS.t$R, Bmat.t[,1])), # k = 1
              xlab=quote(italic(R)), ylab=quote(italic(B)[1]),
              main=quote(bold("Rank plot between"~~italic(R)~~"and"~~italic(B)[1])))
    plot(pobs(cbind(RS.t$R, Bmat.t[,3])), # k = 3
    	  xlab=quote(italic(R)), ylab=quote(italic(B)[3]),
              main=quote(bold("Rank plot between"~~italic(R)~~"and"~~italic(B)[3])))

    ## 'wrong' distributions (multivariate normal)
    plot(pobs(cbind(RS.norm$R, Bmat.norm[,1])), # k = 1
              xlab=quote(italic(R)), ylab=quote(italic(B)[1]),
              main=quote(bold("Rank plot between"~~italic(R)~~"and"~~italic(B)[1])))
    plot(pobs(cbind(RS.norm$R, Bmat.norm[,3])), # k = 3
    	  xlab=quote(italic(R)), ylab=quote(italic(B)[3]),
              main=quote(bold("Rank plot between"~~italic(R)~~"and"~~italic(B)[3])))
}

test_8 <- function() {
    data(SMI.12)
    ## maybe
    head(SMI.12)

    str(D.12 <- as.Date(rownames(SMI.12)))
    summary(D.12)

    matplot(D.12, SMI.12, type="l", log = "y",
            main = "The 20 SMI constituents  (2011-09 -- 2012-03)",
            xaxt="n", xlab = "2011  /  2012")
    Axis(D, side=1)



    if(FALSE) { ##--- This worked up to mid 2012, but no longer ---
     begSMI <- "2011-09-09"
     endSMI <- "2012-03-28"
     ##-- read *public* data ------------------------------
     stopifnot(require(zoo), # -> to access all the zoo methods
               require(tseries))
     symSMI <- c("ABBN.VX","ATLN.VX","ADEN.VX","CSGN.VX","GIVN.VX","HOLN.VX",
    	     "BAER.VX","NESN.VX","NOVN.VX","CFR.VX", "ROG.VX", "SGSN.VX",
    	     "UHR.VX", "SREN.VX","SCMN.VX","SYNN.VX","SYST.VX","RIGN.VX",
    	     "UBSN.VX","ZURN.VX")
     lSMI <- sapply(symSMI, function(sym)
    		get.hist.quote(instrument = sym, start= begSMI, end= endSMI,
    			       quote = "Close", provider = "yahoo",
    			       drop=TRUE))
     ## check if stock data have the same length for each company.
     sapply(lSMI, length)
     ## "concatenate" all:
     SMIo <- do.call(cbind, lSMI)
     ## and fill in the NAs :
     SMI.12 <- na.fill(SMIo, "extend")
     colnames(SMI.12) <- sub("\\.VX", "", colnames(SMI.12))
     SMI.12 <- as.matrix(SMI.12)
    }##----       --- original download

    zoo.there <- "package:zoo" %in% search()
    if(zoo.there || require("zoo")) {
      stopifnot(identical(SMI.12,
         local({ S <- as.matrix(na.fill(do.call(cbind, lSMI), "extend"))
                 colnames(S) <- sub("\\.VX", "", colnames(S)); S })))
      if(!zoo.there) detach("package:zoo")
    }
}

test_9 <- function() {
    ## Sample n random variates from a Sibuya(alpha) distribution and plot a
    ## histogram
    n <- 1000
    alpha <- .4
    X <- rSibuya(n, alpha)
    hist(log(X), prob=TRUE); lines(density(log(X)), col=2, lwd=2)
}

test_10 <- function() {
    Stirling1(7,2)
    Stirling2(7,3)

    Stirling1.all(9)
    Stirling2.all(9)
}

test_11 <- function() {
    t <- c(0:100,Inf)
    set.seed(1)
    (ps <- absdPsiMC(t, family="Gumbel", theta=2, degree=10, n.MC=10000, log=TRUE))
    ## Note: The absolute value of the derivative at 0 should be Inf for
    ## Gumbel, however, it is always finite for the Monte Carlo approximation
    set.seed(1)
    ps2 <- absdPsiMC(log(t), family="Gumbel", theta=2, degree=10,
                     n.MC=10000, log=TRUE, is.log.t = TRUE)
    stopifnot(all.equal(ps[-1], ps2[-1], tolerance=1e-14))
    ## Now is there an advantage of using "is.log.t" ?
    sapply(eval(formals(absdPsiMC)$method), function(MM)
           absdPsiMC(780, family="Gumbel", method = MM,
                     theta=2, degree=10, n.MC=10000, log=TRUE, is.log.t = TRUE))
    ## not really better, yet...
}

test_12 <- function() {
    ## setup
    family <- "Gumbel"
    tau <- 0.5
    m <- 256
    dmax <- 20
    x <- seq(0, 20, length.out=m)

    ## compute and plot pacR() for various d's
    y <- vapply(1:dmax, function(d)
                pacR(x, family=family, theta=iTau(archmCopula(family), tau), d=d),
                rep(NA_real_, m))
    plot(x, y[,1], type="l", ylim=c(0,1),
         xlab = quote(italic(x)), ylab = quote(F[R](x)),
         main = substitute(italic(F[R](x))~~ "for" ~ d==1:.D, list(.D = dmax)))
    for(k in 2:dmax) lines(x, y[,k])
}

test_13 <- function() {
    ## acopula class information
    showClass("acopula")

    ## Information and structure of Clayton copulas
    copClayton
    str(copClayton)

    ## What are admissible parameters for Clayton copulas?
    copClayton@paraInterval

    ## A Clayton "acopula" with Kendall's tau = 0.8 :
    (cCl.2 <- setTheta(copClayton, iTau(copClayton, 0.8)))

    ## Can two Clayton copulas with parameters theta0 and theta1 be nested?
    ## Case 1: theta0 = 3, theta1 = 2
    copClayton@nestConstr(theta0 = 3, theta1 = 2)
    ## -> FALSE as the sufficient nesting criterion is not fulfilled
    ## Case 2: theta0 = 2, theta1 = 3
    copClayton@nestConstr(theta0 = 2, theta1 = 3) # TRUE

    ## For more examples, see  help("acopula-families")
}

test_14 <- function() {
     C3 <- onacopula("AMH", C(0.7135, 1, C(0.943, 2:3)))
     allComp(C3) # components are 1:3
     allComp(C3@childCops[[1]]) # for the child, only  (2, 3)
}

test_15 <- function() {
    clayton.cop <- claytonCopula(2, dim = 3)
    ## scatterplot3d(rCopula(1000, clayton.cop))

    ## negative param (= theta) is allowed for dim = 2 :
    tau(claytonCopula(-0.5)) ## = -1/3
    tauClayton <- Vectorize(function(theta) tau(claytonCopula(theta, dim=2)))
    plot(tauClayton, -1, 10, xlab=quote(theta), ylim = c(-1,1), n=1025)
    abline(h=-1:1,v=0, col="#11111150", lty=2); axis(1, at=-1)

    tauFrank <- Vectorize(function(theta) tau(frankCopula(theta, dim=2)))
    plot(tauFrank, -40, 50, xlab=quote(theta), ylim = c(-1,1), n=1025)
    abline(h=-1:1,v=0, col="#11111150", lty=2)

    ## tauAMH() is function in our package
    iTau(amhCopula(), -1) # -1 with a range warning
    iTau(amhCopula(), (5 - 8*log(2)) / 3) # -1 with a range warning

    ic <- frankCopula(0) # independence copula (with a "message")
    stopifnot(identical(ic,
       frankCopula(0, use.indepC = "TRUE")))# indep.copula  withOUT message
    (fC <- frankCopula(0, use.indepC = "FALSE"))
    ## a Frank copula which corresponds to the indep.copula (but is not)

    frankCopula(dim = 3)# with NA parameters
    frank.cop <- frankCopula(3)# dim=2
    persp(frank.cop, dCopula)

    gumbel.cop <- archmCopula("gumbel", 5)
    stopifnot(identical(gumbel.cop, gumbelCopula(5)))
    contour(gumbel.cop, dCopula)

    amh.cop <- amhCopula(0.5)
    u. <- as.matrix(expand.grid(u=(0:10)/10, v=(0:10)/10, KEEP.OUT.ATTRS=FALSE))
    du <- dCopula(u., amh.cop)
    stopifnot(is.finite(du) | apply(u. == 0, 1,any)| apply(u. == 1, 1,any))

    ## A 7-dim Frank copula
    frank.cop <- frankCopula(3, dim = 7)
    x <- rCopula(5, frank.cop)
    ## dCopula now *does* work:
    dCopula(x, frank.cop)

    ## A 7-dim Gumbel copula
    gumbelC.7 <- gumbelCopula(2, dim = 7)
    dCopula(x, gumbelC.7)

    ## A 12-dim Joe copula
    joe.cop <- joeCopula(iTau(joeCopula(), 0.5), dim = 12)
    x <- rCopula(5, joe.cop)
    dCopula(x, joe.cop)
}

test_16 <- function() {
    gumbel.cop <- gumbelCopula(3)
    tau(gumbel.cop)
    rho(gumbel.cop)
    lambda(gumbel.cop)
    iTau(joeCopula(), 0.5)
    stopifnot(all.equal(tau(gumbel.cop), copGumbel@tau(3)),

              all.equal(lambda(gumbel.cop),
                        c(copGumbel@lambdaL(3), copGumbel@lambdaU(3)),
                        check.attributes=FALSE),

              all.equal(iTau (gumbel.cop, 0.681),
                        copGumbel@iTau(0.681))
    )

    ## let us compute the sample versions
    x <- rCopula(200, gumbel.cop)
    cor(x, method = "kendall")
    cor(x, method = "spearman")
    ## compare with the true parameter value 3
    iTau(gumbel.cop, cor(x, method="kendall" )[1,2])
    iRho(gumbel.cop, cor(x, method="spearman")[1,2])
}

test_17 <- function() {
    beta.(copGumbel, 2.5, d = 5)

    d.set <- c(2:6, 8, 10, 15, 20, 30)
    cols <- adjustcolor(colorRampPalette(c("red", "orange", "blue"),
                                         space = "Lab")(length(d.set)), 0.8)
    ## AMH:
    for(i in seq_along(d.set))
       curve(Vectorize(beta.,"theta")(copAMH, x, d = d.set[i]), 0, .999999,
             main = "Blomqvist's beta(.) for  AMH",
             xlab = quote(theta), ylab = quote(beta(theta, AMH)),
             add = (i > 1), lwd=2, col=cols[i])
    mtext("NB:  d=2 and d=3 are the same")
    legend("topleft", paste("d =",d.set), bty="n", lwd=2, col=cols)

    ## Gumbel:
    for(i in seq_along(d.set))
       curve(Vectorize(beta.,"theta")(copGumbel, x, d = d.set[i]), 1, 10,
             main = "Blomqvist's beta(.) for  Gumbel",
             xlab = quote(theta), ylab = quote(beta(theta, Gumbel)),
             add=(i > 1), lwd=2, col=cols[i])
    legend("bottomright", paste("d =",d.set), bty="n", lwd=2, col=cols)

    ## Clayton:
    for(i in seq_along(d.set))
       curve(Vectorize(beta.,"theta")(copClayton, x, d = d.set[i]), 1e-5, 10,
             main = "Blomqvist's beta(.) for  Clayton",
             xlab = quote(theta), ylab = quote(beta(theta, Gumbel)),
             add=(i > 1), lwd=2, col=cols[i])
    legend("bottomright", paste("d =",d.set), bty="n", lwd=2, col=cols)

    ## Joe:
    for(i in seq_along(d.set))
       curve(Vectorize(beta.,"theta")(copJoe, x, d = d.set[i]), 1, 10,
             main = "Blomqvist's beta(.) for  Joe",
             xlab = quote(theta), ylab = quote(beta(theta, Gumbel)),
             add=(i > 1), lwd=2, col=cols[i])
    legend("bottomright", paste("d =",d.set), bty="n", lwd=2, col=cols)

    ## Frank:
    for(i in seq_along(d.set))
       curve(Vectorize(beta.,"theta")(copFrank, x, d = d.set[i]), 1e-5, 50,
             main = "Blomqvist's beta(.) for  Frank",
             xlab = quote(theta), ylab = quote(beta(theta, Gumbel)),
             add=(i > 1), lwd=2, col=cols[i])
    legend("bottomright", paste("d =",d.set), bty="n", lwd=2, col=cols)

    ## Shows the numeric problems:
    curve(Vectorize(beta.,"theta")(copFrank, x, d = 29), 35, 42, col="violet")
}

test_18 <- function() {
    (Xtras <- copula:::doExtras()) # determine whether examples will be extra (long)

    ## 1) Sampling from a conditional distribution of a Clayton copula given u_1

    ## Define the copula
    tau <- 0.5
    theta <- iTau(claytonCopula(), tau = tau)
    d <- 2
    cc <- claytonCopula(theta, dim = d)
    n <- if(Xtras) 1000 else 250
    set.seed(271)

    ## A small u_1
    u1 <- 0.05
    U <- cCopula(cbind(u1, runif(n)), copula = cc, inverse = TRUE)
    plot(U[,2], ylab = quote(U[2]))

    ## A large u_1
    u1 <- 0.95
    U <- cCopula(cbind(u1, runif(n)), copula = cc, inverse = TRUE)
    plot(U[,2], ylab = quote(U[2]))


    ## 2) Sample via conditional distribution method and then apply the
    ##    Rosenblatt transform
    ##    Note: We choose the numerically more involved (and thus slower)
    ##          Gumbel case here

    ## Define the copula
    tau <- 0.5
    theta <- iTau(gumbelCopula(), tau = tau)
    d <- if(Xtras)  6  else  3
    n <- if(Xtras) 500 else 100
    gc <- gumbelCopula(theta, dim = d)
    set.seed(271)
    U. <- matrix(runif(n*d), ncol = d) # U(0,1)^d


    ## Transform to Gumbel sample via conditional distribution method
    U <- cCopula(U., copula = gc, inverse = TRUE) # slow for ACs except Clayton
    splom2(U) # scatter-plot matrix copula sample

    ## Rosenblatt transform back to U(0,1)^d (as a check)
    U. <- cCopula(U, copula = gc)
    splom2(U.) # U(0,1)^d again


    ## 3) cCopula() for elliptical copulas

    tau <- 0.5
    theta <- iTau(claytonCopula(), tau = tau)
    d <- if(Xtras)  7  else  3
    cc <- claytonCopula(theta, dim = d)
    set.seed(271)
    n <- if(Xtras) 1000 else 200
    U <- rCopula(n, copula = cc)
    X <- qnorm(U) # X now follows a meta-Clayton model with N(0,1) marginals
    U <- pobs(X) # build pseudo-observations

    fN <- fitCopula(normalCopula(dim = d), data = U) # fit a Gauss copula
    U.RN <- cCopula(U, copula = fN@copula)
    splom2(U.RN, cex = 0.2) # visible but not so clearly

    f.t <- fitCopula(tCopula(dim = d), U)
    U.Rt <- cCopula(U, copula = f.t@copula) # transform with a fitted t copula
    splom2(U.Rt, cex = 0.2) # still visible but not so clear

    ## Inverse (and check consistency)
    U.N <- cCopula(U.RN, copula = fN @copula, inverse = TRUE)
    U.t <- cCopula(U.Rt, copula = f.t@copula, inverse = TRUE)

    tol <- 1e-14
    stopifnot(
        all.equal(U, U.N),
        all.equal(U, U.t),
        all.equal(log(U.RN),
                  cCopula(U, copula = fN @copula, log = TRUE), tolerance = tol),
        all.equal(log(U.Rt),
                  cCopula(U, copula = f.t@copula, log = TRUE), tolerance = tol)
    )

    ## 4) cCopula() for a more sophisticated mixture copula (bivariate case only!)

    tau <- 0.5
    cc <- claytonCopula(iTau(claytonCopula(), tau = tau)) # first mixture component
    tc <- tCopula(iTau(tCopula(), tau = tau), df = 3) # t_3 copula
    tc90 <- rotCopula(tc, flip = c(TRUE, FALSE)) # t copula rotated by 90 degrees
    wts <- c(1/2, 1/2) # mixture weights
    mc <- mixCopula(list(cc, tc90), w = wts) # mixture copula with one copula rotated

    set.seed(271)
    U <- rCopula(n, copula = mc)
    U. <- cCopula(U, copula = mc) # Rosenblatt transform back to U(0,1)^2 (as a check)
    plot(U., xlab = quote(U*"'"[1]), ylab = quote(U*"'"[2])) # check for uniformity
}

test_19 <- function() {
    ## For 'matrix' objects
    cop <- gumbelCopula(2, dim = 3)
    n <- 1000
    set.seed(271)
    U <- rCopula(n, copula = cop)
    cloud2(U, xlab = quote(U[1]), ylab = quote(U[2]), zlab = quote(U[3]))

    ## For 'Copula' objects
    set.seed(271)
    cloud2(cop, n = n) # same as above

    ## For 'mvdc' objects
    mvNN <- mvdc(cop, c("norm", "norm", "exp"),
                 list(list(mean = 0, sd = 1), list(mean = 1), list(rate = 2)))
    cloud2(mvNN, n = n)
}

test_20 <- function() {
    a.k  <- coeffG(16, 0.55)
    plot(a.k, xlab = quote(k), ylab = quote(a[k]),
         main = "coeffG(16, 0.55)", log = "y", type = "o", col = 2)
    a.kH <- coeffG(16, 0.55, method = "horner")
    stopifnot(all.equal(a.k, a.kH, tol = 1e-11))# 1.10e-13 (64-bit Lnx, nb-mm4)
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
