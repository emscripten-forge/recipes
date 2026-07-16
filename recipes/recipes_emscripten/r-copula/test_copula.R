library(copula)
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

test_21 <- function() {
    contour(frankCopula(-0.8), dCopula)
    contour(frankCopula(-0.8), dCopula, delta=1e-6)
    contour(frankCopula(-1.2), pCopula)
    contour(claytonCopula(2), pCopula)

    ## the Gumbel copula density is "extreme"
    ## --> use fine grid (and enough levels):
    r <- contour(gumbelCopula(3), dCopula, n=200, nlevels=100)
    range(r$z)# [0, 125.912]
    ## Now superimpose contours of three resolutions:
    contour(r, levels = seq(1, max(r$z), by=2), lwd=1.5)
    contour(r, levels = (1:13)/2, add=TRUE, col=adjustcolor(1,3/4), lty=2)
    contour(r, levels = (1:13)/4, add=TRUE, col=adjustcolor(2,1/2),
            lty=3, lwd=3/4)

    x <- mvdc(gumbelCopula(3), c("norm", "norm"),
              list(list(mean = 0, sd =1), list(mean = 1)))
    contour(x, dMvdc, xlim=c(-2, 2), ylim=c(-1, 3))
    contour(x, pMvdc, xlim=c(-2, 2), ylim=c(-1, 3))
}

test_22 <- function() {
    ## For 'matrix' objects
    ## The Frechet--Hoeffding bounds W and M
    n.grid <- 26
    u <- seq(0, 1, length.out = n.grid)
    grid <- expand.grid("u[1]" = u, "u[2]" = u)
    W <- function(u) pmax(0, rowSums(u)-1) # lower bound W
    M <- function(u) apply(u, 1, min) # upper bound M
    x.W <- cbind(grid, "W(u[1],u[2])" = W(grid)) # evaluate W on 'grid'
    x.M <- cbind(grid, "M(u[1],u[2])" = M(grid)) # evaluate M on 'grid'
    contourplot2(x.W) # contour plot of W
    contourplot2(x.M) # contour plot of M

    ## For 'Copula' objects
    cop <- frankCopula(-4)
    contourplot2(cop, pCopula) # the copula
    contourplot2(cop, pCopula, xlab = "x", ylab = "y") # adjusting the labels
    contourplot2(cop, dCopula) # the density

    ## For 'mvdc' objects
    mvNN <- mvdc(gumbelCopula(3), c("norm", "norm"),
                 list(list(mean = 0, sd = 1), list(mean = 1)))
    xl <- c(-2, 2)
    yl <- c(-1, 3)
    contourplot2(mvNN, FUN = dMvdc, xlim = xl, ylim = yl, contour = FALSE)
    contourplot2(mvNN, FUN = dMvdc, xlim = xl, ylim = yl)
    contourplot2(mvNN, FUN = dMvdc, xlim = xl, ylim = yl, region = FALSE, labels = FALSE)
    contourplot2(mvNN, FUN = dMvdc, xlim = xl, ylim = yl, region = FALSE)
    contourplot2(mvNN, FUN = dMvdc, xlim = xl, ylim = yl,
                 col.regions = colorRampPalette(c("royalblue3", "maroon3"), space="Lab"))
}

test_23 <- function() {
    ## Print a copAMH object and its structure
    copAMH
    str(copAMH)

    ## Show admissible parameters for a Clayton copula
    copClayton@paraInterval

    ## Generate random variates from a Log(p) distribution via V0 of Frank
    p <- 1/2
    copFrank@V0(100, -log(1-p))

    ## Plot the upper tail-dependence coefficient as a function in the
    ## parameter for Gumbel's family
    curve(copGumbel@lambdaU(x), xlim = c(1, 10), ylim = c(0,1), col = 4)

    ## Plot Kendall's tau as a function in the parameter for Joe's family
    curve(copJoe@tau(x), xlim = c(1, 10), ylim = c(0,1), col = 4)

    ## ------- Plot psi() and tau() - and properties of all families ----

    ## The copula families currently provided:
    (famNms <- ls("package:copula", patt="^cop[A-Z]"))

    op <- par(mfrow= c(length(famNms), 2),
              mar = .6+ c(2,1.4,1,1), mgp = c(1.1, 0.4, 0))
    for(nm in famNms) { Cf <- get(nm)
       thet <- Cf@iTau(0.3)
       curve(Cf@psi(x, theta = thet), 0, 5,
             xlab = quote(x), ylab="", ylim=0:1, col = 2,
             main = substitute(list(NAM ~~~ psi(x, theta == TH), tau == 0.3),
                               list(NAM=Cf@name, TH=thet)))
       I <- Cf@paraInterval
       Iu <- pmin(10, I[2])
       curve(Cf@tau(x), I[1], Iu, col = 3,
             xlab = bquote(theta %in% .(format(I))), ylab = "",
             main = substitute(NAM ~~ tau(theta), list(NAM=Cf@name)))
    }
    par(op)

    ## Construct a bivariate Clayton copula with parameter theta
    theta <- 2
    C2 <- onacopula("Clayton", C(theta, 1:2))
    C2@copula # is an "acopula" with specific parameter theta

    curve(C2@copula@psi(x, C2@copula@theta),
          main = quote("Generator" ~~ psi ~~ " of Clayton A.copula"),
          xlab = quote(theta1), ylab = quote(psi(theta1)),
          xlim = c(0,5), ylim = c(0,1), col = 4)

    ## What is the corresponding Kendall's tau?
    C2@copula@tau(theta) # 0.5

    ## What are the corresponding tail-dependence coefficients?
    C2@copula@lambdaL(theta)
    C2@copula@lambdaU(theta)

    ## Generate n pairs of random variates from this copula
    U <- rnacopula(n = 1000, C2)
    ## and plot the generated pairs of random variates
    plot(U, asp=1, main = "n = 1000 from  Clayton(theta = 2)")
}

test_24 <- function() {
    hc <- evCopula("husler", 1.25)
    dim(hc)
    smoothScatter(u <- rCopula(2^11, hc))
    lambda   (hc)
    tau (hc)
    rho(hc)
    str(hc)
}

test_25 <- function() {
    ## If there are no NA's, corKendall() is faster than cor(*, "kendall")
    ## and gives the same :

    system.time(C1 <- cor(swiss, method="kendall"))
    system.time(C2 <- corKendall(swiss))
    stopifnot(all.equal(C1, C2,  tol = 1e-5))

    ## In the case of missing values (NA), corKendall() reverts to
    ## cor(*, "kendall", use = "pairwise") {no longer very fast} :

    swM <- swiss # shorter names and three missings:
    colnames(swM) <- abbreviate(colnames(swiss), min=6)
    swM[1,2] <- swM[7,3] <- swM[25,5] <- NA
    (C3 <- corKendall(swM)) # now automatically uses the same as
    stopifnot(identical(C3, cor(swM, method="kendall", use="pairwise")))
    ## and is quite close to the non-missing "truth":
    stopifnot(all.equal(unname(C3), unname(C2), tol = 0.06)) # rel.diff.= 0.055

    try(corKendall(swM, checkNA=FALSE)) # --> Error
    ## the error is really from  pcaPP::cor.fk(swM)
}

test_26 <- function() {
    th. <- c(0.1, 0.2, 0.5, 0.8, 1.4, 2., 5.)
    curve(dDiag(x, cop=onacopulaL("Clayton", list(th.[1], 1:3))), 0, 1,
          n=1000, ylab="dDiag(x, *)", main="Diagonal densities of Clayton")
    abline(h=0, lty=3)
    for(j in 2:length(th.))
      curve(dDiag(x, cop=onacopulaL("Clayton", list(th.[j], 1:3))), add=TRUE,
    	     col=j, n=1000)
    legend("topleft", do.call(expression, lapply(th., function(th)
                                     substitute(theta == TH, list(TH=th)))),
           lty = 1, col=seq_along(th.), bty="n")
}

test_27 <- function() {
    ## FIXME
}

test_28 <- function() {
    ## Construct a twenty-dimensional Gumbel copula with parameter chosen
    ## such that Kendall's tau of the bivariate margins is 0.25.
    theta <- copJoe@iTau(.25)
    C20 <- onacopula("J", C(theta, 1:20))

    ## Evaluate the copula density at the point u = (0.5,...,0.5)
    u <- rep(0.5, 20)
    dCopula(u, C20)

    ## the same with Monte Carlo based on 10000 simulated "frailties"
    dCopula(u, C20, n.MC = 10000)

    ## Evaluate the exact log-density at several points
    u <- matrix(runif(100), ncol=20)
    dCopula(u, C20, log = TRUE)

    ## Back-compatibility check
    stopifnot(identical( dCopula (u, C20), suppressWarnings(
                        dnacopula(C20, u))),
              identical( dCopula (u, C20, log = TRUE), suppressWarnings(
                        dnacopula(C20, u, log = TRUE))))
}

test_29 <- function() {
    normalCopula(c(0.5, 0.6, 0.7), dim = 3, dispstr = "un")
    t.cop <- tCopula(c(0.5, 0.3), dim = 3, dispstr = "toep",
                     df = 2, df.fixed = TRUE)
    getSigma(t.cop) # P matrix (with diagonal = 1)
    stopifnot(all.equal(toeplitz(c(1, .5, .3)), getSigma(t.cop)))

    ## dispersion "AR1" :
    nC.7 <- normalCopula(0.8, dim = 7, dispstr = "ar1")
    getSigma(nC.7)
    stopifnot(all.equal(toeplitz(.8^(0:6)), getSigma(nC.7)))

    ## from the wrapper
    norm.cop <- ellipCopula("normal", param = c(0.5, 0.6, 0.7),
                            dim = 3, dispstr = "un")
    if(require("scatterplot3d") && dev.interactive(orNone=TRUE)) {
      ## 3d scatter plot of 1000 random observations
      scatterplot3d(rCopula(1000, norm.cop))
      scatterplot3d(rCopula(1000, t.cop))
    }
    set.seed(12)
    uN <- rCopula(512, norm.cop)
    set.seed(2); pN1 <- pCopula(uN, norm.cop)
    set.seed(3); pN2 <- pCopula(uN, norm.cop)
    stopifnot(identical(pN1, pN2)) # no longer random for dim = 3
    (Xtras <- copula:::doExtras())
    if(Xtras) { ## a bit more accurately:
      set.seed(4); pN1. <- pCopula(uN, norm.cop, abseps = 1e-9)
      set.seed(5); pN2. <- pCopula(uN, norm.cop, abseps = 1e-9)
      stopifnot(all.equal(pN1., pN2., 1e-5))# see 3.397e-6
      ## but increasing the required precision (e.g., abseps=1e-15) does *NOT* help
    }

    ## For smaller copula dimension 'd', alternatives are available and
    ## non-random, see ?GenzBretz from package 'mvtnorm' :
    has_mvtn <- "package:mvtnorm" %in% search() #% << (workaround ESS Rd render bug)
    if(!has_mvtn)
      require("mvtnorm")# -> GenzBretz(), Miva(), and TVPACK() are available
    ## Note that Miwa() would become very slow for dimensions 5, 6, ..
    set.seed(4); pN1.M <- pCopula(uN, norm.cop, algorithm = Miwa(steps = 512))
    set.seed(5); pN2.M <- pCopula(uN, norm.cop, algorithm = Miwa(steps = 512))
    stopifnot(all.equal(pN1.M, pN2.M, tol= 1e-15))# *no* randomness
    set.seed(4); pN1.T <- pCopula(uN, norm.cop, algorithm = TVPACK(abseps = 1e-10))
    set.seed(5); pN2.T <- pCopula(uN, norm.cop, algorithm = TVPACK(abseps = 1e-14))
    stopifnot(all.equal(pN1.T, pN2.T, tol= 1e-15))# *no* randomness (but no effect of 'abseps')
    if(!has_mvtn)
       detach("package:mvtnorm")# (revert)


    ## Versions with unspecified parameters:
    tCopula()
    allEQ <- function(u,v) all.equal(u, v, tolerance=0)
    stopifnot(allEQ(ellipCopula("norm"), normalCopula()),
              allEQ(ellipCopula("t"), tCopula()))
    tCopula(dim=3)
    tCopula(dim=4, df.fixed=TRUE)
    tCopula(dim=5, disp = "toep", df.fixed=TRUE)
    normalCopula(dim=4, disp = "un")

    ## Toeplitz after *permutation* dispersions (new in copula 1.1-0) ---------
    tpar <- c(7,5,3)/8 # *gives* pos.def.:
    (ev <- eigen(toeplitz(c(1, tpar)), symmetric=TRUE, only.values=TRUE)$values)
    stopifnot(ev > 0)
    N4.   <- ellipCopula("normal", dim=4, param=tpar, dispstr = "toep") #"regular"
    ## reversed order is "the same" for toeplitz structure:
    N4.pr <- ellipCopula("normal", dim=4, param=tpar, dispstr = dispstrToep(4:1))
    N4.p1 <- ellipCopula("normal", dim=4, param=tpar, dispstr = dispstrToep(c(4,1:3)))
    N4.p2 <- ellipCopula("normal", dim=4, param=tpar, dispstr = dispstrToep(c(4:3,1:2)))
    N4.p3 <- ellipCopula("normal", dim=4, param=tpar, dispstr = dispstrToep(c(2,4,1,3)))

    (pm <- attr(N4.p3@dispstr, "perm")) # (2 4 1 3)
    ip <- c(3,1,4,2) # the *inverse* permutation of (2 4 1 3) = Matrix::invPerm(pm)
    (Sp3 <- getSigma(N4.p3)) # <-- "permuted toeplitz"
    Sp3[ip, ip] # re-ordered rows & columns => *is* toeplitz :
    stopifnot(exprs = {
      ## permutations  pm  and  ip  are inverses:
      pm[ip] == 1:4
      ip[pm] == 1:4
      is.matrix(T4 <- toeplitz(c(1, tpar)))
      identical(getSigma(N4.),   T4)
      identical(getSigma(N4.pr), T4) # 4:1 and 1:4 is "the same" for Rho
      identical(Sp3[ip, ip]  ,   T4)
      identical(Sp3,      T4[pm,pm])
    })
    ## Data generation -- NB: The U matrices are equal only "in distribution":
    set.seed(7); U.p3 <- rCopula(1000, N4.p3)
    set.seed(7); U.   <- rCopula(1000, N4.)
    stopifnot(exprs = {
     all.equal(loglikCopula(tpar, u=U.p3,      copula= N4.p3),
               loglikCopula(tpar, u=U.p3[,ip], copula= N4.) -> LL3)
     all.equal(loglikCopula(tpar, u=U.,      copula= N4.),
               loglikCopula(tpar, u=U.[,pm], copula= N4.p3) -> LL.)
    })
    c(LL. , LL3)# similar but different
    if(Xtras) {
      fm.  <- fitCopula(N4.  , U.  )
      fm.3 <- fitCopula(N4.p3, U.p3)
      summary(fm.3)
      stopifnot(all.equal(coef(fm.), coef(fm.3), tol = 0.01))# similar but different
    }
}

test_30 <- function() {
    tau <- 0.25
    (theta <- copGumbel@iTau(tau)) # 4/3
    d <- 20
    (cop <- onacopulaL("Gumbel", list(theta,1:d)))

    set.seed(1)
    n <- 200
    U <- rnacopula(n, cop)

    (meths <- eval(formals(emde)$method)) # "mde.chisq.CvM", ...
    fun <- function(meth, u, cop, theta){
    	run.time <- system.time(val <- emde(u, cop=cop, method=meth)$minimum)
    	list(value=val, error=val-theta, utime.ms=1000*run.time[[1]])
    }
    (res <- sapply(meths, fun, u=U, cop=cop, theta=theta))
}

test_31 <- function() {
    tau <- 0.25
    (theta <- copGumbel@iTau(tau)) # 4/3
    d <-  20
    (cop <- onacopulaL("Gumbel", list(theta,1:d)))

    set.seed(1)
    n <- 200
    U <- rnacopula(n,cop)

    ## Estimation
    system.time(efm <- emle(U, cop))
    summary(efm) # using bblme's 'mle2' method

    ## Profile likelihood plot [using S4 methods from bbmle/stats4] :
    pfm <- profile(efm)
    ci  <- confint(pfm, level=0.95)
    ci
    stopifnot(ci[1] <= theta, theta <= ci[2])
    plot(pfm)               # |z| against theta, |z| = sqrt(deviance)
    plot(pfm, absVal=FALSE, #  z  against theta
         show.points=TRUE) # showing how it's interpolated
    ## and show the true theta:
    abline(v=theta, col="lightgray", lwd=2, lty=2)
    axis(1, pos = 0, at=theta, label=quote(theta[0]))

    ## Plot of the log-likelihood, MLE  and  conf.int.:
    logL <- function(x) -efm@minuslogl(x)
           # == -sum(copGumbel@dacopula(U, theta=x, log=TRUE))
    logL. <- Vectorize(logL)
    I <- c(cop@copula@iTau(0.1), cop@copula@iTau(0.4))
    curve(logL., from=I[1], to=I[2], xlab=quote(theta),
          ylab="log-likelihood",
          main="log-likelihood for Gumbel")
    abline(v = c(theta, efm@coef), col="magenta", lwd=2, lty=2)
    axis(1, at=c(theta, efm@coef), padj = c(-0.5, -0.8), hadj = -0.2,
         col.axis="magenta", label= expression(theta[0], hat(theta)[n]))
    abline(v=ci, col="gray30", lwd=2, lty=3)
    text(ci[2], extendrange(par("usr")[3:4], f= -.04)[1],
         "95% conf. int.", col="gray30", adj = -0.1)
}

test_32 <- function() {
    ## Generate data X (from a meta-Gumbel model with N(0,1) margins)
    n <- 100
    d <- 3
    family <- "Gumbel"
    theta <- 2
    cop <- onacopulaL(family, list(theta=theta, 1:d))
    set.seed(1)
    X <- qnorm(rCopula(n, cop)) # meta-Gumbel data with N(0,1) margins

    ## Evaluate empirical copula
    u <- matrix(runif(n*d), n, d) # random points were to evaluate the empirical copula
    ec <- C.n(u, X = X)

    ## Compare the empirical copula with the true copula
    pc <- pCopula(u, copula = cop)
    mean(abs(pc - ec)) # ~= 0.012 -- increase n to decrease this error

    ## The same for the two smoothed versions
    beta <- C.n(u, X, smoothing = "beta")
    mean(abs(pc - beta))
    check <- C.n(u, X, smoothing = "checkerboard")
    mean(abs(pc - check))

    ## Compare the empirical copula with F.n(pobs())
    U <- pobs(X) # pseudo-observations
    stopifnot(identical(ec, F.n(u, X = pobs(U)))) # even identical

    ## Compare the empirical copula based on U at U with the Kendall distribution
    ## Note: Theoretically, C(U) ~ K, so K(C_n(U, U = U)) should approximately be U(0,1)
    plot(ecdf(pK(C.n(U, X), cop = cop@copula, d = d)), asp = 1, xaxs="i", yaxs="i")
    segments(0,0, 1,1, col=adjustcolor("blue",1/3), lwd=5, lty = 2)
    abline(v=0:1, col="gray70", lty = 2)

    ## Compare the empirical copula and the true copula on the diagonal
    C.n.diag <- function(u) C.n(do.call(cbind, rep(list(u), d)), X = X) # diagonal of C_n
    C.diag <- function(u) pCopula(do.call(cbind, rep(list(u), d)), cop) # diagonal of C
    curve(C.n.diag, from = 0, to = 1, # empirical copula diagonal
          main = paste("True vs empirical diagonal of a", family, "copula"),
          xlab = "u", ylab = quote("True C(u,..,u) and empirical"~C[n](u,..,u)))
    curve(C.diag, lty = 2, add = TRUE) # add true copula diagonal
    legend("bottomright", lty = 2:1, bty = "n", inset = 0.02,
           legend = expression(C, C[n]))

    ## Approximate partial derivatives w.r.t. the 2nd and 3rd component
    j.ind <- 2:3 # indices w.r.t. which the partial derivatives are computed
    ## Partial derivatives based on the empirical copula and the true copula
    der23 <- dCn(u, U = pobs(U), j.ind = j.ind)
    der23. <- copula:::dCdu(archmCopula(family, param=theta, dim=d), u=u)[,j.ind]
    ## Approximation error
    summary(as.vector(abs(der23-der23.)))

    ## For an example of using F.n(), see help(mvdc)% ./Mvdc.Rd

    ## Generate a bivariate empirical copula object (various smoothing methods)
    n <- 10 # sample size
    d <- 2 # dimension
    set.seed(271)
    X <- rCopula(n, copula = claytonCopula(3, dim = d))
    ecop.orig  <- empCopula(X) # smoothing = "none"
    ecop.beta  <- empCopula(X, smoothing = "beta")
    ecop.check <- empCopula(X, smoothing = "checkerboard")

    ## Sample from these (smoothed) empirical copulas
    m <- 50
    U.orig  <-  rCopula(m, copula = ecop.orig)
    U.beta  <-  rCopula(m, copula = ecop.beta)
    U.check <-  rCopula(m, copula = ecop.check)

    ## Plot
    wireframe2(ecop.orig,  FUN = pCopula, draw.4.pCoplines = FALSE)
    wireframe2(ecop.beta,  FUN = pCopula)
    wireframe2(ecop.check, FUN = pCopula)
    ## Density (only exists when smoothing = "beta")
    wireframe2(ecop.beta,  FUN = dCopula)

    ## Transform a copula sample to empirical margins
    set.seed(271)
    X <- qexp(rCopula(1000, copula = claytonCopula(2))) # multivariate distribution
    U <- rCopula(917, copula = gumbelCopula(2)) # new copula sample
    X. <- toEmpMargins(U, x = X) # tranform U to the empirical margins of X
    plot(X.) # Gumbel sample with empirical margins of X
}

test_33 <- function() {
    tau <- 0.25
    (theta <- copGumbel@iTau(tau)) # 4/3
    (Xtras <- copula:::doExtras())
    d <- if(Xtras)  12  else  5
    (cop <- onacopulaL("Gumbel", list(theta,1:d)))
    n <- if(Xtras) 500 else 50
    set.seed(1)
    U <- rnacopula(n, cop)
    meths <- eval(formals(enacopula)$method)
    if(!Xtras) meths <- meths[meths != "smle"] # as "smle" is slow..
    fun <- function(meth, u, cop, theta) {
        run.time <- system.time(val <- enacopula(u, cop=cop, method=meth))[["user.self"]]
        list(value= val, error= val-theta, utime.ms= 1000*run.time)
    }
    t(res <- sapply(meths, fun, u=U, cop=cop, theta=theta))
}

test_34 <- function() {
    tau <- 0.25
    (theta <- copGumbel@iTau(tau)) # 4/3 = 1.333..
    d <- 20
    (cop <- onacopulaL("Gumbel", list(theta,1:d)))

    set.seed(1)
    n <- 200
    U <- rnacopula(n, cop)

    system.time(theta.hat.beta <- ebeta(U, cop=cop))
    theta.hat.beta$root

    system.time(theta.hat.dmle <- edmle(U, cop=cop))
    theta.hat.dmle$minimum

    system.time(theta.hat.etau <- etau(U, cop=cop, method="tau.mean"))
    theta.hat.etau

    system.time(theta.hat.etau. <- etau(U, cop=cop, method="theta.mean"))
    theta.hat.etau.

    ## etau()  in the case of missing values (NA's)
    ## ------                 ---------------------
    ##' @title add Missing Values completely at random
    ##' @param x  matrix or vector
    ##' @param prob desired probability ("fraction") of missing values (\code{\link{NA}}s).
    ##' @return x[] with some (100*prob percent) entries replaced by \code{\link{NA}}s.
    addNAs <- function(x, prob) {
        np <- length(x)
        x[sample.int(np, prob*np)] <- NA
        x
    }

    ## UM[] := U[] with 5% missing values
    set.seed(7); UM <- addNAs(U, p = 0.05)
    mean(is.na(UM)) # 0.05
    ## This error if x has NA's was happening for  etau(UM, cop=cop)
    ## before copula version 0.999-17 (June 2017) :
    try(eM <- etau(UM, cop=cop, use = "everything"))
            #  --> Error ... NA/NaN/Inf in foreign function call
    ## The new default:
    eM0 <- etau(UM, cop=cop, use = "pairwise")
    eM1 <- etau(UM, cop=cop, use = "complete")
    ##  use = "complete" is really equivalent to dropping all obs. with with missing values:
    stopifnot(all.equal(eM1, etau(na.omit(UM), cop=cop), tol = 1e-15))
    ## but  use = "pairwise" ---> cor(*, use = "pairwise") is much better:
    rbind(etau.U = theta.hat.etau, etau.UM.pairwise = eM0, etau.UM.complete = eM1)
}

test_35 <- function() {
    ## Gumbel is both
    stopifnot(identical(   evCopula("gumbel"), gumbelCopula()),
              identical(archmCopula("gumbel"), gumbelCopula()))

    ## For a given degree of dependence these copulas are strikingly similar :

    tau <- 1/3

    gumbel.cop      <- gumbelCopula     (iTau(gumbelCopula(),      tau))
    galambos.cop    <- galambosCopula   (iTau(galambosCopula(),    tau))
    huslerReiss.cop <- huslerReissCopula(iTau(huslerReissCopula(), tau))
    tawn.cop        <- tawnCopula       (iTau(tawnCopula(),        tau))
    tev.cop         <- tevCopula        (iTau(tevCopula(),         tau))

    curve(A(gumbel.cop, x), 0, 1, ylab = "A(<cop>( iTau(<cop>(), tau)), x)",
          main = paste("A(x) for five Extreme Value cop. w/  tau =", format(tau)))
    curve(A(galambos.cop, x), lty=2, add=TRUE)
    curve(A(huslerReiss.cop, x), lty=3, add=TRUE)
    curve(A(tawn.cop, x), lty=4, add=TRUE)
    curve(A(tev.cop, x), lty=5, col=2, add=TRUE)# very close to Gumbel

    ## And look at the differences
    curve(A(gumbel.cop, x) - A(tawn.cop, x), ylim = c(-1,1)*0.005,
          ylab = '', main = "A(<Gumbel>, x) - A(<EV-Cop.>, x)")
    abline(h=0, lty=2)
    curve(A(gumbel.cop, x) - A(galambos.cop, x), add=TRUE, col=2)
    curve(A(gumbel.cop, x) - A(huslerReiss.cop, x), add=TRUE, col=3)
    curve(A(gumbel.cop, x) - A(tev.cop, x), add=TRUE, col=4, lwd=2)


    ## the t-EV-copula has always positive tau :
    curve(vapply(x, function(x) tau(tevCopula(x)), 0.), -1, 1,
          n=257, ylim=0:1, xlab=quote(rho),ylab=quote(tau),
          main= quote(tau( tevCopula(rho) )), col = 2, lwd = 2)
    rect(-1,0,1,1, lty = 2, border = adjustcolor("black", 0.5))
}

test_36 <- function() {
    ## Do these data come from an extreme-value copula?
    set.seed(63)
    uG <- rCopula(100, gumbelCopula (3))
    uC <- rCopula(100, claytonCopula(3))
    ## these two take 21 sec on nb-mm4 (Intel Core i7-5600U @ 2.60GHz):
    evTestA(uG)
    evTestA(uC) # significant even though Clayton is *NOT* an extreme value copula

    ## These are fast:
    evTestA(uG, derivatives = "Cn")
    evTestA(uC, derivatives = "Cn") # small p-value even though Clayton is *NOT* an EV copula.
}

test_37 <- function() {
    ## Do these data come from an extreme-value copula?
    evTestC(rCopula(200, gumbelCopula(3)))
    evTestC(rCopula(200, claytonCopula(3)))

    ## Three-dimensional examples
    evTestC(rCopula(200, gumbelCopula(3, dim=3)))
    evTestC(rCopula(200, claytonCopula(3, dim=3)))
}

test_38 <- function() {
    set.seed(321)
    ## Do the data come from an extreme-value copula?
    evTestK(Ug <- rCopula(200, gumbelCopula(3))) # not significant => yes, EV
        dim(Uc <- rCopula(200, claytonCopula(3)))
    ## Clayton:                       tests are highly significant => no, not EV
    (K1 <- evTestK(Uc))
    (K2 <- evTestK(Uc, method = "asymptotic"))

    system.time(print(K3 <- evTestK(Uc, method = "jackknife")))
    ## slower: 1.06 sec (2015 intel core i7)
}

test_39 <- function() {
    ## Data from an exchangeable left-tail decreasing copulas
    exchEVTest(rCopula(200,  gumbelCopula(3)))
    exchEVTest(rCopula(200, claytonCopula(3)))

    ## An asymmetric Khoudraji-Gumbel-Hougaard copula
    kc <- khoudrajiCopula(copula1 = indepCopula(),
                          copula2 = gumbelCopula(4),
                          shapes = c(0.4, 0.95))
    exchEVTest(rCopula(200, kc))
}

test_40 <- function() {
    ## Data from an exchangeable copulas
    exchTest(rCopula(200,  gumbelCopula(3)))
    exchTest(rCopula(200, claytonCopula(3)))

    ## An asymmetric Khoudraji-Clayton copula
    kc <- khoudrajiCopula(copula1 = indepCopula(),
                          copula2 = claytonCopula(6),
                          shapes = c(0.4, 0.95))
    exchTest(rCopula(200, kc))
}

test_41 <- function() {
    ## length(param) = #{parameters}  for  d-dimensional  FGM copula:
    d <- 2:10; rbind(d, npar = 2^d - d - 1)
    ## d       2    3    4    5    6    7    8    9   10
    ## npar    1    4   11   26   57  120  247  502 1013

    ## a bivariate example
    fgm.cop <- fgmCopula(1)
    x <- rCopula(1000, fgm.cop)
    cor(x, method = "kendall")
    tau(fgm.cop)
    cor(x, method = "spearman")
    rho(fgm.cop)
    persp  (fgm.cop, dCopula)
    contour(fgm.cop, dCopula)

    ## a trivariate example with wrong parameter values
    try(
     fgm2.cop <- fgmCopula(c(1,1,1,1), dim = 3)
    ) # Error: "Bad vector of parameters"

    ## a trivariate example with satisfactory parameter values
    fgm2.cop <- fgmCopula(c(.2,-.2,-.4,.6), dim = 3)
    fgm2.cop
}

test_42 <- function() {
    ## Lower bound  W : -------------------------

    try(W <- lowfhCopula(dim = 3)) # lower bound is *not* a copula for dim > 2
    W <- lowfhCopula()
    wireframe2(W, FUN = pCopula)
    plot(W, n=100) # perfect anti-correlation ( rho = tau = -1 )

    ## Upper bound  M : -------------------------

    wireframe2(upfhCopula(dim = 2), pCopula)
    M <- upfhCopula(dim = 3)
    set.seed(271)
    splom2(M, n = 100) # "random" data: all perfectly correlated
}

test_43 <- function() {
    (Xtras <- copula:::doExtras()) # determine whether examples will be extra (long)
    n <- if(Xtras) 200 else 64 # sample size

    ## A Gumbel copula
    set.seed(7) # for reproducibility
    gumbel.cop <- gumbelCopula(3, dim=2)
    x <- rCopula(n, gumbel.cop) # "true" observations (simulated)
    u <- pobs(x)                # pseudo-observations
    ## Inverting Kendall's tau
    fit.tau <- fitCopula(gumbelCopula(), u, method="itau")
    fit.tau
    confint(fit.tau) # works fine !
    confint(fit.tau, level = 0.98)
    summary(fit.tau) # a bit more, notably "Std. Error"s
    coef(fit.tau)# named vector
    coef(fit.tau, SE = TRUE)# matrix

    ## Inverting Spearman's rho
    fit.rho <- fitCopula(gumbelCopula(), u, method="irho")
    summary(fit.rho)
    ## Maximum pseudo-likelihood
    fit.mpl <- fitCopula(gumbelCopula(), u, method="mpl")
    fit.mpl
    ## Maximum likelihood -- use 'x', not 'u' ! --
    fit.ml <- fitCopula(gumbelCopula(), x, method="ml")
    summary(fit.ml) # now prints a bit more than simple 'fit.ml'
    ## ... and what's the log likelihood (in two different ways):
    (ll. <- logLik(fit.ml))
    stopifnot(all.equal(as.numeric(ll.),
                loglikCopula(coef(fit.ml), u=x, copula=gumbel.cop)))

    ## A Gauss/normal copula

    ## With multiple/*un*constrained parameters
    set.seed(6) # for reproducibility
    normal.cop <- normalCopula(c(0.6, 0.36, 0.6), dim=3, dispstr="un")
    x <- rCopula(n, normal.cop) # "true" observations (simulated)
    u <- pobs(x)                # pseudo-observations
    ## Inverting Kendall's tau
    fit.tau <- fitCopula(normalCopula(dim=3, dispstr="un"), u, method="itau")
    fit.tau

    if(Xtras) withAutoprint({ ## needs time
      ## Inverting Spearman's rho
      fit.rho <- fitCopula(normalCopula(dim=3, dispstr="un"), u, method="irho")
      fit.rho
      ## Maximum pseudo-likelihood
      fit.mpl <- fitCopula(normalCopula(dim=3, dispstr="un"), u, method="mpl")
      summary(fit.mpl)
      coef(fit.mpl) # named vector
      coef(fit.mpl, SE = TRUE) # the matrix, with SE
    }) #
    ## Maximum likelihood (use 'x', not 'u' !)
    fit.ml <- fitCopula(normalCopula(dim=3, dispstr="un"), x, method="ml", traceOpt=TRUE)
    summary(fit.ml)
    confint(fit.ml)
    confint(fit.ml, level = 0.999) # clearly non-0

    ## Fix some of the parameters
    param <- c(.6, .3, NA_real_)
    attr(param, "fixed") <- c(TRUE, FALSE, FALSE)
    ncp <- normalCopula(param = param, dim = 3, dispstr = "un")
    fixedParam(ncp) <- c(TRUE, TRUE, FALSE)
    ## 'traceOpt = 5': showing every 5-th log likelihood evaluation:
    summary(Fxf.mpl <- fitCopula(ncp, u, method = "mpl", traceOpt = 5))
    Fxf.mpl@copula # reminding of the fixed param. values

    ## With dispstr = "toep" :
    normal.cop.toep <- normalCopula(c(0, 0), dim=3, dispstr="toep")
    ## Inverting Kendall's tau
    fit.tau <- fitCopula(normalCopula(dim=3, dispstr="toep"), u, method="itau")
    fit.tau
    ## Inverting Spearman's rho
    fit.rho <- fitCopula(normalCopula(dim=3, dispstr="toep"), u, method="irho")
    summary(fit.rho)
    ## Maximum pseudo-likelihood
    fit.mpl <- fitCopula(normalCopula(dim=3, dispstr="toep"), u, method="mpl")
    fit.mpl
    ## Maximum likelihood (use 'x', not 'u' !)
    fit.ml <- fitCopula(normalCopula(dim=3, dispstr="toep"), x, method="ml")
    summary(fit.ml)

    ## With dispstr = "ar1"
    normal.cop.ar1 <- normalCopula(c(0), dim=3, dispstr="ar1")
    ## Inverting Kendall's tau
    summary(fit.tau <- fitCopula(normalCopula(dim=3, dispstr="ar1"), u, method="itau"))
    ## Inverting Spearman's rho
    summary(fit.rho <- fitCopula(normalCopula(dim=3, dispstr="ar1"), u, method="irho"))
    ## Maximum pseudo-likelihood
    summary(fit.mpl <- fitCopula(normalCopula(dim=3, dispstr="ar1"), u, method="mpl"))
    ## Maximum likelihood (use 'x', not 'u' !)
    fit.ml <- fitCopula(normalCopula(dim=3, dispstr="ar1"), x, method="ml")
    summary(fit.ml)

    ## A t copula with variable df (df.fixed=FALSE)
    (tCop <- tCopula(c(0.2,0.4,0.6), dim=3, dispstr="un", df=5))
    set.seed(101)
    x <- rCopula(n, tCop) # "true" observations (simulated)
    ## Maximum likelihood (start = (rho[1:3], df))
    summary(tc.ml <- fitCopula(tCopula(dim=3, dispstr="un"), x, method="ml",
                               start = c(0,0,0, 10)))
    ## Maximum pseudo-likelihood (the asymptotic variance cannot be estimated)
    u <- pobs(x)          # pseudo-observations
    tc.mpl <- fitCopula(tCopula(dim=3, dispstr="un"),
                         u, method="mpl", estimate.variance=FALSE,
                         start= c(0,0,0, 10))
    summary(tc.mpl)
}

test_44 <- function() {
    n <- 10000 # sample size
    p <- 0.01 # cut-off

    ## Bivariate case
    d <- 2
    cop <- claytonCopula(2, dim = d)
    set.seed(271)
    U <- rCopula(n, copula = cop) # generate observations (unrealistic)
    (lam.true <- lambda(cop)) # true tail-dependence coefficients lambda
    (lam.C <- c(lower = fitLambda(U, p = p)[2,1],
                upper = fitLambda(U, p = p, lower.tail = FALSE)[2,1])) # estimate lambdas
    ## => pretty good
    U. <- pobs(U) # pseudo-observations (realistic)
    (lam.C. <- c(lower = fitLambda(U., p = p)[2,1],
                 upper = fitLambda(U., p = p, lower.tail = FALSE)[2,1])) # estimate lambdas
    ## => The pseudo-observations do have an effect...

    ## Higher-dimensional case
    d <- 5
    cop <- claytonCopula(2, dim = d)
    set.seed(271)
    U <- rCopula(n, copula = cop) # generate observations (unrealistic)
    (lam.true <- lambda(cop)) # true tail-dependence coefficients lambda
    (Lam.C <- list(lower = fitLambda(U, p = p),
                   upper = fitLambda(U, p = p, lower.tail = FALSE))) # estimate Lambdas
    ## => Not too good
    U. <- pobs(U) # pseudo-observations (realistic)
    (Lam.C. <- list(lower = fitLambda(U., p = p),
                    upper = fitLambda(U., p = p, lower.tail = FALSE))) # estimate Lambdas
    ## => Performance not too great here in either case
}

test_45 <- function() {
    G3 <- gumbelCopula(3, dim=2)
    gMvd2  <- mvdc(G3, c("exp","exp"),
                   param = list(list(rate=2), list(rate=4)))
    ## with identical margins:
    gMvd.I <- mvdc(G3, "exp",
                   param = list(rate=3), marginsIdentical=TRUE)

    (Xtras <- copula:::doExtras()) # determine whether examples will be extra (long)
    n <- if(Xtras) 10000 else 200 # sample size (realistic vs short for example)

    set.seed(11)
    x <- rMvdc(n, gMvd2)
    ## Default:     hideWarnings = FALSE .. i.e. show warnings here
    fit2 <- fitMvdc(x, gMvd2, start = c(1,1, 2))
    fit2
    confint(fit2)
    summary(fit2) # slightly more
    ## The estimated, asymptotic var-cov matrix [was used for confint()]:
    vcov(fit2)

    ## with even more output for the "identical margin" case:
    fitI <- fitMvdc(x, gMvd.I, start = c(3, 2),
                    optim.control=list(trace= TRUE, REPORT= 2))
    summary(fitI)
    coef(fitI, SE = TRUE)
    stopifnot(is.matrix(coef(fitI, SE = TRUE)),
              is.matrix(print( confint(fitI) )) )

    ## a wrong starting value can already be *the* problem:
    f2 <- try(fitMvdc(x, gMvd.I, start = c(1, 1),
               optim.control=list(trace= TRUE, REPORT= 2)))
    ##--> Error in optim( ... ) : non-finite finite-difference value [2]

    ##==> "Solution" :  Using a more robust (but slower) optim() method:
    fI.2 <- fitMvdc(x, gMvd.I, start = c(1, 1), method = "Nelder",
                    optim.control=list(trace= TRUE))
    fI.2
}

test_46 <- function() {
    nc1 <- normalCopula(dim = 3, fixParam(c(.6,.3,.2), c(TRUE, FALSE,FALSE)),
                        dispstr = "un")
    nc1
    nc13 <- nc12 <- nc1
    fixedParam(nc12) <- c(TRUE, TRUE, FALSE) ; nc12
    fixedParam(nc13) <- c(TRUE, FALSE, TRUE) ; nc13
    set.seed(17); x <- rCopula(100, nc1)
    summary(f.13 <- fitCopula(nc13, x, method = "ml"))
    f.13@copula  # 'rho.2' is estimated; the others kept fixed

    ## Setting to 'FALSE' (removes the "fixed" parts completely):
    nc0 <- nc13; fixedParam(nc0) <- FALSE
    nc0
    stopifnot(is.null(attributes(nc0@parameters)))
}

test_47 <- function() {
    data(gasoil)
    ## Log Scaled  Oil & Gas Prices :
    lattice :: xyplot(oil + gas ~ date, data = gasoil, auto.key=TRUE,
                      type = c("l","r"),
                      scales=list(y = list(log = TRUE), equispaced.log = FALSE))
}

test_48 <- function() {
    ## List the available methods (and their definitions):
    showMethods("A")
    showMethods("iPsi", incl=TRUE)
}

test_49 <- function() {
    getAcop("Gumbel")

    ## different ways of getting the same "acopula" family object:
    stopifnot(## Joe (three ways):
              identical(getAcop("J"), getAcop("Joe")),
              identical(getAcop("J"), copJoe),
              ## Frank (yet another two different ways):
              identical(getAcop(frankCopula()), copFrank),
              identical(getAcop("frankCopula"), copFrank))

    stopifnot(
      identical(getAname(claytonCopula()), getAname("C")),
      identical(getAname(copClayton), "Clayton"), identical(getAname("J"), "Joe"),
      identical(getAname(amhCopula(), TRUE), "copAMH"),
      identical(getAname(joeCopula(), TRUE), "copJoe")
    )

    .ac.shortNames
    .ac.longNames
    .ac.objNames
    .ac.classNames
}

test_50 <- function() {
     # TODO !
}

test_51 <- function() {
    showMethods("getTheta")

    getTheta(setTheta(copClayton, 0.5)) # is 0.5
}

test_52 <- function() {
    ## demo(gof_graph)
}

test_53 <- function() {
    ## The following example is available in batch through
    ## demo(gofCopula)

    n <- 200; N <- 1000 # realistic (but too large for interactive use)
    n <-  60; N <-  200 # (time (and tree !) saving ...)

    ## A two-dimensional data example ----------------------------------
    set.seed(271)
    x <- rCopula(n, claytonCopula(3))

    ## Does the Gumbel family seem to be a good choice (statistic "Sn")?
    gofCopula(gumbelCopula(), x, N=N)
    ## With "SnC", really s..l..o..w.. --- with "SnB", *EVEN* slower
    gofCopula(gumbelCopula(), x, N=N, method = "SnC", trafo.method = "cCopula")
    ## What about the Clayton family?
    gofCopula(claytonCopula(), x, N=N)

    ## Similar with a different estimation method
    gofCopula(gumbelCopula (), x, N=N, estim.method="itau")
    gofCopula(claytonCopula(), x, N=N, estim.method="itau")


    ## A three-dimensional example  ------------------------------------
    x <- rCopula(n, tCopula(c(0.5, 0.6, 0.7), dim = 3, dispstr = "un"))

    ## Does the Gumbel family seem to be a good choice?
    g.copula <- gumbelCopula(dim = 3)
    gofCopula(g.copula, x, N=N)
    ## What about the t copula?
    t.copula <- tCopula(dim = 3, dispstr = "un", df.fixed = TRUE)
    if(FALSE) ## this is *VERY* slow currently
      gofCopula(t.copula, x, N=N)

    ## The same with a different estimation method
    gofCopula(g.copula, x, N=N, estim.method="itau")
    if(FALSE) # still really slow
      gofCopula(t.copula, x, N=N, estim.method="itau")

    ## The same using the multiplier approach
    gofCopula(g.copula, x, N=N, simulation="mult")
    gofCopula(t.copula, x, N=N, simulation="mult")
    if(FALSE) # no yet possible
        gofCopula(t.copula, x, N=N, simulation="mult", estim.method="itau")
}

test_54 <- function() {
    n <- 100; N <- 1000 # realistic (but too large currently for CRAN checks)
    n <-  60; N <-  200 # (time (and tree !) saving ...)
    x <- rCopula(n, claytonCopula(3))


    ## Does the Gumbel family seem to be a good choice?
    gofEVCopula(gumbelCopula(), x, N=N)


    ## The same with different (and cheaper) estimation methods:
    gofEVCopula(gumbelCopula(), x, N=N, method="itau")
    gofEVCopula(gumbelCopula(), x, N=N, method="irho")


    ## The same with different extreme-value copulas
    gofEVCopula(galambosCopula(), x, N=N)
    gofEVCopula(galambosCopula(), x, N=N, method="itau")
    gofEVCopula(galambosCopula(), x, N=N, method="irho")

    gofEVCopula(huslerReissCopula(), x, N=N)
    gofEVCopula(huslerReissCopula(), x, N=N, method="itau")
    gofEVCopula(huslerReissCopula(), x, N=N, method="irho")

    gofEVCopula(tevCopula(df.fixed=TRUE), x, N=N)
    gofEVCopula(tevCopula(df.fixed=TRUE), x, N=N, method="itau")
    gofEVCopula(tevCopula(df.fixed=TRUE), x, N=N, method="irho")
}

test_55 <- function() {
    n <- 100
    d <- 2
    set.seed(271)
    x <- matrix(runif(n * d), ncol = d)
    y <- matrix(runif(n * d), ncol = d)
    res <- gofMMDtest(x, y)
    res$p.value
}

test_56 <- function() {
    ## generate data on the unit sphere
    n <- 360
    d <- 5
    set.seed(1)
    x <- matrix(rnorm(n*d), ncol=d)
    U <- x/sqrt(rowSums(x^2))

    ## compute the test statistics B_k, k in {1,..,d-1}
    Bmat <- gofBTstat(U)

    ## (graphically) check if Bmat[,k] follows a Beta(k/2, (d-k)/2) distribution
    qqp <- function(k, Bmat) {
        d <- ncol(Bmat)+1L
        tit <- substitute(plain("Beta")(.A.,.B.)~~ bold("Q-Q Plot"),
                          list(.A. = k/2, .B. = (d-k)/2))
        qqplot2(Bmat[,k], qF=function(p) qbeta(p, shape1=k/2, shape2=(d-k)/2),
                main.args=list(text=tit, side=3, cex=1.3, line=1.1, xpd=NA))
    }
    qqp(1, Bmat=Bmat) # k=1
    qqp(3, Bmat=Bmat) # k=3
}

test_57 <- function() {
    ## Generate data
    cop <- archmCopula("Gumbel", param=iTau(gumbelCopula(), 0.5), dim=5)
    set.seed(1)
    U <- rCopula(1000, cop)

    ## Compute Sn (as is done in a parametric bootstrap, for example)
    Uhat <- pobs(U) # pseudo-observations
    u <- cCopula(Uhat, copula = cop) # Rosenblatt transformed data (with correct copula)
    gofTstat(u, method = "Sn", copula = cop) # compute test statistic Sn; requires copula argument
}

test_58 <- function() {
    ## Sample and build pseudo-observations (what we normally have available)
    ## of a Clayton copula
    tau <- 0.5
    theta <- iTau(claytonCopula(), tau = tau)
    d <- 5
    cc <- claytonCopula(theta, dim = d)
    set.seed(271)
    n <- 1000
    U <- rCopula(n, copula = cc)
    X <- qnorm(U) # X now follows a meta-Gumbel model with N(0,1) marginals
    U <- pobs(X) # build pseudo-observations

    ## Graphically check if the data comes from a meta-Clayton model
    ## with the transformation of Hering and Hofert (2014):
    U.H <- htrafo(U, copula = cc) # transform the data
    splom2(U.H, cex = 0.2) # looks good

    ## The same for an 'outer_nacopula' object
    cc. <- onacopulaL("Clayton", list(theta, 1:d))
    U.H. <- htrafo(U, copula = cc.)
    splom2(U.H., cex = 0.2) # looks good

    ## What about a meta-Gumbel model?
    ## The parameter is chosen such that Kendall's tau equals (the same) tau
    gc <- gumbelCopula(iTau(gumbelCopula(), tau = tau), dim = d)

    ## Plot of the transformed data (Hering and Hofert (2014)) to see the
    ## deviations from uniformity
    U.H.. <- htrafo(U, copula = gc)
    splom2(U.H.., cex = 0.2) # deviations visible
}

test_59 <- function() {
    indep.cop <- indepCopula(3)
    x <- rCopula(10, indep.cop)
    dCopula(x, indep.cop)
    persp(indepCopula(), pCopula)
}

test_60 <- function() {
    getClass("indepCopula")
}

test_61 <- function() {
    ## Consider the following example taken from
    ## Genest and Remillard (2004), p 352:

    set.seed(2004)
    x <- matrix(rnorm(500),100,5)
    x[,1] <- abs(x[,1]) * sign(x[,2] * x[,3])
    x[,5] <- x[,4]/2 + sqrt(3) * x[,5]/2

    ## In order to test for independence "within" x, the first step consists
    ## in simulating the distribution of the test statistics under
    ## independence for the same sample size and dimension,
    ## i.e. n=100 and p=5. As we are going to consider all the subsets of
    ## {1,...,5} whose cardinality is between 2 and 5, we set p=m=5.

    ## For a realistic N = 1000 (default), this takes a few seconds:
    N. <- if(copula:::doExtras()) 1000 else 120
    N.
    system.time(d <- indepTestSim(100, 5, N = N.))
    ## For N=1000,  2 seconds (lynne 2015)
    ## You could save 'd' for future use, via  saveRDS()

    ## The next step consists of performing the test itself (and print its results):
    (iTst <- indepTest(x,d))

    ## Display the dependogram with the details:
    dependogram(iTst, print=TRUE)

    ## We could have tested for a weaker form of independence, for instance,
    ## by only computing statistics for subsets whose cardinality is between 2
    ## and 3. Consider for instance the following data:
    y <- matrix(runif(500),100,5)
    ## and perform the test:
    system.time( d <- indepTestSim(100,5,3, N=N.) )
    iTy <- indepTest(y,d)
    iTy
    dependogram(iTy, print=TRUE)
}

test_62 <- function() {
    ## Definition of the function:
    initOpt

    ## Generate some data:
    tau <- 0.25
    (theta <- copGumbel@iTau(tau)) # 4/3
    d <- 20
    (cop <- onacopulaL("Gumbel", list(theta,1:d)))

    set.seed(1)
    n <- 200
    U <- rnacopula(n, cop)

    ## Initial interval:
    initOpt("Gumbel") # contains theta

    ## Initial values:
    initOpt("Gumbel", interval=FALSE, u=U) # 1.3195
    initOpt("Gumbel", interval=FALSE, u=U, method="tau.mean") # 1.2844
}

test_63 <- function() {
    interval("[0, 1)")

    ## Two ways to specify open interval borders:
    identical(interval("]-1,1["),
              interval("(-1,1)"))

    ## infinite :
    interval("[0, Inf)")

    ## arithmetic with scalars works:
    4 + 2 * interval("[0, 1.5)") # ->  [4, 7)

    ## str() to look at internals:
    str( interval("[1.2, 7]") )
}

test_64 <- function() {
    -1:2 %in% interval("(0, Inf)")
    ## 0 is *not* inside
}

test_65 <- function() {
    ## A bivariate Khoudraji-Clayton copula
    kc <- khoudrajiCopula(copula2 = claytonCopula(6),
                          shapes = c(0.4, 0.95))
    class(kc) # "kh..._Biv_Copula"
    kc
    contour(kc, dCopula, nlevels = 20, main = "dCopula(<khoudrajiBivCopula>)")

    ## A Khoudraji-Clayton copula with second shape parameter fixed
    kcf <- khoudrajiCopula(copula2 = claytonCopula(6),
                           shapes = fixParam(c(0.4, 0.95), c(FALSE, TRUE)))
    kcf. <- setTheta(kcf, c(3, 0.2)) # (change *free* param's only)
    validObject(kcf) & validObject(kcf.)

    ## A "nested" Khoudraji bivariate copula
    kgkcf <- khoudrajiCopula(copula1 = gumbelCopula(3),
                             copula2 = kcf,
                             shapes = c(0.7, 0.25))
    kgkcf # -> 6 parameters (1 of 6 is 'fixed')
    contour(kgkcf, dCopula, nlevels = 20,
            main = "dCopula(<khoudrajiBivC.(nested)>)")

    (Xtras <- copula:::doExtras()) # determine whether examples will be extra (long)
    n <- if(Xtras) 300 else 64 # sample size (realistic vs short for example)

    u <- rCopula(n, kc)
    plot(u)

    ## For likelihood (or fitting), specify the "free" (non-fixed) param's:
    ##           C1:  C2c C2s1    sh1  sh2
    loglikCopula(c(3,   6, 0.4,   0.7, 0.25),
                 u = u, copula = kgkcf)

    ## Fitting takes time (using numerical differentiation) and may be difficult:

    ## Starting values are required for all parameters
    f.IC <- fitCopula(khoudrajiCopula(copula2 = claytonCopula()),
                      start = c(1.1, 0.5, 0.5), data = pobs(u),
                      optim.method = "Nelder-Mead")
    summary(f.IC)
    confint(f.IC) # (only interesting for reasonable sample size)

    ## Because of time,  don't run these by default :

    ## Second shape parameter fixed to 0.95
    kcf2 <- khoudrajiCopula(copula2 = claytonCopula(),
                            shapes = fixParam(c(NA_real_, 0.95), c(FALSE, TRUE)))
    system.time(
    f.ICf <- fitCopula(kcf2, start = c(1.1, 0.5), data = pobs(u),
                       optim.method = "Nelder-Mead")
    ) # ~ 7-8 sec
    confint(f.ICf) # !
    coef(f.ICf, SE=TRUE)

    ## With a different optimization method
    system.time(
    f.IC2 <- fitCopula(kcf2, start = c(1.1, 0.5), data = pobs(u),
                       optim.method = "BFGS")
    )
    printCoefmat(coef(f.IC2, SE=TRUE), digits = 3) # w/o unuseful extra digits


    if(Xtras >= 2) { # really S..L..O..W... --------

    ## GOF example
    optim.method <- "Nelder-Mead" #try "BFGS" as well
    gofCopula(kcf2, x = u, start = c(1.1, 0.5), optim.method = optim.method)
    gofCopula(kcf2, x = u, start = c(1.1, 0.5), optim.method = optim.method,
              sim = "mult")
    ## The goodness-of-fit tests should hold their level
    ## but this would need to be tested

    ## Another example under the alternative
    u <- rCopula(n, gumbelCopula(4))
    gofCopula(kcf2, x = u, start = c(1.1, 0.5), optim.method = optim.method)
    gofCopula(kcf2, x = u, start = c(1.1, 0.5), optim.method = optim.method,
              sim = "mult")

    }## ------ end { really slow gofC*() } --------

    ## Higher-dimensional constructions

    ## A three dimensional Khoudraji-Clayton copula
    kcd3 <- khoudrajiCopula(copula1 = indepCopula(dim=3),
                            copula2 = claytonCopula(6, dim=3),
                            shapes = c(0.4, 0.95, 0.95))

    n <- if(Xtras) 1000 else 100 # sample size (realistic vs short for example)
    u <- rCopula(n, kcd3)
    splom2(u)
    v <- matrix(runif(15), 5, 3)
    dCopula(v, kcd3)

    ## A four dimensional Khoudraji-Normal copula
    knd4 <- khoudrajiCopula(copula1 = indepCopula(dim=4),
                            copula2 = normalCopula(.9, dim=4),
                            shapes = c(0.4, 0.95, 0.95, 0.95))
    knd4
    stopifnot(class(knd4) == "khoudrajiCopula")
    u <- rCopula(n, knd4)
    splom2(u)
    ## TODO :
    ## dCopula(v, knd4) ## not implemented
}

test_66 <- function() {
    showClass("khoudrajiCopula")# two subclasses

    ## all methods applicable to these subclasses:
    (meths <- sapply(names(getClass("khoudrajiCopula")@subclasses),
                     function(CL) methods(class = CL),
                     simplify=FALSE))
}

test_67 <- function() {
    a <- 2^seq(-58,10, length = 256)
    fExpr <- expression(
              log(1 - exp(-a)),
              log(-expm1(-a)),
              log1p(-exp(-a)),
              log1mexp(a))
    names(fExpr) <- c("DEF", "expm1", "log1p", "F")
    str(fa <- do.call(cbind, as.list(fExpr)))
    head(fa)# expm1() works here
    tail(fa)# log1p() works here

    ## graphically:
    lwd <- 1.5*(5:2); col <- adjustcolor(1:4, 0.4)
    op <- par(mfcol=c(1,2), mgp = c(1.25, .6, 0), mar = .1+c(3,2,1,1))
      matplot(a, fa, type = "l", log = "x", col=col, lwd=lwd)
      legend("topleft", fExpr, col=col, lwd=lwd, lty=1:4, bty="n")
      # expm1() & log1mexp() work here

      matplot(a, -fa, type = "l", log = "xy", col=col, lwd=lwd)
      legend("left", paste("-",fExpr), col=col, lwd=lwd, lty=1:4, bty="n")
      # log1p() & log1mexp() work here
    par(op)

    curve(log1pexp, -10, 10, asp=1)
    abline(0,1, h=0,v=0, lty=3, col="gray")

    ## Cutoff c1 for log1pexp() -- not often "needed":
    curve(log1p(exp(x)) - log1pexp(x), 16, 20, n=2049)
    ## need for *some* cutoff:
    x <- seq(700, 720, by=2)
    cbind(x, log1p(exp(x)), log1pexp(x))

    ## Cutoff c2 for log1pexp():
    curve((x+exp(-x)) - x, 20, 40, n=1025)
    curve((x+exp(-x)) - x, 33.1, 33.5, n=1025)
}

test_68 <- function() {
    data(loss)
}

test_69 <- function() {
    tc <- tCopula(8:2 / 10, dim = 8, dispstr = "toep")
    margCopula(tc, c(TRUE, TRUE, FALSE, TRUE, FALSE, FALSE, TRUE, FALSE))

    nc <- normalCopula(.8, dim = 8, dispstr = "ar1")
    mnc <- margCopula(nc, c(TRUE, TRUE, FALSE, TRUE, FALSE, FALSE, TRUE, FALSE))
    mnc7 <- margCopula(nc, (1:8) != 1)
    stopifnot(dim(nc) == 8, dim(mnc) == 4, dim(mnc7) == 7)

    gc <- gumbelCopula(2, dim = 8)
    margCopula(gc, c(TRUE, TRUE, TRUE, FALSE, FALSE, FALSE, FALSE, FALSE))
}

test_70 <- function() {
    curve(sinc, -15,25); abline(h=0,v=0, lty=2)
    curve(A..Z(x, 0.25), xlim = c(-4,4),
          main = "Zolotarev's function A(x) ^ 1-alpha")
}

test_71 <- function() {
    ## display the two simple definitions:
    p2P
    P2p

    param <- (2:7)/10
    tC <- tCopula(param, dim = 4, dispstr = "un", df = 3)
    ## consistency of the three functions :
    P <- p2P(param) # (using the default 'd')
    stopifnot(identical(param, P2p(P)),
    	  identical(P, getSigma(tC)))

    ## Toeplitz case:
    (tCt <- tCopula((2:6)/10, dim = 6, disp = "toep"))
    (rhoP <- tCt@getRho(tCt))
    stopifnot(identical(getSigma (tCt),
    		    toeplitz (c(1, rhoP))))

    ## "AR1" case:
    nC.7 <- normalCopula(0.8, dim = 7, dispstr = "ar1")
    (Sar1.7 <- getSigma(nC.7))
    0.8^(0:(7-1)) #  1  0.8  0.64  0.512 ..
    stopifnot(all.equal(Sar1.7, toeplitz(0.8^(0:(7-1)))))
}

test_72 <- function() {

    mC <- mixCopula(list(gumbelCopula(2.5, dim=3),
                         claytonCopula(pi, dim=3),
                         tCopula(0.7, dim=3)),
                    c(2,2,4)/8)
    mC
    stopifnot(dim(mC) == 3)

    set.seed(17)
    uM <- rCopula(600, mC)
    splom2(uM, main = "mixCopula( (gumbel, clayton, t-Cop) )")
    d.uM <- dCopula(uM, mC)
    p.uM <- pCopula(uM, mC)

    ## mix a Gumbel with a rotated Gumbel (with equal weights 1/2):
    mGG <- mixCopula(list(gumbelCopula(2), rotCopula(gumbelCopula(1.5))))
    rho(mGG)   # 0.57886
    lambda(mGG)# both lower and upper tail dependency

    loglikCopula(c(2.5, pi, rho.1=0.7, df = 4, w = c(2,2,4)/8),
                        u = uM, copula = mC)
    ## define (profiled) log-likelihood function of two arguments (df, rho) :
    ll.df <- Vectorize(function(df, rho)
                       loglikCopula(c(2.5, pi, rho.1=rho, df=df, w = c(2,2,4)/8),
                                    uM, mC))
    (df. <- 1/rev(seq(1/8, 1/2, length=21)))# in [2, 8] equidistant in 1/. scale

    ll. <- ll.df(df., rho = (rh1 <- 0.7))
    plot(df., ll., type = "b", main = "loglikCopula((.,.,rho = 0.7, df, ..), u, <mixCopula>)")

    if(!exists("Xtras")) Xtras <- copula:::doExtras() ; cat("Xtras: ", Xtras,"\n")
    if (Xtras) withAutoprint({
      Rhos <- seq(0.55, 0.70, by = 0.01)
      ll.m <- matrix(NA, nrow=length(df.), ncol=length(Rhos))
      for(k in seq_along(Rhos)) ll.m[,k] <- ll.df(df., rho = Rhos[k])
      tit <- "loglikelihood(<tCop>, true param. for rest)"
      persp         (df., Rhos, ll.m, phi=30, theta = 50, ticktype="detailed", main = tit)
      filled.contour(df., Rhos, ll.m, xlab="df", ylab = "rho", main = tit)
    })

    ## fitCopula() example -----------------------------------------------------

    ## 1) with "fixed" weights :

    (mNt <- mixCopula(list(normalCopula(0.95), tCopula(-0.7)), w = c(1, 2) / 3))
    set.seed(1452) ; U <- pobs(rCopula(1000, mNt))
    (m1 <- mixCopula(list(normalCopula(), tCopula()), w = mNt@w))

    getTheta(m1, freeOnly = TRUE, attr = TRUE)
    getTheta(m1, named=TRUE)
    isFree(m1) # all of them; --> now fix the weights :
    fixedParam(m1) <- fx <- c(FALSE, FALSE, FALSE, TRUE, TRUE)
    stopifnot(identical(isFree(m1), !fx))

    if(Xtras) withAutoprint({ ## time
      system.time( # ~ 16 sec (nb-mm4) :
        fit <- fitCopula(m1, start = c(0, 0, 10), data = U)
      )
      fit
      summary(fit) #-> incl  'Std.Error' (which seems small for rho1 !)
    })

    ## 2) with "free" weights (possible since copula 1.0-0):

    (mNt2 <- mixCopula(list(normalCopula(0.9), tCopula(-0.8)), w = c(1, 3) / 4))
    set.seed(1959) ; U2 <- pobs(rCopula(2000, mNt2))
    if(Xtras) withAutoprint({ ## time
      m2 <- mixCopula(list(normalCopula(), tCopula()), w = mNt@w)
      system.time( # ~ 13.5 sec (lynne) :
        f2 <- fitCopula(m2, start = c(0, 0, 10, c(1/2, 1/2)), data = U2)
      )
      f2
      summary(f2) # NA for 'Std. Error' as did *not* estimate.variance
      summary(f2, orig=FALSE) # default 'orig=TRUE': w-scale;  whereas
         coef(f2, orig=FALSE) # 'orig=FALSE' => shows 'l-scale' instead
    })
}

test_73 <- function() {
    showClass("mixCopula")
}

test_74 <- function() {
    alpha <- c(0.2, 0.7)
    MO <- moCopula(alpha)
    tau(MO) # 0.18
    lambda(MO)
    stopifnot(all.equal(lambda(MO),
                        c(lower = 0, upper = 0.2)))
    wireframe2  (MO, FUN = pCopula) # if you look carefully, you can see the kink
    contourplot2(MO, FUN = pCopula)
    set.seed(271)
    plot(rCopula(1000, MO))
}

test_75 <- function() {
    moCopula()@exprdist[["cdf"]] # a simple definition

    methods(class = "moCopula")
    contourplot2(moCopula(c(.1, .8)), pCopula, main= "moCopula((0.1, 0.8))")

    Xmo <- rCopula(5000, moCopula(c(.2, .5)))
    try( # gives an error, as there is no density (!):
    loglikCopula(c(.1, .2), Xmo, moCopula())
    )

    plot(moCopula(c(.9, .2)), n = 10000, xaxs="i", yaxs="i",
         # opaque color (for "density effect"):
         pch = 16, col = adjustcolor("black", 0.3))
}

test_76 <- function() {
    ## Consider the following example taken from
    ## Kojadinovic and Holmes (2008):

    n <- 100

    ## Generate data
    y <- matrix(rnorm(6*n),n,6)
    y[,1] <- y[,2]/2 + sqrt(3)/2*y[,1]
    y[,3] <- y[,4]/2 + sqrt(3)/2*y[,3]
    y[,5] <- y[,6]/2 + sqrt(3)/2*y[,5]

    nc <- normalCopula(0.3,dim=3)
    x <- cbind(y,rCopula(n, nc), rCopula(n, nc))

    x[,1] <- abs(x[,1]) * sign(x[,3] * x[,5])
    x[,2] <- abs(x[,2]) * sign(x[,3] * x[,5])
    x[,7] <- x[,7] + x[,10]
    x[,8] <- x[,8] + x[,11]
    x[,9] <- x[,9] + x[,12]

    ## Dimensions of the random vectors
    d <- c(2,2,2,3,3)

    ## Run the test
    (Xtras <- copula:::doExtras()) # or set  'N = ...' manually
    test <- multIndepTest(x, d, N = if(Xtras) 1000 else 150)
    test

    ## Display the dependogram
    dependogram(test, print=TRUE)
}

test_77 <- function() {
    ## A multivariate time series {minimal example for demo purposes}
    d <- 2
    n <- 100 # sample size *and* "burn-in" size
    param <- 0.25
    A <- matrix(param,d,d) # the bivariate AR(1)-matrix
    set.seed(17)
    ar <- matrix(rnorm(2*n * d), 2*n,d) # used as innovations
    for (i in 2:(2*n))
      ar[i,] <- A %*% ar[i-1,] + ar[i,]
    ## drop burn-in :
    x <- ar[(n+1):(2*n),]

    ## Run the test
    test <- multSerialIndepTest(x,3)
    test

    ## Display the dependogram
    dependogram(test,print=TRUE)
}

test_78 <- function() {
    ## takes about 7 seconds:% so we rather test a much smaller set in R CMD check

    nacFrail.time(10000, "Gumbel", taus=  c(0.05,(1:9)/10, 0.95))

    system.time(
    print( nacFrail.time( 100,  "Gumbel", taus = c(1, 6)/10) )
    )
}

test_79 <- function() {
    ## test with
    options(width=97)

    (mm <- rnacModel("Gumbel", d=15, pr.comp = 0.25, order="random"))
    stopifnot(isSymmetric(PT <- nacPairthetas(mm)))
    round(PT, 2)

    ## The tau's -- "Kendall's correlation matrix" :
    round(copGumbel@tau(PT), 2)

    ## do this several times:
    m1 <- rnacModel("Gumbel", d=15, pr.comp = 1/8, order="seq")
    stopifnot(isSymmetric(PT <- nacPairthetas(m1)))
    m1; PT

    m100 <- rnacModel("Gumbel", d= 100, pr.comp = 1/16, order="seq")
    system.time(PT <- nacPairthetas(m100))# how slow {non-optimal algorithm}?
    ##-- very fast, still!
    stopifnot(isSymmetric(PT))
    m100

    ## image(PT)# not ok -- want one color per theta
    nt <- length(th0 <- unique(sort(PT[!is.na(PT)])))
    th1 <- c(th0[1]/2, th0, 1.25*th0[nt])
    ths <- (th1[-1]+th1[-(nt+2)])/2
    image(log(PT), breaks = ths, col = heat.colors(nt))

    ## Nicer and easier:
    require(Matrix)
    image(as(log(PT),"Matrix"), main = "log( nacPairthetas( m100 ))",
          useAbs=FALSE, useRaster=TRUE, border=NA)
}

test_80 <- function() {
    ## nacopula and outer_nacopula class information
    showClass("nacopula")
    showClass("outer_nacopula")

    ## Construct a three-dimensional nested Frank copula with parameters
    ## chosen such that the Kendall's tau of the respective bivariate margins
    ## are 0.2 and 0.5.
    theta0 <- copFrank@iTau(.2)
    theta1 <- copFrank@iTau(.5)
    C3 <- onacopula("F", C(theta0, 1, C(theta1, c(2,3))))

    C3 # displaying it, using show(C3); see help(printNacopula)

    ## What is the dimension of this copula?
    dim(C3)

    ## What are the indices of direct components of the root copula?
    C3@comp

    ## How does the list of child nested Archimedean copulas look like?
    C3@childCops # only one child for this copula, components 2, 3
}

test_81 <- function() {
    F2 <- onacopula("F", C(1.9, 1, C(4.5, c(2,3))))
    F2
    F3 <- onacopula("Clayton", C(1.5, 3:1,
                                 C(2.5, 4:5,
                                   C(15, 9:6))))
    nesdepth(F2) # 2
    nesdepth(F3) # 3
}

test_82 <- function() {
    ## Construct a ten-dimensional Joe copula with parameter such that
    ## Kendall's tau equals 0.5
    theta <- copJoe@iTau(0.5)
    C10 <- onacopula("J",C(theta,1:10))

    ## Equivalent construction with onacopulaL():
    C10. <- onacopulaL("J",list(theta,1:10))
    stopifnot(identical(C10, C10.),
              identical(nac2list(C10), list(theta, 1:10)))

    ## Construct a three-dimensional nested Gumbel copula with parameters
    ## such that Kendall's tau of the respective bivariate margins are 0.2
    ## and 0.5.
    theta0 <- copGumbel@iTau(.2)
    theta1 <- copGumbel@iTau(.5)
    C3 <- onacopula("G", C(theta0, 1, C(theta1, c(2,3))))

    ## Equivalent construction with onacopulaL():
    str(NAlis <- list(theta0, 1, list(list(theta1, c(2,3)))))
    C3. <- onacopulaL("Gumbel", NAlis)
    stopifnot(identical(C3, C3.))

    ## An exercise: assume you got the copula specs as character string:
    na3spec <- "C(theta0, 1, C(theta1, c(2,3)))"
    na3call <- str2lang(na3spec) # == parse(text = na3spec)[[1]]
    C3.s <- onacopula("Gumbel", na3call)
    stopifnot(identical(C3, C3.s))

    ## Good error message if the component ("coordinate") indices are wrong
    ## or do not match:
    err <- try(onacopula("G", C(theta0, 2, C(theta1, c(3,2)))))

    ## Compute the probability of falling in [0,.01]^3 for this copula
    pCopula(rep(.01,3), C3)

    ## Compute the probability of falling in the cube [.99,1]^3
    prob(C3, rep(.99, 3), rep(1, 3))

    ## Construct a 6-dimensional, partially nested Gumbel copula of the form
    ## C_0(C_1(u_1, u_2), C_2(u_3, u_4), C_3(u_5, u_6))
    theta <- 2:5
    copG <- onacopulaL("Gumbel", list(theta[1], NULL, list(list(theta[2], c(1,2)),
                                                           list(theta[3], c(3,4)),
                                                           list(theta[4], c(5,6)))))
    set.seed(1)
    U <- rCopula(5000, copG)
    pairs(U, pch=".", gap=0, labels = as.expression( lapply(1:dim(copG),
                                         function(j) bquote(italic(U[.(j)]))) ))
}

test_83 <- function() {
    ## Construct an outer power Clayton copula with parameter thetabase such
    ## that Kendall's tau equals 0.2
    thetabase <- copClayton@iTau(0.2)
    opC <- opower(copClayton, thetabase) # "acopula" obj. (unspecified theta)

    ## Construct a 3d nested Archimedean copula based on opC, that is, a nested
    ## outer power Clayton copula.  The parameters theta are chosen such that
    ## Kendall's tau equals 0.4 and 0.6 for the outer and inner sector,
    ## respectively.
    theta0 <- opC@iTau(0.4)
    theta1 <- opC@iTau(0.6)
    opC3d <- onacopulaL(opC, list(theta0, 1, list(list(theta1, 2:3))))
    ## or opC3d <- onacopula(opC, C(theta0, 1, C(theta1, c(2,3))))

    ## Compute the corresponding lower and upper tail-dependence coefficients
    rbind(theta0 = c(
          lambdaL = opC@lambdaL(theta0),
          lambdaU = opC@lambdaU(theta0) # => opC3d has upper tail dependence
          ),
          theta1 = c(
          lambdaL = opC@lambdaL(theta1),
          lambdaU = opC@lambdaU(theta1) # => opC3d has upper tail dependence
          ))

    ## Sample opC3d
    n <- 1000
    U <- rnacopula(n, opC3d)

    ## Plot the generated vectors of random variates of the nested outer
    ## power Clayton copula.
    splom2(U)

    ## Construct such random variates "by hand"
    ## (1) draw V0 and V01
    V0  <- opC@ V0(n, theta0)
    V01 <- opC@V01(V0, theta0, theta1)
    ## (2) build U
    U <- cbind(
    opC@psi(rexp(n)/V0,  theta0),
    opC@psi(rexp(n)/V01, theta1),
    opC@psi(rexp(n)/V01, theta1))
}

test_84 <- function() {
    ## Create a 100 x 7 matrix of random variates from a t distribution
    ## with four degrees of freedom and plot the generated data
    U <- matrix(rt(700, df = 4), ncol = 7)
    pairs2(U, pch = ".")
}

test_85 <- function() {
    ## 2-dim example {d = 2} ===============
    ##
    ## "t" Copula with 22. degrees of freedom; and (pairwise) tau = 0.5
    nu <- 2.2 # degrees of freedom
    ## Define the multivariate distribution
    tCop <- ellipCopula("t", param=iTau(ellipCopula("t", df=nu), tau = 0.5),
                        dim=2, df=nu)
    set.seed(19)
    X <- qexp(rCopula(n = 400, tCop))

    ## H0 (wrongly): a Normal copula, with correct tau
    copH0 <- ellipCopula("normal", param=iTau(ellipCopula("normal"), tau = 0.5))

    ## create array of pairwise copH0-transformed data columns
    cu.u <- pairwiseCcop(pobs(X), copula = copH0)

    ## compute pairwise matrix of p-values and corresponding colors
    pwIT <- pairwiseIndepTest(cu.u, N=200) # (d,d)-matrix of test results

    round(pmat <- pviTest(pwIT), 3) # pick out p-values
    ## .286 and .077
    pairsRosenblatt(cu.u, pvalueMat= pmat)



    ### A shortened version of   demo(gof_graph) -------------------------------

    N <- 32 ## too small, for "testing"; realistically, use a larger one:
    if(FALSE)
    N <- 100

    ## 5d Gumbel copula ##########

    n <- 250 # sample size
    d <- 5 # dimension
    family <- "Gumbel" # copula family
    tau <- 0.5
    set.seed(17)
    ## define and sample the copula (= H0 copula), build pseudo-observations
    cop <- getAcop(family)
    th <- cop@iTau(tau) # correct parameter value
    copH0 <- onacopulaL(family, list(th, 1:d)) # define H0 copula
    U. <- pobs(rCopula(n, cop=copH0))

    ## create array of pairwise copH0-transformed data columns
    cu.u <- pairwiseCcop(U., copula = copH0)

    ## compute pairwise matrix of p-values and corresponding colors
    pwIT <- pairwiseIndepTest(cu.u, N=N, verbose=interactive()) # (d,d)-matrix of test results
    round(pmat <- pviTest(pwIT), 3) # pick out p-values
    ## Here (with seed=1):  no significant ones, smallest = 0.0603

    ## Plots ---------------------

    ## plain (too large plot symbols here)
    pairsRosenblatt(cu.u, pvalueMat=pmat, pch=".")

    ## with title, no subtitle
    pwRoto <- "Pairwise Rosenblatt transformed observations"
    pairsRosenblatt(cu.u, pvalueMat=pmat, pch=".", main=pwRoto, sub=NULL)

    ## two-line title including expressions, and centered
    title <- list(paste(pwRoto, "to test"),
                  substitute(italic(H[0]:C~~bold("is Gumbel with"~~tau==tau.)),
                             list(tau.=tau)))
    line.main <- c(4, 1.4)
    pairsRosenblatt(cu.u, pvalueMat=pmat, pch=".",
                    main=title, line.main=line.main, main.centered=TRUE)

    ## Q-Q plots -- can, in general, better detect outliers
    pairsRosenblatt(cu.u, pvalueMat=pmat, method="QQchisq", cex=0.2)
}

test_86 <- function() {
    persp(claytonCopula(2),   pCopula, main = "CDF of claytonCopula(2)")
    persp(  frankCopula(1.5), dCopula, main = "Density of frankCopula(1.5)")
    persp(  frankCopula(1.5), dCopula, main = "c_[frank(1.5)](.)", zlim = c(0,2))

    ## Examples with negative tau:
    (th1 <- iTau(amhCopula(), -0.1))
    persp(amhCopula(th1), dCopula)
    persp(amhCopula(th1), pCopula, ticktype = "simple") # no axis ticks
    persp(  frankCopula(iTau(  frankCopula(), -0.1)), dCopula)
    persp(claytonCopula(iTau(claytonCopula(), -0.1)), dCopula)
    ##
    cCop.2 <- function(u, copula, ...) cCopula(u, copula, ...)[,2]
    persp(    amhCopula(iTau(    amhCopula(), -0.1)), cCop.2, main="cCop(AMH...)[,2]")
    persp(  frankCopula(iTau(  frankCopula(), -0.1)), cCop.2, main="cCop(frankC)[,2]")
    ## and  Clayton  also looks "the same" ...

    ## MVDC Examples ------------------------------------
    mvNN <- mvdc(gumbelCopula(3), c("norm", "norm"),
              list(list(mean = 0, sd = 1), list(mean = 1)))
    persp(mvNN, dMvdc, xlim=c(-2, 2), ylim=c(-1, 3), main = "Density")
    persp(mvNN, pMvdc, xlim=c(-2, 2), ylim=c(-1, 3), main = "Cumulative Distr.")
}

test_87 <- function() {
    plackett.cop <- plackettCopula(param=2)
    lambda(plackett.cop) # 0 0 : no tail dependencies
    ## For really large param values (here, 1e20 and Inf are equivalent):
    set.seed(1); Xe20 <- rCopula(5000, plackettCopula(1e20))
    set.seed(1); Xinf <- rCopula(5000, plackettCopula(Inf))
    stopifnot(all.equal(Xe20, Xinf))
}

test_88 <- function() {
    str(plackettCopula())

    plackettCopula()@exprdist[["cdf"]]
    methods(class = "plackettCopula")
    contourplot2(plackettCopula(7), pCopula)
    wireframe2(plackettCopula(5), dCopula, main= "plackettCopula(5)")
}

test_89 <- function() {
    ## For 2-dim. 'copula' objects -------------------------
    ## Plot uses  n  compula samples
    n <- 1000 # sample size
    set.seed(271) # (reproducibility)
    plot(tCopula(-0.8, df = 1.25), n = n) # automatic main title!

    nu <- 3 # degrees of freedom
    tau <- 0.5 # Kendall's tau
    th <- iTau(tCopula(df = nu), tau) # corresponding parameter
    cop <- tCopula(th, df = nu) # define 2-d copula object
    plot(cop, n = n)

    ## For 2-dim. 'mvdc' objects ---------------------------
    mvNN <- mvdc(cop, c("norm", "norm"),
                 list(list(mean = 0, sd = 1), list(mean = 1)))
    plot(mvNN, n = n)
}

test_90 <- function() {
    ## Construct a three-dimensional nested Joe copula with parameters
    ## chosen such that the Kendall's tau of the respective bivariate margins
    ## are 0.2 and 0.5.
    theta0 <- copJoe@iTau(.2)
    theta1 <- copJoe@iTau(.5)
    C3 <- onacopula("J", C(theta0, 1, C(theta1, c(2,3))))

    ## Evaluate this copula at the vector u
    u <- c(.7,.8,.6)
    pCopula(u, C3)

    ## Evaluate this copula at the matrix v
    v <- matrix(runif(300), ncol=3)
    pCopula(v, C3)

    ## Back-compatibility check
    stopifnot(identical( pCopula (u, C3), suppressWarnings(
                        pnacopula(C3, u))),
              identical( pCopula (v, C3), suppressWarnings(
                        pnacopula(C3, v))))
}

test_91 <- function() {
    ## Simple definition of the function:
    pobs
    ## Draw from a multivariate normal distribution
    d <- 10
    set.seed(1)
    P <- Matrix::nearPD(matrix(pmin(pmax(runif(d*d), 0.3), 0.99), ncol=d))$mat
    diag(P) <- rep(1, d)
    n <- 500
    x <- MASS::mvrnorm(n, mu = rep(0, d), Sigma = P)

    ## Compute pseudo-observations (should roughly follow a Gauss
    ## copula with correlation matrix P)
    u <- pobs(x)
    plot(u[,5],u[,10], xlab=quote(italic(U)[1]), ylab=quote(italic(U)[2]))

    ## All components: pairwise plot
    pairs(u, gap=0, pch=".", labels =
          as.expression( lapply(1:d, function(j) bquote(italic(U[.(j)]))) ))
}

test_92 <- function() {
    ## The dilogarithm,  polylog(z, s = 2) = Li_2(.) -- mathmatically defined on C \ [1, Inf)
    ## so x -> 1 is a limit case:
    polylog(z = 1, s = 2)
    ## in the limit, should be equal to
    pi^2 / 6

    ## Default method uses  GSL's dilog():
    rLi2 <- curve(polylog(x, 2), -5, 1, n= 1+ 6*64, col=2, lwd=2)
    abline(c(0,1), h=0,v=0:1, lty=3, col="gray40")
    ## "sum" method gives the same for |z| < 1 and large number of terms:
    ii <- which(abs(rLi2$x) < 1)
    stopifnot(all.equal(rLi2$y[ii],
                polylog(rLi2$x[ii], 2, "sum", n.sum = 1e5),
              tolerance = 1e-15))


    z1 <- c(0.95, 0.99, 0.995, 0.999, 0.9999)
    L   <- polylog(         z1,  s=-3,method="negI-s-Euler") # close to Inf
    LL  <- polylog(     log(z1), s=-3,method="negI-s-Euler",is.log.z=TRUE)
    LLL <- polylog(log(-log(z1)),s=-3,method="negI-s-Euler",is.logmlog=TRUE)
    all.equal(L, LL)
    all.equal(L, LLL)

    p.Li <- function(s.set, from = -2.6, to = 1/4, ylim = c(-1, 0.5),
                     colors = c("orange","brown", palette()), n = 201, ...)
    {
        s.set <- sort(s.set, decreasing = TRUE)
        s <- s.set[1] # <_ for auto-ylab
        curve(polylog(x, s, method="negI-s-Stirling"), from, to,
              col=colors[1], ylim=ylim, n=n, ...)
        abline(h=0,v=0, col="gray")
        for(is in seq_along(s.set)[-1])
            curve(polylog(x, s=s.set[is], method="negI-s-Stirling"),
                  add=TRUE, col = colors[is], n=n)
        s <- rev(s.set)
        legend("bottomright",paste("s =",s), col=colors[2-s], lty=1, bty="n")
    }

    ## yellow is unbearable (on white):
    palette(local({p <- palette(); p[p=="yellow"] <- "goldenrod"; p}))

    ## Wikipedia page plot (+/-):
    p.Li(1:-3, ylim= c(-.8, 0.6), colors = c(2:4,6:7))

    ## and a bit more:
    p.Li(1:-5)

    ## For the range we need it:
    ccol <- c(NA,NA, rep(palette(),10))
    p.Li(-1:-20, from=0, to=.99, colors=ccol, ylim = c(0, 10))
    ## log-y scale:
    p.Li(-1:-20, from=0, to=.99, colors=ccol, ylim = c(.01, 1e7),
         log = "y", yaxt = "n")
    if(require(sfsmisc)) eaxis(2) else axis(2)
}

test_93 <- function() {
    polynEval(c(1,-2,1), x = -2:7) # (x - 1)^2
    polynEval(c(0, 24, -50, 35, -10, 1),
              x = matrix(0:5, 2,3)) # 5 zeros!
}

test_94 <- function() {
    C8 <- onacopula("F", C(1.9, 1,
                           list(K1 = C(5.7, c(2,5)),
                                abc= C(5.0, c(3,4,6),
                                       list(L2 = C(11.5, 7:8))))))
    C8 # -> printNacopula(C8)
    printNacopula(C8, delta=10)
    printNacopula(C8, labelKids=TRUE)
}

test_95 <- function() {
    ## Construct a three-dimensional nested Joe copula with parameters
    ## chosen such that the Kendall's tau of the respective bivariate margins
    ## are 0.2 and 0.5.
    theta0 <- copJoe@iTau(.2)
    theta1 <- copJoe@iTau(.5)
    C3 <- onacopula("J", C(theta0, 1, C(theta1, c(2,3))))

    ## Compute the probability of a random vector distributed according to
    ## this copula to fall inside the cube with lower point l and upper
    ## point u.
    l <- c(.7,.8,.6)
    u <- c(1,1,1)
    prob(C3, l, u)

    ## ditto for a bivariate normal copula with rho = 0.8 :
    Cn <- normalCopula(0.8)
    (prob(Cn, c(.2,.4), c(.3,.6)) -> pr) # 0.0222...
    ## prob() just using volume(), internally:
    pr == volume(function(z) pCopula(z, Cn), c(.2,.4), c(.3,.6))
}

test_96 <- function() {
    n <- 250
    df <- 7
    set.seed(1)
    x <- rchisq(n, df=df)

    ## Q-Q plot against the true quantiles (of a chi^2_3 distribution)
    qqplot2(x, qF = function(p) qchisq(p, df=df),
            main = substitute(bold(italic(chi[NU])~~"Q-Q Plot"), list(NU=df)))

    ## in log-log scale
    qqplot2(x, qF = function(p) qchisq(p, df=df), log="xy",
            main = substitute(bold(italic(chi[NU])~~"Q-Q Plot"), list(NU=df)))

    ## Q-Q plot against wrong quantiles (of an Exp(1) distribution)
    qqplot2(x, qF=qexp, main = quote(bold(Exp(1)~~"Q-Q Plot")))
}

test_97 <- function() {
    ## Sample n random variates V0 ~ F0 for Frank and Joe with parameter
    ## chosen such that Kendall's tau equals 0.2 and plot histogram
    n <- 1000
    theta0.F <- copFrank@iTau(0.2)
    V0.F <- copFrank@V0(n,theta0.F)
    hist(log(V0.F), prob=TRUE); lines(density(log(V0.F)), col=2, lwd=2)
    theta0.J <- copJoe@iTau(0.2)
    V0.J <- copJoe@V0(n,theta0.J)
    hist(log(V0.J), prob=TRUE); lines(density(log(V0.J)), col=2, lwd=2)

    ## Sample corresponding V01 ~ F01 for Frank and Joe and plot histogram
    ## copFrank@V01 calls rF01Frank(V0, theta0, theta1, rej=1, approx=10000)
    ## copJoe@V01 calls rF01Joe(V0, alpha, approx=10000)
    theta1.F <- copFrank@iTau(0.5)
    V01.F <- copFrank@V01(V0.F,theta0.F,theta1.F)
    hist(log(V01.F), prob=TRUE); lines(density(log(V01.F)), col=2, lwd=2)
    theta1.J <- copJoe@iTau(0.5)
    V01.J <- copJoe@V01(V0.J,theta0.J,theta1.J)
    hist(log(V01.J), prob=TRUE); lines(density(log(V01.J)), col=2, lwd=2)
}

test_98 <- function() {
    ## Simple definition of the functions:
    rFFrank
    rFJoe
}

test_99 <- function() {
    ## Data from radially symmetric copulas
    radSymTest(rCopula(200, frankCopula(3)))
    radSymTest(rCopula(200, normalCopula(0.7, dim = 3)))

    ## Data from non radially symmetric copulas
    radSymTest(rCopula(200, claytonCopula(3)))
    radSymTest(rCopula(200, gumbelCopula(2, dim=3)))
}

test_100 <- function() {
    data(rdj)
    str(rdj)# 'Date' is of class "Date"

    with(rdj, {
       matplot(Date, rdj[,-1], type = "o", xaxt = "n", ylim = .15* c(-1,1),
               main = paste("rdj - data;  n =", nrow(rdj)))
       Axis(Date, side=1)
    })
    legend("top", paste(1:3, names(rdj[,-1])), col=1:3, lty=1:3, bty="n")


    x <- rdj[, -1] # '-1' : not the Date
    ## a t-copula (with a vague inital guess of Rho entries)
    tCop <- tCopula(rep(.2, 3), dim=3, dispstr="un", df=10, df.fixed=TRUE)
    ft <- fitCopula(tCop, data = pobs(x))
    ft
    ft@copula # the fitted t-copula as tCopula object
    system.time(
    g.C <- gofCopula(claytonCopula(dim=3), as.matrix(x), simulation = "mult")
    ) ## 5.3 sec
    system.time(
    g.t <- gofCopula(ft@copula, as.matrix(x), simulation = "mult")
    ) ## 8.1 sec
}

test_101 <- function() {
    ## Draw random variates from an exponentially tilted stable distribution
    ## with given alpha, V0, and h = 1
    alpha <- .2
    V0 <- rgamma(200, 1)
    rETS <- retstable(alpha, V0)

    ## Distribution plot the random variates -- log-scaled
    hist(log(rETS), prob=TRUE)
    lines(density(log(rETS)), col=2)
    rug (log(rETS))
}

test_102 <- function() {
    ## Sample n random variates from a Log(p) distribution and plot a
    ## "histogram"
    n <- 1000
    p <- .5
    X <- rlog(n, p)
    table(X) ## distribution on the integers {1, 2, ..}
    ## ==> The following plot is more reasonable than a  hist(X, prob=TRUE) :
    plot(table(X)/n, type="h", lwd=10, col="gray70")

    ## case closer to numerical boundary:
    lV <- log10(V <- rlog(10000, Ip = 2e-9))# Ip = exp(-theta) <==> theta ~= 20
    hV <- hist(lV, plot=FALSE)
    dV <- density(lV)
    ## Plot density and histogram on log scale with nice axis labeling & ticks:
    plot(dV, xaxt="n", ylim = c(0, max(hV$density, dV$y)),
         main = "Density of [log-transformed] Log(p),  p=0.999999..")
    abline(h=0, lty=3); rug(lV); lines(hV, freq=FALSE, col = "light blue"); lines(dV)
    rx <- range(pretty(par("usr")[1:2]))
    sx <- outer(1:9, 10^(max(0,rx[1]):rx[2]))
    axis(1, at=log10(sx),     labels= FALSE, tcl = -0.3)
    axis(1, at=log10(sx[1,]), labels= formatC(sx[1,]), tcl = -0.75)
}

test_103 <- function() {
    ## Implicitly tests the function {with validity of outer_nacopula ..}
    set.seed(11)
    for(i in 1:40) {
      m1 <- rnacModel("Gumbel", d=sample(20:25, 1), pr.comp = 0.3,
    		  rtau0 = function() 0.25)
      m2 <- rnacModel("Joe", d=3, pr.comp = 0.1, order="each")
      mC <- rnacModel("Clayton", d=20, pr.comp = 0.3,
    		  rtau0 = function() runif(1, 0.1, 0.5))
      mF <- rnacModel("Frank", d=sample(20:25, 1), pr.comp = 0.3, order="seq")
    }
}

test_104 <- function() {
    ## Construct a three-dimensional nested Clayton copula with parameters
    ## chosen such that the Kendall's tau of the respective bivariate margins
    ## are 0.2 and 0.5 :
    C3 <- onacopula("C", C(copClayton@iTau(0.2), 1,
                           C(copClayton@iTau(0.5), c(2,3))))
    C3

    ## Sample n vectors of random variates from this copula.  This involves
    ## sampling exponentially tilted stable distributions
    n <- 1000
    U <- rnacopula(n, C3)

    ## Plot the drawn vectors of random variates
    splom2(U)
}

test_105 <- function() {
    ## Construct a three-dimensional nested Clayton copula with parameters
    ## chosen such that the Kendall's tau of the respective bivariate margins
    ## are 0.2 and 0.5.
    theta0 <- copClayton@iTau(.2)
    theta1 <- copClayton@iTau(.5)
    C3 <- onacopula("C", C(theta0, 1, C(theta1, c(2,3))))
    ## Sample n random variates V0 ~ F0 (a Gamma(1/theta0,1) distribution)
    n <- 1000
    V0 <- copClayton@V0(n, theta0)

    ## Given these variates V0, sample the child copula, that is, the bivariate
    ## nested Clayton copula with parameter theta1
    U23 <- rnchild(C3@childCops[[1]], theta0, V0)

    ## Now build the three-dimensional vectors of random variates by hand
    U1 <- copClayton@psi(rexp(n)/V0, theta0)
    U <- cbind(U1, U23$U)

    ## Plot the vectors of random variates from the three-dimensional nested
    ## Clayton copula
    splom2(U)
}

test_106 <- function() {
       # Generate and plot a series of stable random variates
       set.seed(1953)
       r <- rstable1(n = 1000, alpha = 1.9, beta = 0.3)
       plot(r, type = "l", main = "stable: alpha=1.9 beta=0.3",
            col = "steelblue"); grid()

       hist(r, "Scott", prob = TRUE, ylim = c(0,0.3),
            main = "Stable S(1.9, 0.3; 1)")
       lines(density(r), col="red2", lwd = 2)
}

test_107 <- function() {
    f1 <- function(x) (121 - x^2)/(x^2+1)
    f2 <- function(x) exp(-x)*(x - 12)

    try(uniroot(f1, c(0,10)))
    try(uniroot(f2, c(0,2)))
    ##--> error: f() .. end points not of opposite sign

    ## where as safeUroot() simply first enlarges the search interval:
    safeUroot(f1, c(0,10),trace=1)
    safeUroot(f2, c(0,2), trace=2)

    ## no way to find a zero of a positive function:
    try( safeUroot(exp, c(0,2), trace=TRUE) )

    ## Convergence checking :
    safeUroot(sinc, c(0,5), maxiter=4) #-> "just" a warning
    try( # an error, now with  check.conv=TRUE
      safeUroot(sinc, c(0,5), maxiter=4, check.conv=TRUE) )
}

test_108 <- function() {
    ## AR 1 process

    ar <-  numeric(200)
    ar[1] <- rnorm(1)
    for (i in 2:200)
      ar[i] <- 0.5 * ar[i-1] + rnorm(1)
    x <- ar[101:200]

    ## In order to test for serial independence, the first step consists
    ## in simulating the distribution of the test statistics under
    ## serial independence for the same sample size, i.e. n=100.
    ## As we are going to consider lags up to 3, i.e., subsets of
    ## {1,...,4} whose cardinality is between 2 and 4 containing {1},
    ## we set lag.max=3. This may take a while...

    d <- serialIndepTestSim(100,3)

    ## The next step consists in performing the test itself:

    test <- serialIndepTest(x,d)

    ## Let us see the results:

    test

    ## Display the dependogram:

    dependogram(test,print=TRUE)

    ## NB: In order to save d for future use, the saveRDS() function can be used.
}

test_109 <- function() {
    myC <- setTheta(copClayton, 0.5)
    myC
    ## Frank copula with Kendall's tau = 0.8 :
    (myF.8 <- setTheta(copFrank, iTau(copFrank, tau = 0.8)))

    # negative theta is ok for dim = 2 :
    myF <- setTheta(copFrank, -2.5, noCheck=TRUE)
    myF@tau(myF@theta) # -0.262

    myT <- setTheta(tCopula(df.fixed=TRUE), 0.7)
    stopifnot(all.equal(myT, tCopula(0.7, df.fixed=TRUE),
                        check.environment=FALSE, tolerance=0))

    (myT2 <- setTheta(tCopula(dim=3, df.fixed=TRUE), 0.7))
    ## Setting 'rho' and 'df'  --- for default df.fixed=FALSE :
    (myT3 <- setTheta(tCopula(dim=3), c(0.7, 4)))
}

test_110 <- function() {
    ## For 'matrix' objects
    ## Create a 100 x 7 matrix of random variates from a t distribution
    ## with four degrees of freedom and plot the generated data
    n <- 1000 # sample size
    d <- 3 # dimension
    nu <- 4 # degrees of freedom
    tau <- 0.5 # Kendall's tau
    th <- iTau(tCopula(df = nu), tau) # corresponding parameter
    cop <- tCopula(th, dim = d, df = nu) # define copula object
    set.seed(271)
    U <- rCopula(n, copula = cop)
    splom2(U)

    ## For 'copula' objects
    set.seed(271)
    splom2(cop, n = n) # same as above

    ## For 'rotCopula' objects: ---> Examples in rotCopula

    ## For 'mvdc' objects
    mvNN <- mvdc(cop, c("norm", "norm", "exp"),
                 list(list(mean = 0, sd = 1), list(mean = 1), list(rate = 2)))
    splom2(mvNN, n = n)
}

test_111 <- function() {
    tauAMH(c(0, 2^-40, 2^-20))
    curve(tauAMH,  0, 1)
    curve(tauAMH, -1, 1)# negative taus as well
    curve(tauAMH, 1e-12, 1, log="xy") # linear, tau ~= 2/9*theta in the limit

    curve(tauJoe, 1,      10)
    curve(tauJoe, 0.2387, 10)# negative taus (*not* valid for Joe: no 2-monotone psi()!)
}

test_112 <- function() {
    data(uranium)
}

test_113 <- function() {
    ### 1 Basic plots ##############################################################

    ## Generate data from a Gumbel copula
    cop <- gumbelCopula(iTau(gumbelCopula(), tau = 0.5))
    n <- 1e4
    set.seed(271)
    U <- rCopula(n, copula = cop)

    ## Transform the sample to a Latin Hypercube sample
    U.LH <- rLatinHypercube(U)

    ## Plot
    ## Note: The 'variance-reducing property' is barely visible, but that's okay
    layout(rbind(1:2))
    plot(U,    xlab = quote(U[1]), ylab = quote(U[2]), pch = ".", main = "U")
    plot(U.LH, xlab = quote(U[1]), ylab = quote(U[2]), pch = ".", main = "U.LH")
    layout(1) # reset layout

    ## Transform the sample to an Antithetic variate sample
    U.AV <- rAntitheticVariates(U)
    stopifnot(identical(U.AV[,,1],  U ),
              identical(U.AV[,,2], 1-U))

    ## Plot original sample and its corresponding (componentwise) antithetic variates
    layout(rbind(1:2))
    plot(U.AV[,,1], xlab = quote(U[1]), ylab = quote(U[2]), pch=".", main= "U")
    plot(U.AV[,,2], xlab = quote(U[1]), ylab = quote(U[2]), pch=".", main= "1 - U")
    layout(1) # reset layout


    ### 2 Small variance-reduction study for exceedance probabilities ##############

    ## Auxiliary function for approximately computing P(U_1 > u_1,..., U_d > u_d)
    ## by Monte Carlo simulation based on pseudo-random numbers, Latin hypercube
    ## sampling and quasi-random numbers.
    sProb <- function(n, copula, u)
    {
        d <- length(u)
        stopifnot(n >= 1, inherits(copula, "Copula"), 0 < u, u < 1,
                  d == dim(copula))
        umat <- rep(u, each = n)
        ## Pseudo-random numbers
        U <- rCopula(n, copula = copula)
        PRNG <- mean(rowSums(U > umat) == d)
        ## Latin hypercube sampling (based on the recycled 'U')
        U. <- rLatinHypercube(U)
        LHS <- mean(rowSums(U. > umat) == d)
        ## Quasi-random numbers
        U.. <- cCopula(sobol(n, d = d, randomize = TRUE), copula = copula,
                       inverse = TRUE)
        QRNG <- mean(rowSums(U.. > umat) == d)
        ## Return
        c(PRNG = PRNG, LHS = LHS, QRNG = QRNG)
    }

    ## Simulate the probabilities of falling in (u_1,1] x ... x (u_d,1]
    library(qrng) # for quasi-random numbers
    (Xtras <- copula:::doExtras()) # determine whether examples will be extra (long)
    B <- if(Xtras)  500 else 100 # number of replications
    n <- if(Xtras) 1000 else 200 # sample size
    d <- 2 # dimension; note: for d > 2, the true value depends on the seed
    nu <- 3 # degrees of freedom
    th <- iTau(tCopula(df = nu), tau = 0.5) # correlation parameter
    cop <- tCopula(param = th, dim = d, df = nu) # t copula
    u <- rep(0.99, d) # lower-left endpoint of the considered cube
    set.seed(42) # for reproducibility
    true <- prob(cop, l = u, u = rep(1, d)) # true exceedance probability
    system.time(res <- replicate(B, sProb(n, copula = cop, u = u)))

    ## "abbreviations":
    PRNG <- res["PRNG",]
    LHS  <- res["LHS" ,]
    QRNG <- res["QRNG",]

    ## Compute the variance-reduction factors and % improvements
    vrf  <- var(PRNG) / var(LHS)                    # variance reduction factor w.r.t. LHS
    vrf. <- var(PRNG) / var(QRNG)                   # variance reduction factor w.r.t. QRNG
    pim  <- (var(PRNG) - var(LHS)) / var(PRNG) *100 # improvement w.r.t. LHS
    pim. <- (var(PRNG) - var(QRNG))/ var(PRNG) *100 # improvement w.r.t. QRNG

    ## Boxplot
    boxplot(list(PRNG = PRNG, LHS = LHS, QRNG = QRNG), notch = TRUE,
            main = substitute("Simulated exceedance probabilities" ~
                                  P(bold(U) > bold(u))~~ "for a" ~ t[nu.]~"copula",
                              list(nu. = nu)),
            sub = sprintf(
               "Variance-reduction factors and %% improvements: %.1f (%.0f%%), %.1f (%.0f%%)",
                vrf, pim, vrf., pim.))
    abline(h = true, lty = 3) # true value
    mtext(sprintf("B = %d replications with n = %d and d = %d", B, n, d), side = 3)
}

test_114 <- function() {
    ## For 'matrix' objects
    ## The Frechet--Hoeffding bounds W and M
    n.grid <- 26
    u <- seq(0, 1, length.out = n.grid)
    grid <- expand.grid("u[1]" = u, "u[2]" = u)
    W <- function(u) pmax(0, rowSums(u)-1) # lower bound W
    M <- function(u) apply(u, 1, min) # upper bound M
    x.W <- cbind(grid, "W(u[1],u[2])" = W(grid)) # evaluate W on 'grid'
    x.M <- cbind(grid, "M(u[1],u[2])" = M(grid)) # evaluate M on 'grid'
    wireframe2(x.W)
    wireframe2(x.W, shade = TRUE) # plot of W
    wireframe2(x.M, drape = TRUE) # plot of M
    ## use with custom colors:
    myPalette <- colorRampPalette(c("white","darkgreen", "gold", "red"))
    myPar <- lattice::standard.theme(region = myPalette(16))
    wireframe2(x.W, shade = TRUE, par.settings = myPar)

    ## For 'Copula' objects
    cop <- frankCopula(-4)
    wireframe2(cop, pCopula) # the copula
    wireframe2(cop, pCopula, shade = TRUE) # ditto, "shaded" (but color=FALSE)
    wireframe2(cop, pCopula, shade = TRUE, par.settings=list()) # use lattice default colors
    wireframe2(cop, pCopula, shade = TRUE, col.4 = "gray60") # ditto, "shaded"+grid
    wireframe2(cop, pCopula, drape = TRUE, xlab = quote(x[1])) # adjusting an axis label
    wireframe2(cop, dCopula, delta=0.01) # the density
    wireframe2(cop, dCopula, shade = TRUE, par.settings=list()) # use lattice default colors
    wireframe2(cop, dCopula) # => the density is set to 0 on the margins
    wireframe2(cop, function(u, copula) dCopula(u, copula, log=TRUE),
               shade = TRUE, par.settings = myPar,
               zlab = list(quote(log(c(u[1],u[2]))), rot=90), main = "dCopula(.., log=TRUE)")

    ## For 'mvdc' objects
    mvNN <- mvdc(gumbelCopula(3), c("norm", "norm"),
                 list(list(mean = 0, sd = 1), list(mean = 1)))
    wireframe2(mvNN, dMvdc, xlim=c(-2, 2), ylim=c(-1, 3))
    wireframe2(mvNN, dMvdc, xlim=c(-2, 2), ylim=c(-1, 3), shade=TRUE, par.settings=list())
}

test_115 <- function() {

    ## A two-dimensional data example ----------------------------------
    x <- rCopula(200, claytonCopula(3))


    ## Model (copula) selection -- takes time: each fits 200 copulas to 199 obs.
    xvCopula(gumbelCopula(), x)
    xvCopula(frankCopula(), x)
    xvCopula(joeCopula(), x)
    xvCopula(claytonCopula(), x)
    xvCopula(normalCopula(), x)
    xvCopula(tCopula(), x)
    xvCopula(plackettCopula(), x)


    ## The same with 5-fold cross-validation [to save time ...]
    set.seed(1) # k-fold is random (for k < n) !
    xvCopula(gumbelCopula(),  x, k=5)
    xvCopula(frankCopula(),   x, k=5)
    xvCopula(joeCopula(),     x, k=5)
    xvCopula(claytonCopula(), x, k=5)
    xvCopula(normalCopula(),  x, k=5)
    xvCopula(tCopula(),       x, k=5)
    xvCopula(plackettCopula(),x, k=5)
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

cat("Running test_109\n")
test_109()

cat("Running test_110\n")
test_110()

cat("Running test_111\n")
test_111()

cat("Running test_112\n")
test_112()

cat("Running test_113\n")
test_113()

cat("Running test_114\n")
test_114()

cat("Running test_115\n")
test_115()

