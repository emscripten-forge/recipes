print('Loading VGAM package')
library(VGAM)
print('... VGAM package loaded successfully')

test_1 <- function() {
    y <- cbind(53, 95, 38)
    fit1 <- vglm(y ~ 1, AA.Aa.aa, trace = TRUE)
    fit2 <- vglm(y ~ 1, AA.Aa.aa(inbreeding = TRUE), trace = TRUE)
    rbind(y, sum(y) * fitted(fit1))
    Coef(fit1)  # Estimated pA
    Coef(fit2)  # Estimated pA and f
    summary(fit1)
}

test_2 <- function() {
    ymat <- cbind(AB=1997, Ab=906, aB=904, ab=32)  # Data from Fisher (1925)
    fit <- vglm(ymat ~ 1, AB.Ab.aB.ab(link = "identitylink"), trace = TRUE)
    fit <- vglm(ymat ~ 1, AB.Ab.aB.ab, trace = TRUE)
    rbind(ymat, sum(ymat)*fitted(fit))
    Coef(fit)  # Estimated p
    p <- sqrt(4*(fitted(fit)[, 4]))
    p*p
    summary(fit)
}

test_3 <- function() {
    ymat <- cbind(A = 725, B = 258, AB = 72, O = 1073)  # Order matters, not the name
    fit <- vglm(ymat ~ 1, ABO(link.pA = "identitylink",
                              link.pB = "identitylink"), trace = TRUE,
                crit = "coef")
    coef(fit, matrix = TRUE)
    Coef(fit)  # Estimated pA and pB
    rbind(ymat, sum(ymat) * fitted(fit))
    sqrt(diag(vcov(fit)))
}

test_4 <- function() {
    pneumo <- transform(pneumo, let = log(exposure.time))
    (fit1 <- vglm(cbind(normal, mild, severe) ~ let,
                  cumulative(parallel = TRUE, reverse = TRUE), data = pneumo))
    coef(fit1, matrix = TRUE)
    AIC(fit1)
    AICc(fit1)  # Quick way
    AIC(fit1, corrected = TRUE)  # Slow way
    (fit2 <- vglm(cbind(normal, mild, severe) ~ let,
                  cumulative(parallel = FALSE, reverse = TRUE), data = pneumo))
    coef(fit2, matrix = TRUE)
    AIC(fit2)
    AICc(fit2)
    AIC(fit2, corrected = TRUE)
}

test_5 <- function() {
      set.seed(1)
      nn <- 500
      ARcoeff1 <- c(0.3, 0.25)        # Will be recycled.
      WNsd     <- c(exp(1), exp(1.5)) # Will be recycled.
      p.drift  <- c(0, 0)             # Zero-mean gaussian time series.

      ### Generate two (zero-mean) AR(1) processes ###
      ts1 <- p.drift[1]/(1 - ARcoeff1[1]) +
                       arima.sim(model = list(ar = ARcoeff1[1]), n = nn,
                       sd = WNsd[1])
      ts2 <- p.drift[2]/(1 - ARcoeff1[2]) +
                       arima.sim(model = list(ar = ARcoeff1[2]), n = nn,
                       sd = WNsd[2])

      ARdata <- matrix(cbind(ts1, ts2), ncol = 2)


      ### Compute the exact EIMs: TWO responses. ###
      ExactEIM <- AR1EIM(x = ARdata, var.arg = FALSE, p.drift = p.drift,
                               WNsd = WNsd, ARcoeff1 = ARcoeff1)

      ### For response 1:
      head(ExactEIM[, 1 ,])      # NOTICE THAT THIS IS A (nn x 6) MATRIX!

      ### For response 2:
      head(ExactEIM[, 2 ,])      # NOTICE THAT THIS IS A (nn x 6) MATRIX!
}

test_6 <- function() {
    pneumo <- transform(pneumo, let = log(exposure.time))
    (fit1 <- vglm(cbind(normal, mild, severe) ~ let,
                  cumulative(parallel = TRUE, reverse = TRUE), data = pneumo))
    coef(fit1, matrix = TRUE)
    BIC(fit1)
    (fit2 <- vglm(cbind(normal, mild, severe) ~ let,
                  cumulative(parallel = FALSE, reverse = TRUE), data = pneumo))
    coef(fit2, matrix = TRUE)
    BIC(fit2)
}

test_7 <- function() {
    journal <- c("Biometrika", "Comm Statist", "JASA", "JRSS-B")
    mat <- matrix(c( NA, 33, 320, 284,   730, NA, 813, 276,
                    498, 68,  NA, 325,   221, 17, 142, NA), 4, 4)
    dimnames(mat) <- list(winner = journal, loser = journal)
    Brat(mat)  # Less readable
    Brat(mat, whitespace = TRUE)  # More readable
    vglm(Brat(mat, whitespace = TRUE) ~ 1, brat, trace = TRUE)
}

test_8 <- function() {
    CM.equid(4)
    CM.equid(4, Trev = TRUE, Tref = 3)
    CM.symm1(5)
    CM.symm0(5)
    CM.qnorm(5)
}

test_9 <- function() {
    nn <- 1000
    bdata <- data.frame(y = rbeta(nn, shape1 = 1, shape2 = 3))  # Original scale
    fit <- vglm(y ~ 1, betaR, data = bdata, trace = TRUE)  # Intercept-only model
    coef(fit, matrix = TRUE)  # Both on a log scale
    Coef(fit)  # On the original scale
}

test_10 <- function() {
    # Rank-1 stereotype model of Anderson (1984)
    pneumo <- transform(pneumo, let = log(exposure.time), x3 = runif(nrow(pneumo)))
    fit <- rrvglm(cbind(normal, mild, severe) ~ let + x3, multinomial, data = pneumo)
    coef(fit, matrix = TRUE)
    Coef(fit)
}

test_11 <- function() {
    # Rank-1 stereotype model of Anderson (1984)
    pneumo <- transform(pneumo, let = log(exposure.time), x3 = runif(nrow(pneumo)))
    fit <- rrvglm(cbind(normal, mild, severe) ~ let + x3, multinomial, data = pneumo)
    coef(fit, matrix = TRUE)
    Coef(fit)
    # print(Coef(fit), digits = 3)
}

test_12 <- function() {
    set.seed(123); nn <- 1000
    bdata <- data.frame(y = rbeta(nn, shape1 = 1, shape2 = 3))
    fit <- vglm(y ~ 1, betaff, data = bdata, trace = TRUE)  # intercept-only model
    coef(fit, matrix = TRUE)  # log scale
    Coef(fit)  # On the original scale
}

test_13 <- function() {
    fdata <- data.frame(y = rfisk(1000, shape = exp(1), scale = exp(2)))
    fit <- vglm(y ~ 1, fisk(lss = FALSE), data = fdata, trace = TRUE)
    coef(fit, matrix = TRUE)
    Coef(fit)
}

test_14 <- function() {
    dgenbetaII(0, shape1.a = 1/4, shape2.p = 4, shape3.q = 3)
    dgenbetaII(0, shape1.a = 1/4, shape2.p = 2, shape3.q = 3)
    dgenbetaII(0, shape1.a = 1/4, shape2.p = 8, shape3.q = 3)
}

test_15 <- function() {
    pneumo <- transform(pneumo, let = log(exposure.time))
    fit <- vglm(cbind(normal, mild, severe) ~ let, acat, data = pneumo)
    coef(fit)  # 8-vector
    Influence(fit)  # 8 x 4
    all(abs(colSums(Influence(fit))) < 1e-6)  # TRUE
}

test_16 <- function() {
    idata <- data.frame(y = rinv.lomax(n = 1000, exp(2), exp(1)))
    fit <- vglm(y ~ 1, inv.lomax, idata, trace = TRUE, crit = "coef")
    coef(fit, matrix = TRUE)
    Coef(fit)
}

test_17 <- function() {
    idata <- data.frame(y = rinv.paralogistic(3000, exp(1), sc = exp(2)))
    fit <- vglm(y ~ 1, inv.paralogistic(lss = FALSE, ishape1.a = 2.1),
                data = idata, trace = TRUE, crit = "coef")
    coef(fit, matrix = TRUE)
    Coef(fit)
}

test_18 <- function() {
    #  McKendrick (1925): Data from 223 Indian village households
    cholera <- data.frame(ncases = 0:4,  # Number of cholera cases,
                          wfreq  = c(168, 32, 16, 6, 1))  # Frequencies
    fit7 <- vglm(ncases ~ 1, gaitdpoisson(i.mlm = 0, ilambda.p = 1),
                 weight = wfreq, data = cholera, trace = TRUE)
    coef(fit7, matrix = TRUE)
    KLD(fit7)
}

test_19 <- function() {
    # Order matters only:
    y <- cbind(MS = 295, Ms = 107, MNS = 379, MNs = 322, NS = 102, Ns = 214)
    fit <- vglm(y ~ 1, MNSs("logitlink", .25, .28, .08), trace = TRUE)
    fit <- vglm(y ~ 1, MNSs(link = logitlink), trace = TRUE, crit = "coef")
    Coef(fit)
    rbind(y, sum(y)*fitted(fit))
    sqrt(diag(vcov(fit)))
}

test_20 <- function() {
    nn <- 1000; mymu <- 1; sdev <- exp(1)
    apar <- rhobitlink(0.5, inverse = TRUE)
    prob <-  logitlink(0.5, inverse = TRUE)
    mat <- rN1binom(nn, mymu, sdev, prob, apar)
    nbdata <- data.frame(y1 = mat[, 1], y2 = mat[, 2])
    fit1 <- vglm(cbind(y1, y2) ~ 1, N1binomial,
                 nbdata, trace = TRUE)
    coef(fit1, matrix = TRUE)
    Coef(fit1)
    head(fitted(fit1))
    summary(fit1)
    confint(fit1)
}

test_21 <- function() {
    apar <- rhobitlink(0.3, inverse = TRUE)
    nn <- 1000; mymu <- 1; sdev <- exp(1)
    lambda <- loglink(1, inverse = TRUE)
    mat <- rN1pois(nn, mymu, sdev, lambda, apar)
    npdata <- data.frame(y1 = mat[, 1], y2 = mat[, 2])
    with(npdata, var(y2) / mean(y2))  # Overdispersion
    fit1 <- vglm(cbind(y1, y2) ~ 1, N1poisson,
                 npdata, trace = TRUE)
    coef(fit1, matrix = TRUE)
    Coef(fit1)
    head(fitted(fit1))
    summary(fit1)
    confint(fit1)
}

test_22 <- function() {
    pdata <- data.frame(y = rparalogistic(n = 3000, scale = exp(1), exp(2)))
    fit <- vglm(y ~ 1, paralogistic(lss = FALSE, ishape1.a = 4.1),
                data = pdata, trace = TRUE)
    coef(fit, matrix = TRUE)
    Coef(fit)
}

test_23 <- function() {
    pneumo <- transform(pneumo, let = log(exposure.time))
    (fit <- vglm(cbind(normal, mild, severe) ~ let, propodds, data = pneumo))
    R2latvar(fit)
}

test_24 <- function() {
    pneumo <- transform(pneumo, let = log(exposure.time),
                                x3  = runif(nrow(pneumo)))
    (fit1 <- rrvglm(cbind(normal, mild, severe) ~ let + x3,
                    acat, data = pneumo))
    coef(fit1, matrix = TRUE)
    constraints(fit1)
    Rank(fit1)
}

test_25 <- function() {
    (alcoff.e <- moffset(alcoff, roffset = "6", postfix = "*"))
    (aa <- Rcim(alcoff,    rbaseline = "11", cbaseline = "Sun"))
    (bb <- moffset(alcoff,             "11",             "Sun", postfix = "*"))
    aa - bb  # Note the difference!
}

test_26 <- function() {
    # Obtain some of the results of p.1199 of Kmenta and Gilbert (1968)
    clist <- list("(Intercept)" = diag(2),
                  "capital.g"   = rbind(1, 0),
                  "value.g"     = rbind(1, 0),
                  "capital.w"   = rbind(0, 1),
                  "value.w"     = rbind(0, 1))
    zef1 <- vglm(cbind(invest.g, invest.w) ~
                 capital.g + value.g + capital.w + value.w,
                 SURff(divisor = "sqrt"), maxit = 1,
                 data = gew, trace = TRUE, constraints = clist)

    round(coef(zef1, matrix = TRUE), digits = 4)  # ZEF
    zef1@extra$ncols.X.lm
    zef1@misc$divisor
    zef1@misc$values.divisor
    round(sqrt(diag(vcov(zef1))),    digits = 4)  # SEs
    nobs(zef1, type = "lm")
    df.residual(zef1, type = "lm")


    mle1 <- vglm(cbind(invest.g, invest.w) ~
                 capital.g + value.g + capital.w + value.w,
                 SURff(mle.normal = TRUE),
                 epsilon = 1e-11,
                 data = gew, trace = TRUE, constraints = clist)
    round(coef(mle1, matrix = TRUE), digits = 4)  # MLE
    round(sqrt(diag(vcov(mle1))),    digits = 4)  # SEs
}

test_27 <- function() {
    Pneumo <- pneumo
    colnames(Pneumo) <- c("y1", "y2", "y3", "x2")  # The "y" variables are response
    Pneumo$x1 <- 1; Pneumo$x3 <- 3; Pneumo$x <- 0; Pneumo$x4 <- 4  # Add these

    Select(data = Pneumo)  # Same as with(Pneumo, cbind(y1, y2, y3))
    Select(Pneumo, "x")
    Select(Pneumo, "x", sort = FALSE, as.char = TRUE)
    Select(Pneumo, "x", exclude = "x1")
    Select(Pneumo, "x", exclude = "x1", as.char = TRUE)
    Select(Pneumo, c("x", "y"))
    Select(Pneumo, "z")  # Now returns a NULL
    Select(Pneumo, " ")  # Now returns a NULL
    Select(Pneumo, prefix = TRUE, as.formula = TRUE)
    Select(Pneumo, "x", exclude = c("x3", "x1"), as.formula = TRUE,
           lhs = "cbind(y1, y2, y3)", rhs = "0")
    Select(Pneumo, "x", exclude = "x1", as.formula = TRUE, as.char = TRUE,
           lhs = "cbind(y1, y2, y3)", rhs = "0")

    # Now a 'real' example:
    Huggins89table1 <- transform(Huggins89table1, x3.tij = t01)
    tab1 <- subset(Huggins89table1,
                   rowSums(Select(Huggins89table1, "y")) > 0)
    # Same as
    # subset(Huggins89table1, y1 + y2 + y3 + y4 + y5 + y6 + y7 + y8 + y9 + y10 > 0)

    # Long way to do it:
    fit.th <-
       vglm(cbind(y01, y02, y03, y04, y05, y06, y07, y08, y09, y10) ~ x2 + x3.tij,
            xij = list(x3.tij ~ t01 + t02 + t03 + t04 + t05 + t06 + t07 + t08 +
                                t09 + t10 - 1),
            posbernoulli.t(parallel.t = TRUE ~ x2 + x3.tij),
            data = tab1, trace = TRUE,
            form2 = ~ x2 + x3.tij + t01 + t02 + t03 + t04 + t05 + t06 + t07 + t08 +
                                    t09 + t10)
    # Short way to do it:
    Fit.th <- vglm(Select(tab1, "y") ~ x2 + x3.tij,
                   xij = list(Select(tab1, "t", as.formula = TRUE,
                                     sort = FALSE, lhs = "x3.tij", rhs = "0")),
                   posbernoulli.t(parallel.t = TRUE ~ x2 + x3.tij),
                   data = tab1, trace = TRUE,
                   form2 = Select(tab1, prefix = TRUE, as.formula = TRUE))
}

test_28 <- function() {
    sdata <- data.frame(y = rsinmad(n = 3000, scale = exp(2),
                                    shape1 = exp(1), shape3 = exp(1)))
    fit <- vglm(y ~ 1, sinmad(lss = FALSE, ishape1.a = 2.1), data = sdata,
                trace = TRUE, crit = "coef")
    coef(fit, matrix = TRUE)
    Coef(fit)
}

test_29 <- function() {
    with(leukemia, SurvS4(time, status))
    class(with(leukemia, SurvS4(time, status)))
}

test_30 <- function() {
    showClass("SurvS4")
}

test_31 <- function() {
    pneumo <- transform(pneumo, let = log(exposure.time))
    (fit1 <- vglm(cbind(normal, mild, severe) ~ let,
                  cumulative(parallel = TRUE, reverse = TRUE), data = pneumo))
    coef(fit1, matrix = TRUE)
    TIC(fit1)
    (fit2 <- vglm(cbind(normal, mild, severe) ~ let,
                  cumulative(parallel = FALSE, reverse = TRUE), data = pneumo))
    coef(fit2, matrix = TRUE)
    TIC(fit2)
}

test_32 <- function() {
    param.names("shape", 1)  # "shape"
    param.names("shape", 3)  # c("shape1", "shape2", "shape3")

    dimm(3, hbw = 1)  # Diagonal matrix; the 3 elements need storage.
    dimm(3)  # A general 3 x 3 symmetrix matrix has 6 unique elements.
    dimm(3, hbw = 2)  # Tridiagonal matrix; the 3-3 element is 0 and unneeded.

    M1 <- 2; ncoly <- 3; M <- ncoly * M1
    mynames1 <- param.names("location", ncoly)
    mynames2 <- param.names("scale",    ncoly)
    (parameters.names <- c(mynames1, mynames2)[interleave.VGAM(M, M1 = M1)])
    # The  following is/was in Yee (2015) and has a poor/deceptive style:
    (parameters.names <- c(mynames1, mynames2)[interleave.VGAM(M, M  = M1)])
    parameters.names[interleave.VGAM(M, M1 = M1, inverse = TRUE)]
}

test_33 <- function() {
    pneumo <- transform(pneumo, let = log(exposure.time))
    (fit <- vglm(cbind(normal, mild, severe) ~ let, acat, pneumo))
    coef(fit, matrix = TRUE)
    constraints(fit)
    model.matrix(fit)
}

test_34 <- function() {
    data("backPain2", package = "VGAM")
    summary(backPain2)
    fit1 <- vglm(pain ~ x2 + x3 + x4, propodds, data = backPain2)
    coef(fit1)
    add1(fit1, scope = ~ x2 * x3 * x4, test = "LRT")
    drop1(fit1, test = "LRT")
    fit2 <- vglm(pain ~ x2 * x3 * x4, propodds, data = backPain2)
    drop1(fit2)
}

test_35 <- function() {
    # Example 1: a proportional odds model fitted to pneumo.
    set.seed(1)
    pneumo <- transform(pneumo, let = log(exposure.time), x3 = runif(8))
    fit1 <- vglm(cbind(normal, mild, severe) ~ let     , propodds, pneumo)
    fit2 <- vglm(cbind(normal, mild, severe) ~ let + x3, propodds, pneumo)
    fit3 <- vglm(cbind(normal, mild, severe) ~ let + x3, cumulative, pneumo)
    anova(fit1, fit2, fit3, type = 1)  # Remember to specify 'type'!!
    anova(fit2)
    anova(fit2, type = "I")
    anova(fit2, type = "III")

    # Example 2: a proportional odds model fitted to backPain2.
    data("backPain2", package = "VGAM")
    summary(backPain2)
    fitlogit <- vglm(pain ~ x2 * x3 * x4, propodds, data = backPain2)
    coef(fitlogit)
    anova(fitlogit)
    anova(fitlogit, type = "I")
    anova(fitlogit, type = "III")
}

test_36 <- function() {
    # Fit a M_tbh model to the deermice data:
    (pdata <- aux.posbernoulli.t(with(deermice,
                                      cbind(y1, y2, y3, y4, y5, y6))))

    deermice <- data.frame(deermice,
                        bei = 0,  # Add this
                        pdata$cap.hist1)  # Incorporate these
    head(deermice)  # Augmented with behavioural effect indicator variables
    tail(deermice)
}

test_37 <- function() {
    summary(backPain)
    summary(backPain2)
}

test_38 <- function() {
    beggs
    colSums(beggs)
    rowSums(beggs)
}

test_39 <- function() {
    y0 <- 1; nn <- 3000
    bdata <- data.frame(y  = rbenini(nn, y0 = y0, shape = exp(2)))
    fit <- vglm(y ~ 1, benini1(y0 = y0), data = bdata, trace = TRUE)
    coef(fit, matrix = TRUE)
    Coef(fit)
    fit@extra$y0
    c(head(fitted(fit), 1), with(bdata, median(y)))  # Should be equal
}

test_40 <- function() {
    bdata <- data.frame(y = rsinmad(2000, shape1.a = 1,
             shape3.q = exp(2), scale = exp(1)))  # Not genuine data!
    # fit <- vglm(y ~ 1, betaII, data = bdata, trace = TRUE)
    fit <- vglm(y ~ 1, betaII(ishape2.p = 0.7, ishape3.q = 0.7),
                data = bdata, trace = TRUE)
    coef(fit, matrix = TRUE)
    Coef(fit)
    summary(fit)
}

test_41 <- function() {
    bdata <- data.frame(y = rbeta(1000, shape1 = exp(0), shape2 = exp(1)))
    fit <- vglm(y ~ 1, betaR(lshape1 = "identitylink",
                lshape2 = "identitylink"), bdata, trace = TRUE, crit = "coef")
    fit <- vglm(y ~ 1, betaR, data = bdata, trace = TRUE, crit = "coef")
    coef(fit, matrix = TRUE)
    Coef(fit)  # Useful for intercept-only models

    bdata <- transform(bdata, Y = 5 + 8 * y)  # From 5 to 13, not 0 to 1
    fit <- vglm(Y ~ 1, betaR(A = 5, B = 13), data = bdata, trace = TRUE)
    Coef(fit)
    c(meanY = with(bdata, mean(Y)), head(fitted(fit),2))
}

test_42 <- function() {
    bdata <- data.frame(y = rbeta(nn <- 1000, shape1 = exp(0),
                                  shape2 = exp(1)))
    fit1 <- vglm(y ~ 1, betaff, data = bdata, trace = TRUE)
    coef(fit1, matrix = TRUE)
    Coef(fit1)  # Useful for intercept-only models

    # General A and B, and with a covariate
    bdata <- transform(bdata, x2 = runif(nn))
    bdata <- transform(bdata, mu = logitlink(0.5 - x2, inverse = TRUE),
                              prec = exp(3.0 + x2))  # prec == phi
    bdata <- transform(bdata, shape2 = prec * (1 - mu),
                              shape1 = mu * prec)
    bdata <- transform(bdata,
                       y = rbeta(nn, shape1 = shape1, shape2 = shape2))
    bdata <- transform(bdata, Y = 5 + 8 * y)  # From 5--13, not 0--1
    fit <- vglm(Y ~ x2, data = bdata, trace = TRUE,
       betaff(A = 5, B = 13, lmu = "extlogitlink(min = 5, max = 13)"))
    coef(fit, matrix = TRUE)
}

test_43 <- function() {
    nn <- 1000
    bdata <- data.frame(shape1 = exp(1), shape2 = exp(3))
    bdata <- transform(bdata, yb = rbeta(nn, shape1, shape2))
    bdata <- transform(bdata, y1 = (1-yb) /    yb,
                              y2 =    yb  / (1-yb),
                              y3 = rgamma(nn, exp(3)) / rgamma(nn, exp(2)))

    fit1 <- vglm(y1 ~ 1, betaprime, data = bdata, trace = TRUE)
    coef(fit1, matrix = TRUE)

    fit2 <- vglm(y2 ~ 1, betaprime, data = bdata, trace = TRUE)
    coef(fit2, matrix = TRUE)

    fit3 <- vglm(y3 ~ 1, betaprime, data = bdata, trace = TRUE)
    coef(fit3, matrix = TRUE)

    # Compare the fitted values
    with(bdata, mean(y3))
    head(fitted(fit3))
    Coef(fit3)  # Useful for intercept-only models
}

test_44 <- function() {
    ymat <- rbiamhcop(1000, apar = rhobitlink(2, inverse = TRUE))
    fit <- vglm(ymat ~ 1, biamhcop, trace = TRUE)
    coef(fit, matrix = TRUE)
    Coef(fit)
}

test_45 <- function() {
    coalminers <- transform(coalminers, Age = (age - 42) / 5)
    fit <- vglm(cbind(nBnW, nBW, BnW, BW) ~ Age,
                binom2.rho, data = coalminers, trace = TRUE)
    summary(fit)
    coef(fit, matrix = TRUE)
}

test_46 <- function() {
    set.seed(123); nn <- 1000
    bdata <- data.frame(x2 = runif(nn), x3 = runif(nn))
    bdata <- transform(bdata, y1 = rnorm(nn, 1 + 2 * x2),
                              y2 = rnorm(nn, 3 + 4 * x2))
    fit1 <- vglm(cbind(y1, y2) ~ x2,
                 binormal(eq.sd = TRUE), bdata, trace = TRUE)
    coef(fit1, matrix = TRUE)
    constraints(fit1)
    summary(fit1)

    # Estimated P(Y1 <= y1, Y2 <= y2) under the fitted model
    var1  <- loglink(2 * predict(fit1)[, "loglink(sd1)"], inv = TRUE)
    var2  <- loglink(2 * predict(fit1)[, "loglink(sd2)"], inv = TRUE)
    cov12 <- rhobitlink(predict(fit1)[, "rhobitlink(rho)"], inv = TRUE)
    head(with(bdata, pbinorm(y1, y2,
                             mean1 = predict(fit1)[, "mean1"],
                             mean2 = predict(fit1)[, "mean2"],
                             var1 = var1, var2 = var2, cov12 = cov12)))
}

test_47 <- function() {
    bdata <- data.frame(y = rbort(n <- 200))
    fit <- vglm(y ~ 1, borel.tanner, bdata, trace = TRUE, crit = "c")
    coef(fit, matrix = TRUE)
    Coef(fit)
    summary(fit)
}

test_48 <- function() {
    # Citation statistics: being cited is a 'win'; citing is a 'loss'
    journal <- c("Biometrika", "Comm.Statist", "JASA", "JRSS-B")
    mat <- matrix(c( NA, 33, 320, 284,
                    730, NA, 813, 276,
                    498, 68,  NA, 325,
                    221, 17, 142,  NA), 4, 4)
    dimnames(mat) <- list(winner = journal, loser = journal)
    fit <- vglm(Brat(mat) ~ 1, brat(refgp = 1), trace = TRUE)
    fit <- vglm(Brat(mat) ~ 1, brat(refgp = 1), trace = TRUE, crit = "coef")
    summary(fit)
    c(0, coef(fit))  # Log-abilities (in order of "journal")
    c(1, Coef(fit))  # Abilities (in order of "journal")
    fitted(fit)     # Probabilities of winning in awkward form
    (check <- InverseBrat(fitted(fit)))  # Probabilities of winning
    check + t(check)  # Should be 1's in the off-diagonals
}

test_49 <- function() {
    # citation statistics: being cited is a 'win'; citing is a 'loss'
    journal <- c("Biometrika", "Comm.Statist", "JASA", "JRSS-B")
    mat <- matrix(c( NA, 33, 320, 284,
                    730, NA, 813, 276,
                    498, 68,  NA, 325,
                    221, 17, 142,  NA), 4, 4)
    dimnames(mat) <- list(winner = journal, loser = journal)

    # Add some ties. This is fictitional data.
    ties <- 5 + 0 * mat
    ties[2, 1] <- ties[1,2] <- 9

    # Now fit the model
    fit <- vglm(Brat(mat, ties) ~ 1, bratt(refgp = 1), trace = TRUE,
                crit = "coef")

    summary(fit)
    c(0, coef(fit))  # Log-abilities (last is log(alpha0))
    c(1, Coef(fit))  #     Abilities (last is alpha0)

    fit@misc$alpha   # alpha_1,...,alpha_M
    fit@misc$alpha0  # alpha_0

    fitted(fit)  # Probabilities of winning and tying, in awkward form
    predict(fit)
    (check <- InverseBrat(fitted(fit)))    # Probabilities of winning
    qprob <- attr(fitted(fit), "probtie")  # Probabilities of a tie
    qprobmat <- InverseBrat(c(qprob), NCo = nrow(ties))  # Pr(tie)
    check + t(check) + qprobmat  # Should be 1s in the off-diagonals
}

test_50 <- function() {
    budworm
    summary(budworm)
}

test_51 <- function() {
    # Both location and scale parameters unknown
    set.seed(123)
    cdata <- data.frame(x2 = runif(nn <- 1000))
    cdata <- transform(cdata, loc = exp(1 + 0.5 * x2), scale = exp(1))
    cdata <- transform(cdata, y2 = rcauchy(nn, loc, scale))
    fit2 <- vglm(y2 ~ x2, cauchy(lloc = "loglink"), data = cdata)
    coef(fit2, matrix = TRUE)
    head(fitted(fit2))  # Location estimates
    summary(fit2)

    # Location parameter unknown
    cdata <- transform(cdata, scale1 = 0.4)
    cdata <- transform(cdata, y1 = rcauchy(nn, loc, scale1))
    fit1 <- vglm(y1 ~ x2, cauchy1(scale = 0.4), data = cdata, trace = TRUE)
    coef(fit1, matrix = TRUE)
}

test_52 <- function() {
    fit <- vgam(BMI ~ s(age, df=c(4, 2)), lms.bcn(zero = 1), data = bmi.nz)
    head(fit@post$cdf)
    head(cdf(fit))  # Same
    head(depvar(fit))
    head(fitted(fit))

    cdf(fit, data.frame(age = c(31.5, 39), BMI = c(28.4, 24)))
}

test_53 <- function() {
    # Example 1: right censored data
    set.seed(123); U <- 20
    cdata <- data.frame(y = rpois(N <- 100, exp(3)))
    cdata <- transform(cdata, cy = pmin(U, y),
                              rcensored = (y >= U))
    cdata <- transform(cdata, status = ifelse(rcensored, 0, 1))
    with(cdata, table(cy))
    with(cdata, table(rcensored))
    with(cdata, table(print(SurvS4(cy, status))))  # Check; U+ means >= U
    fit <- vglm(SurvS4(cy, status) ~ 1, cens.poisson, data = cdata,
                trace = TRUE)
    coef(fit, matrix = TRUE)
    table(print(depvar(fit)))  # Another check; U+ means >= U

    # Example 2: left censored data
    L <- 15
    cdata <- transform(cdata,
                   cY = pmax(L, y),
                   lcensored = y <  L)  # Note y < L, not cY == L or y <= L
    cdata <- transform(cdata, status = ifelse(lcensored, 0, 1))
    with(cdata, table(cY))
    with(cdata, table(lcensored))
    with(cdata, table(print(SurvS4(cY, status, type = "left"))))  # Check
    fit <- vglm(SurvS4(cY, status, type = "left") ~ 1, cens.poisson,
                data = cdata, trace = TRUE)
    coef(fit, matrix = TRUE)

    # Example 3: interval censored data
    cdata <- transform(cdata, Lvec = rep(L, len = N),
                              Uvec = rep(U, len = N))
    cdata <-
      transform(cdata,
            icensored = Lvec <= y & y < Uvec)  # Not lcensored or rcensored
    with(cdata, table(icensored))
    cdata <- transform(cdata, status = rep(3, N))  # 3 == interval censored
    cdata <- transform(cdata,
             status = ifelse(rcensored, 0, status))  # 0 means right censored
    cdata <- transform(cdata,
             status = ifelse(lcensored, 2, status))  # 2 means left  censored
    # Have to adjust Lvec and Uvec because of the (start, end] format:
    cdata$Lvec[with(cdata,icensored)] <- cdata$Lvec[with(cdata,icensored)]-1
    cdata$Uvec[with(cdata,icensored)] <- cdata$Uvec[with(cdata,icensored)]-1
    # Unchanged:
    cdata$Lvec[with(cdata, lcensored)] <- cdata$Lvec[with(cdata, lcensored)]
    cdata$Lvec[with(cdata, rcensored)] <- cdata$Uvec[with(cdata, rcensored)]
    with(cdata,  # Check
     table(ii <- print(SurvS4(Lvec, Uvec, status, type = "interval"))))
    fit <- vglm(SurvS4(Lvec, Uvec, status, type = "interval") ~ 1,
                cens.poisson, data = cdata, trace = TRUE)
    coef(fit, matrix = TRUE)
    table(print(depvar(fit)))  # Another check

    # Example 4: Add in some uncensored observations
    index <- (1:N)[with(cdata, icensored)]
    index <- head(index, 4)
    cdata$status[index] <- 1  # actual or uncensored value
    cdata$Lvec[index] <- cdata$y[index]
    with(cdata, table(ii <- print(SurvS4(Lvec, Uvec, status,
                                         type = "interval"))))  # Check
    fit <- vglm(SurvS4(Lvec, Uvec, status, type = "interval") ~ 1,
                cens.poisson, data = cdata, trace = TRUE, crit = "c")
    coef(fit, matrix = TRUE)
    table(print(depvar(fit)))  # Another check
}

test_54 <- function() {
    cfibrosis
    summary(cfibrosis)
}

test_55 <- function() {
    cdata <- data.frame(x2 = runif(nn <- 1000))
    cdata <- transform(cdata, y1 = rchisq(nn, df = exp(1 - 1 * x2)),
                              y2 = rchisq(nn, df = exp(2 - 2 * x2)))
    fit <- vglm(cbind(y1, y2) ~ x2, chisq, data = cdata, trace = TRUE)
    coef(fit, matrix = TRUE)
}

test_56 <- function() {
    str(coalminers)
}

test_57 <- function() {
    fit <- vgam(agaaus ~ s(altitude, df = 2), binomialff, data = hunua)
    coef(fit)  # Same as coef(fit, type = "linear")
    (ii <- coef(fit, type = "nonlinear"))
    is.list(ii)
    names(ii)
    slotNames(ii[[1]])
}

test_58 <- function() {
    zdata <- data.frame(x2 = runif(nn <- 200))
    zdata <- transform(zdata, pstr0  = logitlink(-0.5 + 1*x2, inverse = TRUE),
                              lambda =   loglink( 0.5 + 2*x2, inverse = TRUE))
    zdata <- transform(zdata, y2 = rzipois(nn, lambda, pstr0 = pstr0))

    fit2 <- vglm(y2 ~ x2, zipoisson(zero = 1), data = zdata, trace = TRUE)
    coef(fit2, matrix = TRUE)  # Always a good idea
    coef(fit2)
    coef(fit2, colon = TRUE)
}

test_59 <- function() {
    # Fit the proportional odds model:
    pneumo <- transform(pneumo, let = log(exposure.time))
    (fit1 <- vglm(cbind(normal, mild, severe) ~ sm.bs(let, 3),
                  cumulative(parallel = TRUE, reverse = TRUE), data = pneumo))
    coef(fit1, matrix = TRUE)
    constraints(fit1)  # Parallel assumption results in this
    constraints(fit1, type = "term")  # Same as the default ("vlm"-type)
    is.parallel(fit1)

    # An equivalent model to fit1 (needs the type "term" constraints):
    clist.term <- constraints(fit1, type = "term")  # "term"-type constraints
    # cumulative() has no 'zero' argument to set to NULL (a good idea
    # when using the 'constraints' argument):
    (fit2 <- vglm(cbind(normal, mild, severe) ~ sm.bs(let, 3), data = pneumo,
                  cumulative(reverse = TRUE), constraints = clist.term))
    abs(max(coef(fit1, matrix = TRUE) -
            coef(fit2, matrix = TRUE)))  # Should be zero

    # Fit a rank-1 stereotype (RR-multinomial logit) model:
    fit <- rrvglm(Country ~ Width + Height + HP, multinomial, data = car.all)
    constraints(fit)  # All except the first are the estimated A matrix
}

test_60 <- function() {
    summary(corbet)
}

test_61 <- function() {
    pneumo <- transform(pneumo, let = log(exposure.time))
    (fit <- vglm(cbind(normal, mild, severe) ~ let,
                 cratio(parallel = TRUE), data = pneumo))
    coef(fit, matrix = TRUE)
    constraints(fit)
    predict(fit)
    predict(fit, untransform = TRUE)
    margeff(fit)
}

test_62 <- function() {
    pneumo <- transform(pneumo, let = log(exposure.time))
    (fit <- vglm(cbind(normal, mild, severe) ~ let, propodds, pneumo))
    fit@y        # Sample proportions (not recommended)
    depvar(fit)  # Better than using fit@y
    weights(fit, type = "prior")  # Number of observations
    # This is new:
    fit@family@infos()$muxypw  # Proportion or count?
    fit@family@infos()$Mux4vglmnet  # vglmnet needs counts?
    fit@family@infos()$roundmux  # Product is integer-valued?
    depvar(fit, muxypw = TRUE, roundmux = TRUE)  # Counts
}

test_63 <- function() {
    pneumo <- transform(pneumo, let = log(exposure.time))
    (fit <- vglm(cbind(normal, mild, severe) ~ let, propodds, pneumo))
    head(model.matrix(fit, type = "vlm"))
    head(model.matrix(fit, type = "lm"))

    df.residual(fit, type = "vlm")  # n * M - p_VLM
    nobs(fit, type = "vlm")  # n * M
    nvar(fit, type = "vlm")  # p_VLM

    df.residual(fit, type = "lm")  # n - p_LM(j)
    nobs(fit, type = "lm")  # n
    nvar(fit, type = "lm")  # p_LM
    nvar_vlm(fit, type = "lm")  # p_LM(j) (<= p_LM elementwise)
}

test_64 <- function() {
    odata <- data.frame(x2 = runif(nn <- 1000))  # Artificial data
    odata <- transform(odata, shape = loglink(-0.25 + x2, inv = TRUE))
    odata <- transform(odata, y1 = rdiffzeta(nn, shape))
    with(odata, table(y1))
    ofit <- vglm(y1 ~ x2, diffzeta, odata, trace = TRUE)
    coef(ofit, matrix = TRUE)
}

test_65 <- function() {
    ddata <- data.frame(rdiric(1000,
                        shape = exp(c(y1 = -1, y2 = 1, y3 = 0))))
    fit <- vglm(cbind(y1, y2, y3)  ~ 1, dirichlet,
                data = ddata, trace = TRUE, crit = "coef")
    Coef(fit)
    coef(fit, matrix = TRUE)
    head(fitted(fit))
}

test_66 <- function() {
    # Data from p.50 of Lange (2002)
    alleleCounts <- c(2, 84, 59, 41, 53, 131, 2, 0,
           0, 50, 137, 78, 54, 51, 0, 0,
           0, 80, 128, 26, 55, 95, 0, 0,
           0, 16, 40, 8, 68, 14, 7, 1)
    dim(alleleCounts) <- c(8, 4)
    alleleCounts <- data.frame(t(alleleCounts))
    dimnames(alleleCounts) <- list(c("White","Black","Chicano","Asian"),
                        paste("Allele", 5:12, sep = ""))

    set.seed(123)  # @initialize uses random numbers
    fit <- vglm(cbind(Allele5,Allele6,Allele7,Allele8,Allele9,
                      Allele10,Allele11,Allele12) ~ 1, dirmul.old,
                 trace = TRUE, crit = "c", data = alleleCounts)

    (sfit <- summary(fit))
    vcov(sfit)
    round(eta2theta(coef(fit),
                    fit@misc$link,
                    fit@misc$earg), digits = 2)  # not preferred
    round(Coef(fit), digits = 2)  # preferred
    round(t(fitted(fit)), digits = 4)  # 2nd row of Lange (2002, Table 3.5)
    coef(fit, matrix = TRUE)


    pfit <- vglm(cbind(Allele5,Allele6,Allele7,Allele8,Allele9,
                       Allele10,Allele11,Allele12) ~ 1,
                 dirmul.old(parallel = TRUE), trace = TRUE,
                 data = alleleCounts)
    round(eta2theta(coef(pfit, matrix = TRUE), pfit@misc$link,
                    pfit@misc$earg), digits = 2)  # 'Right' answer
    round(Coef(pfit), digits = 2)  # 'Wrong' due to parallelism constraint
}

test_67 <- function() {
    print(ducklings)
}

test_68 <- function() {
    fit1 <- vglm(BMI ~ ns(age, 4), extlogF1, data = bmi.nz)  # trace = TRUE
    eCDF(fit1)
    eCDF(fit1, all = TRUE)
}

test_69 <- function() {
    rate <- exp(2); myshape <- 3
    edata <- data.frame(y = rep(0, nn <- 1000))
    for (ii in 1:myshape)
      edata <- transform(edata, y = y + rexp(nn, rate = rate))
    fit <- vglm(y ~ 1, erlang(shape = myshape), edata, trace = TRUE)
    coef(fit, matrix = TRUE)
    Coef(fit)  # Answer = 1/rate
    1/rate
    summary(fit)
}

test_70 <- function() {
    # Ball bearings data (number of million revolutions before failure)
    edata <- data.frame(bbearings = c(17.88, 28.92, 33.00, 41.52, 42.12, 45.60,
    48.80, 51.84, 51.96, 54.12, 55.56, 67.80, 68.64, 68.64,
    68.88, 84.12, 93.12, 98.64, 105.12, 105.84, 127.92,
    128.04, 173.40))
    fit <- vglm(bbearings ~ 1, expexpff1(ishape = 4), trace = TRUE,
                maxit = 250, checkwz = FALSE, data = edata)
    coef(fit, matrix = TRUE)
    Coef(fit)  # Authors get c(0.0314, 5.2589) with log-lik -112.9763
    logLik(fit)
    fit@misc$shape  # Estimate of shape


    # Failure times of the airconditioning system of an airplane
    eedata <- data.frame(acplane = c(23, 261, 87, 7, 120, 14, 62, 47,
    225, 71, 246, 21, 42, 20, 5, 12, 120, 11, 3, 14,
    71, 11, 14, 11, 16, 90, 1, 16, 52, 95))
    fit <- vglm(acplane ~ 1, expexpff1(ishape = 0.8), trace = TRUE,
                maxit = 50, checkwz = FALSE, data = eedata)
    coef(fit, matrix = TRUE)
    Coef(fit)  # Authors get c(0.0145, 0.8130) with log-lik -152.264
    logLik(fit)
    fit@misc$shape  # Estimate of shape
}

test_71 <- function() {
    theta <- rnorm(30)
    explink(theta)
    max(abs(explink(explink(theta), inverse = TRUE) - theta))  # 0?
}

test_72 <- function() {
    edata <- data.frame(x2 = runif(nn <- 100) - 0.5)
    edata <- transform(edata, x3 = runif(nn) - 0.5)
    edata <- transform(edata, eta = 0.2 - 0.7 * x2 + 1.9 * x3)
    edata <- transform(edata, rate = exp(eta))
    edata <- transform(edata, y = rexp(nn, rate = rate))
    with(edata, stem(y))

    fit.slow <- vglm(y ~ x2 + x3, exponential, data = edata, trace = TRUE)
    fit.fast <- vglm(y ~ x2 + x3, exponential(exp = FALSE), data = edata,
                     trace = TRUE, crit = "coef")
    coef(fit.slow, mat = TRUE)
    summary(fit.slow)


    # Compare results with a GPD. Has a threshold.
    threshold <- 0.5
    gdata <- data.frame(y1 = threshold + rexp(n = 3000, rate = exp(1.5)))

    fit.exp <- vglm(y1 ~ 1, exponential(location = threshold), data = gdata)
    coef(fit.exp, matrix = TRUE)
    Coef(fit.exp)
    logLik(fit.exp)

    fit.gpd <- vglm(y1 ~ 1, gpd(threshold =  threshold), data = gdata)
    coef(fit.gpd, matrix = TRUE)
    Coef(fit.gpd)
    logLik(fit.gpd)
}

test_73 <- function() {
    summary(eyed)
}

test_74 <- function() {
    pneumo <- transform(pneumo, let = log(exposure.time))
    fit1 <- vglm(cbind(normal, mild, severe) ~ let,
                  cumulative(parallel = TRUE, reverse = TRUE), data = pneumo)
    familyname(fit1)
    familyname(fit1, all = TRUE)
    familyname(propodds())  # "cumulative"
}

test_75 <- function() {
    fit1 <- vglm(cbind(dead, n - dead) ~ logdose, trace = TRUE,
                 binomialff("probitlink"), fbeetle)
    summary(fit1)
}

test_76 <- function() {
    fdata <- data.frame(y = 2 * rpois(n = 200, 1) + 1)  # Not real data!
    fit <- vglm(y ~ 1, felix, data = fdata, trace = TRUE, crit = "coef")
    coef(fit, matrix = TRUE)
    Coef(fit)
    summary(fit)
}

test_77 <- function() {
    data(finney44)
    transform(finney44, mortality = unhatched / (hatched + unhatched))
}

test_78 <- function() {
    fdata <- data.frame(y = rfisk(200, shape = exp(1), exp(2)))
    fit <- vglm(y ~ 1, fisk(lss = FALSE), data = fdata, trace = TRUE)
    fit <- vglm(y ~ 1, fisk(ishape1.a = exp(2)), fdata, trace = TRUE)
    coef(fit, matrix = TRUE)
    Coef(fit)
    summary(fit)
}

test_79 <- function() {
    # Categorical regression example 1
    pneumo <- transform(pneumo, let = log(exposure.time))
    (fit1 <- vglm(cbind(normal, mild, severe) ~ let, propodds, pneumo))
    fitted(fit1)

    # LMS quantile regression example 2
    fit2 <- vgam(BMI ~ s(age, df = c(4, 2)),
                 lms.bcn(zero = 1), data = bmi.nz, trace = TRUE)
    head(predict(fit2, type = "response"))  # Equals to both these:
    head(fitted(fit2))
    predict(fit2, type = "response", newdata = head(bmi.nz))

    # Zero-inflated example 3
    zdata <- data.frame(x2 = runif(nn <- 1000))
    zdata <- transform(zdata,
                       pstr0.3  = logitlink(-0.5       , inverse = TRUE),
                       lambda.3 =   loglink(-0.5 + 2*x2, inverse = TRUE))
    zdata <- transform(zdata,
             y1 = rzipois(nn, lambda = lambda.3, pstr0 = pstr0.3))
    fit3 <- vglm(y1 ~ x2, zipoisson(zero = NULL), zdata, trace = TRUE)
    head(fitted(fit3, type.fitted = "mean" ))  # E(Y) (the default)
    head(fitted(fit3, type.fitted = "pobs0"))  # Pr(Y = 0)
    head(fitted(fit3, type.fitted = "pstr0"))  # Prob of a structural 0
    head(fitted(fit3, type.fitted = "onempstr0"))  # 1 - Pr(structural 0)
}

test_80 <- function() {
    # Example: this is based on a glm example
    counts <- c(18,17,15,20,10,20,25,13,12)
    outcome <- gl(3, 1, 9); treatment <- gl(3, 3)
    vglm.D93 <- vglm(counts ~ outcome + treatment, family = poissonff)
    formula(vglm.D93)
    pdata <- data.frame(counts, outcome, treatment)  # Better style
    vglm.D93 <- vglm(counts ~ outcome + treatment, poissonff, data = pdata)
    formula(vglm.D93)
    term.names(vglm.D93)
    responseName(vglm.D93)
    has.intercept(vglm.D93)
}

test_81 <- function() {
    fdata <- data.frame(y1 = rexp(nn <- 1000, rate = exp(1)))
    fdata <- transform(fdata, y2 = rexp(nn, rate = exp(2)))
    fit1 <- vglm(cbind(y1, y2) ~ 1, freund61, fdata, trace = TRUE)
    coef(fit1, matrix = TRUE)
    Coef(fit1)
    vcov(fit1)
    head(fitted(fit1))
    summary(fit1)

    # y1 and y2 are independent, so fit an independence model
    fit2 <- vglm(cbind(y1, y2) ~ 1, freund61(indep = TRUE),
                 data = fdata, trace = TRUE)
    coef(fit2, matrix = TRUE)
    constraints(fit2)
    pchisq(2 * (logLik(fit1) - logLik(fit2)),  # p-value
           df = df.residual(fit2) - df.residual(fit1),
           lower.tail = FALSE)
    lrtest(fit1, fit2)  # Better alternative
}

test_82 <- function() {
    gdata <- data.frame(y = rgamma(n = 100, shape = exp(3)))
    fit <- vglm(y ~ 1, gamma1, data = gdata, trace = TRUE, crit = "coef")
    coef(fit, matrix = TRUE)
    Coef(fit)
    summary(fit)
}

test_83 <- function() {
    # Essentially a 1-parameter gamma
    gdata <- data.frame(y = rgamma(n = 100, shape = exp(1)))
    fit1 <- vglm(y ~ 1, gamma1, data = gdata)
    fit2 <- vglm(y ~ 1, gamma2, data = gdata, trace = TRUE, crit = "coef")
    coef(fit2, matrix = TRUE)
    c(Coef(fit2), colMeans(gdata))

    # Essentially a 2-parameter gamma
    gdata <- data.frame(y = rgamma(n = 500, rate = exp(-1), shape = exp(2)))
    fit2 <- vglm(y ~ 1, gamma2, data = gdata, trace = TRUE, crit = "coef")
    coef(fit2, matrix = TRUE)
    c(Coef(fit2), colMeans(gdata))
    summary(fit2)
}

test_84 <- function() {
    # Essentially a 1-parameter gamma
    gdata <- data.frame(y1 = rgamma(n <- 100, shape =  exp(1)))
    fit1 <- vglm(y1 ~ 1, gamma1, data = gdata, trace = TRUE)
    fit2 <- vglm(y1 ~ 1, gammaR, data = gdata, trace = TRUE, crit = "coef")
    coef(fit2, matrix = TRUE)
    Coef(fit2)

    # Essentially a 2-parameter gamma
    gdata <- data.frame(y2 = rgamma(n = 500, rate = exp(1), shape = exp(2)))
    fit2 <- vglm(y2 ~ 1, gammaR, data = gdata, trace = TRUE, crit = "coef")
    coef(fit2, matrix = TRUE)
    Coef(fit2)
    summary(fit2)
}

test_85 <- function() {
    gdata <- data.frame(x2 = runif(nn <- 1000))
    gdata <- transform(gdata, theta = exp(-2 + x2))
    gdata <- transform(gdata, y1 = rexp(nn, rate = exp(-theta)/theta),
                              y2 = rexp(nn, rate = theta) + 1)
    fit <- vglm(cbind(y1, y2) ~ x2, gammahyperbola(expected = TRUE), data = gdata)
    coef(fit, matrix = TRUE)
    Coef(fit)
    head(fitted(fit))
    summary(fit)
}

test_86 <- function() {
    gdata <- data.frame(x2 = runif(nn <- 500))
    gdata <- transform(gdata, y1 = rgenpois0(nn, theta = exp(2 + x2),
                                             logitlink(1, inverse = TRUE)))
    gfit0 <- vglm(y1 ~ x2, genpoisson0, data = gdata, trace = TRUE)
    coef(gfit0, matrix = TRUE)
    summary(gfit0)
}

test_87 <- function() {
    gdata <- data.frame(x2 = runif(nn <- 500))
    gdata <- transform(gdata, y1 = rgenpois1(nn, exp(2 + x2),
                                   logloglink(-1, inverse = TRUE)))
    gfit1 <- vglm(y1 ~ x2, genpoisson1, gdata, trace = TRUE)
    coef(gfit1, matrix = TRUE)
    summary(gfit1)
}

test_88 <- function() {
    gdata <- data.frame(x2 = runif(nn <- 500))
    gdata <- transform(gdata, y1 = rgenpois2(nn, exp(2 + x2),
                                   loglink(-1, inverse = TRUE)))
    gfit2 <- vglm(y1 ~ x2, genpoisson2, gdata, trace = TRUE)
    coef(gfit2, matrix = TRUE)
    summary(gfit2)
}

test_89 <- function() {
    sh <- -pi / 2; loc <- 2
    hdata <- data.frame(x2 = rnorm(nn <- 200))
    hdata <- transform(hdata, y = rgensh(nn, sh, loc))
    fit <- vglm(y ~ x2, gensh(sh), hdata, trace = TRUE)
    coef(fit, matrix = TRUE)
}

test_90 <- function() {
    gdata <- data.frame(x2 = runif(nn <- 1000) - 0.5)
    gdata <- transform(gdata, x3 = runif(nn) - 0.5,
                              x4 = runif(nn) - 0.5)
    gdata <- transform(gdata, eta  = -1.0 - 1.0 * x2 + 2.0 * x3)
    gdata <- transform(gdata, prob = logitlink(eta, inverse = TRUE))
    gdata <- transform(gdata, y1 = rgeom(nn, prob))
    with(gdata, table(y1))
    fit1 <- vglm(y1 ~ x2 + x3 + x4, geometric, data = gdata, trace = TRUE)
    coef(fit1, matrix = TRUE)
    summary(fit1)

    # Truncated geometric (between 0 and upper.limit)
    upper.limit <- 5
    tdata <- subset(gdata, y1 <= upper.limit)
    nrow(tdata)  # Less than nn
    fit2 <- vglm(y1 ~ x2 + x3 + x4, truncgeometric(upper.limit),
                 data = tdata, trace = TRUE)
    coef(fit2, matrix = TRUE)

    # Generalized truncated geometric (between lower.limit and upper.limit)
    lower.limit <- 1
    upper.limit <- 8
    gtdata <- subset(gdata, lower.limit <= y1 & y1 <= upper.limit)
    with(gtdata, table(y1))
    nrow(gtdata)  # Less than nn
    fit3 <- vglm(y1 - lower.limit ~ x2 + x3 + x4,
                 truncgeometric(upper.limit - lower.limit),
                 data = gtdata, trace = TRUE)
    coef(fit3, matrix = TRUE)
}

test_91 <- function() {
    print(sm.min1)
}

test_92 <- function() {
    str(gew)
}

test_93 <- function() {
    gdata <- data.frame(x2 = runif(nn <- 1000))
    gdata <- transform(gdata, heta1  = +1,
                              heta2  = -1 + 0.1 * x2,
                              ceta1 =  0,
                              ceta2 =  1)
    gdata <- transform(gdata, shape1 = exp(heta1),
                              shape2 = exp(heta2),
                              scale1 = exp(ceta1),
                              scale2 = exp(ceta2))
    gdata <- transform(gdata,
                       y1 = rgumbelII(nn, scale = scale1, shape = shape1),
                       y2 = rgumbelII(nn, scale = scale2, shape = shape2))

    fit <- vglm(cbind(y1, y2) ~ x2,
                gumbelII(zero = c(1, 2, 3)), data = gdata, trace = TRUE)
    coef(fit, matrix = TRUE)
    vcov(fit)
    summary(fit)
}

test_94 <- function() {
    # Example: this is based on a glm example
    counts <- c(18,17,15,20,10,20,25,13,12)
    outcome <- gl(3, 1, 9); treatment <- gl(3, 3)
    pdata <- data.frame(counts, outcome, treatment)  # Better style
    vglm.D93 <- vglm(counts ~ outcome + treatment, poissonff, data = pdata)
    formula(vglm.D93)
    term.names(vglm.D93)
    responseName(vglm.D93)
    has.intercept(vglm.D93)
}

test_95 <- function() {
    pneumo <- transform(pneumo, let = log(exposure.time))
    fit <- vglm(cbind(normal, mild, severe) ~ let, data = pneumo,
                trace = TRUE, crit = "c",  # Get some more accuracy
                cumulative(reverse = TRUE,  parallel = TRUE))
    cumulative()@infos()$hadof  # Analytical solution implemented
    hdeff(fit)
    hdeff(fit, deriv = 1)  # Analytical solution
    hdeff(fit, deriv = 2)  # It is a partial analytical solution
    hdeff(fit, deriv = 2, se.arg = TRUE,
          fd.only = TRUE)  # All derivatives solved numerically by FDs

    # 2 x 2 table of counts
    R0 <- 25; N0 <- 100  # Hauck Donner (1977) data set
    mymat <- c(N0-R0, R0, 8, 92)  # HDE present
    (mymat <- matrix(mymat, 2, 2, byrow = TRUE))
    hdeff(mymat)
    hdeff(c(mymat))  # Input is a vector
    hdeff(c(t(mymat)), byrow = TRUE)  # Reordering of the data
}

test_96 <- function() {
    example(genpoisson0)
    summary(gfit0, wsdm = TRUE)
    hdeffsev(gfit0)
}

test_97 <- function() {
    deg <- 4  # myfun is a function that approximates the HDE
    myfun <- function(x, deriv = 0) switch(as.character(deriv),
      '0' = x^deg * exp(-x),
      '1' = (deg * x^(deg-1) - x^deg) * exp(-x),
      '2' = (deg*(deg-1)*x^(deg-2) - 2*deg*x^(deg-1) + x^deg)*exp(-x))

    xgrid <- seq(0, 10, length = 101)
    ansm <- hdeffsev0(xgrid, myfun(xgrid), myfun(xgrid, deriv = 1),
                     myfun(xgrid, deriv = 2), allofit = TRUE)
    digg <- 4
    cbind(severity = ansm$sev, 
          fun      = round(myfun(xgrid), digg),
          deriv1   = round(myfun(xgrid, deriv = 1), digg),
          deriv2   = round(myfun(xgrid, deriv = 2), digg),
          zderiv1  = round(1 + (myfun(xgrid, deriv = 1))^2 +
                           myfun(xgrid, deriv = 2) * myfun(xgrid), digg))
}

test_98 <- function() {
    nn <- 100; set.seed(1)
    hdata <- data.frame(x2 = runif(nn))
    hdata <-
      transform(hdata,  # Cannot generate proper random variates!
        y1 = rbeta(nn, shape1 = 0.5, shape2 = 0.5),  # "U" shaped
        y2 = rnorm(nn, 0.65, sd = exp(-3 - 4 * x2)))
    # Multiple responses:
    hfit <- vglm(cbind(y1, y2) ~ x2, hurea, hdata, trace = TRUE)
    coef(hfit, matrix = TRUE)
    summary(hfit)
}

test_99 <- function() {
    nn <- 100
    m <- 5  # Number of white balls in the population
    k <- rep(4, len = nn)  # Sample sizes
    n <- 4  # Number of black balls in the population
    y  <- rhyper(nn = nn, m = m, n = n, k = k)
    yprop <- y / k  # Sample proportions

    # N is unknown, D is known. Both models are equivalent:
    fit <- vglm(cbind(y,k-y) ~ 1, hyperg(D = m), trace = TRUE, crit = "c")
    fit <- vglm(yprop ~ 1, hyperg(D = m), weight = k, trace = TRUE, crit = "c")

    # N is known, D is unknown. Both models are equivalent:
    fit <- vglm(cbind(y, k-y) ~ 1, hyperg(N = m+n), trace = TRUE, crit = "l")
    fit <- vglm(yprop ~ 1, hyperg(N = m+n), weight = k, trace = TRUE, crit = "l")

    coef(fit, matrix = TRUE)
    Coef(fit)  # Should be equal to the true population proportion
    unique(m / (m+n))  # The true population proportion
    fit@extra
    head(fitted(fit))
    summary(fit)
}

test_100 <- function() {
    hdata <- data.frame(x2 = rnorm(nn <- 200))
    hdata <- transform(hdata, y = rnorm(nn))  # Not very good data!
    fit1 <- vglm(y ~ x2, hypersecant, hdata, trace = TRUE, crit = "c")
    coef(fit1, matrix = TRUE)
    fit1@misc$earg

    # Not recommended:
    fit2 <- vglm(y ~ x2, hypersecant(link = "identitylink"), hdata)
    coef(fit2, matrix = TRUE)
    fit2@misc$earg
}

test_101 <- function() {
    shape <- exp(exp(-0.1))  # The parameter
    hdata <- data.frame(y = rhzeta(n = 1000, shape))
    fit <- vglm(y ~ 1, hzeta, data = hdata, trace = TRUE, crit = "coef")
    coef(fit, matrix = TRUE)
    Coef(fit)  # Useful for intercept-only models; should be same as shape
    c(with(hdata, mean(y)), head(fitted(fit), 1))
    summary(fit)
}

test_102 <- function() {
    iam(1, 2, M = 3)  # The 4th coln represents elt (1,2) of a 3x3 matrix
    iam(NULL, NULL, M = 3, both = TRUE)  # Return the row & column indices

    dirichlet()@weight

    M <- 4
    temp1 <- iam(NA, NA, M = M, both = TRUE)
    mat1 <- matrix(NA, M, M)
    mat1[cbind(temp1$row, temp1$col)] = 1:length(temp1$row)
    mat1  # More commonly used

    temp2 <- iam(NA, NA, M = M, both = TRUE, diag = FALSE)
    mat2 <- matrix(NA, M, M)
    mat2[cbind(temp2$row, temp2$col)] = 1:length(temp2$row)
    mat2  # Rarely used
}

test_103 <- function() {
    identitylink((-5):5)
    identitylink((-5):5, deriv = 1)
    identitylink((-5):5, deriv = 2)
    negidentitylink((-5):5)
    negidentitylink((-5):5, deriv = 1)
    negidentitylink((-5):5, deriv = 2)
}

test_104 <- function() {
    idata <- data.frame(y = rnbinom(n <- 1000, mu = exp(3), size = exp(1)))
    fit <- vglm(y ~ 1, inv.binomial, data = idata, trace = TRUE)
    with(idata, c(mean(y), head(fitted(fit), 1)))
    summary(fit)
    coef(fit, matrix = TRUE)
    Coef(fit)
    sum(weights(fit))  # Sum of the prior weights
    sum(weights(fit, type = "work"))  # Sum of the working weights
}

test_105 <- function() {
    idata <- data.frame(x2 = runif(nn <- 1000))
    idata <- transform(idata, mymu   = exp(2 + 1 * x2),
                              Lambda = exp(2 + 1 * x2))
    idata <- transform(idata, y = rinv.gaussian(nn, mu = mymu, Lambda))
    fit1 <-   vglm(y ~ x2, inv.gaussianff, data = idata, trace = TRUE)
    rrig <- rrvglm(y ~ x2, inv.gaussianff, data = idata, trace = TRUE)
    coef(fit1, matrix = TRUE)
    coef(rrig, matrix = TRUE)
    Coef(rrig)
    summary(fit1)
}

test_106 <- function() {
    idata <- data.frame(y = rinv.lomax(2000, sc = exp(2), exp(1)))
    fit <- vglm(y ~ 1, inv.lomax, data = idata, trace = TRUE)
    fit <- vglm(y ~ 1, inv.lomax(iscale = exp(3)), data = idata,
                trace = TRUE, epsilon = 1e-8, crit = "coef")
    coef(fit, matrix = TRUE)
    Coef(fit)
    summary(fit)
}

test_107 <- function() {
    fit1 <- vgam(cbind(agaaus, kniexc) ~ s(altitude, df = c(3, 4)),
                 binomialff(multiple.responses = TRUE), data = hunua)
    is.buggy(fit1)  # Okay
    is.buggy(fit1, each.term = TRUE)  # No terms are buggy
    fit2 <-
      vgam(cbind(agaaus, kniexc) ~ s(altitude, df = c(3, 4)),
           binomialff(multiple.responses = TRUE), data = hunua,
           constraints =
           list("(Intercept)" = diag(2),
                "s(altitude, df = c(3, 4))" = matrix(c(1, 1, 0, 1), 2, 2)))
    is.buggy(fit2)  # TRUE
    is.buggy(fit2, each.term = TRUE)
    constraints(fit2)

    # fit2b is an approximate alternative to fit2:
    fit2b <-
      vglm(cbind(agaaus, kniexc) ~ bs(altitude, df=3) + bs(altitude, df=4),
           binomialff(multiple.responses = TRUE), data = hunua,
           constraints =
             list("(Intercept)" = diag(2),
                  "bs(altitude, df = 3)" = rbind(1, 1),
                  "bs(altitude, df = 4)" = rbind(0, 1)))
    is.buggy(fit2b)  # Okay
    is.buggy(fit2b, each.term = TRUE)
    constraints(fit2b)
}

test_108 <- function() {
    coalminers <- transform(coalminers, Age = (age - 42) / 5)
    fit <- vglm(cbind(nBnW,nBW,BnW,BW) ~ Age, binom2.or(zero = NULL),
                data = coalminers)
    is.zero(fit)
    is.zero(coef(fit, matrix = TRUE))
}

test_109 <- function() {
    shape1 <- exp(1); shape2 <- exp(2)
    kdata <- data.frame(y = rkumar(n = 1000, shape1, shape2))
    fit <- vglm(y ~ 1, kumar, data = kdata, trace = TRUE)
    c(with(kdata, mean(y)), head(fitted(fit), 1))
    coef(fit, matrix = TRUE)
    Coef(fit)
    summary(fit)
}

test_110 <- function() {
    data(lakeO)
    lakeO
    summary(lakeO)
}

test_111 <- function() {
    ldata <- data.frame(y = rlaplace(nn <- 100, 2, scale = exp(1)))
    fit <- vglm(y  ~ 1, laplace, ldata, trace = TRUE)
    coef(fit, matrix = TRUE)
    Coef(fit)
    with(ldata, median(y))

    ldata <- data.frame(x = runif(nn <- 1001))
    ldata <- transform(ldata, y = rlaplace(nn, 2, scale = exp(-1 + 1*x)))
    coef(vglm(y ~ x, laplace(iloc = 0.2, imethod = 2, zero = 1), ldata,
              trace = TRUE), matrix = TRUE)
}

test_112 <- function() {
    ldata <- data.frame(y = rnorm(2000, 0.5, 0.1))  # Improper data
    fit <- vglm(y ~ 1, leipnik(ilambda = 1), ldata, trace = TRUE)
    head(fitted(fit))
    with(ldata, mean(y))
    summary(fit)
    coef(fit, matrix = TRUE)
    Coef(fit)

    sum(weights(fit))  # Sum of the prior weights
    sum(weights(fit, type = "work"))  # Sum of the working weights
}

test_113 <- function() {
    nn <- 1000; loc1 <- 0; loc2 <- 10
    myscale <- 1  # log link ==> 0 is the answer
    ldata <-
      data.frame(y1 = loc1 + myscale/rnorm(nn)^2,  # Levy(myscale, a)
                 y2 = rlevy(nn, loc = loc2, scale = exp(+2)))
    # Cf. Table 1.1 of Nolan for Levy(1,0)
    with(ldata, sum(y1 > 1) / length(y1))  # Should be 0.6827
    with(ldata, sum(y1 > 2) / length(y1))  # Should be 0.5205

    fit1 <- vglm(y1 ~ 1, levy(location = loc1), ldata, trace = TRUE)
    coef(fit1, matrix = TRUE)
    Coef(fit1)
    summary(fit1)
    head(weights(fit1, type = "work"))

    fit2 <- vglm(y2 ~ 1, levy(location = loc2), ldata, trace = TRUE)
    coef(fit2, matrix = TRUE)
    Coef(fit2)
    c(median = with(ldata, median(y2)),
      fitted.median = head(fitted(fit2), 1))
}

test_114 <- function() {
    ldata <- data.frame(y = rlgamma(100, shape = exp(1)))
    fit <- vglm(y ~ 1, lgamma1, ldata, trace = TRUE, crit = "coef")
    summary(fit)
    coef(fit, matrix = TRUE)
    Coef(fit)

    ldata <- data.frame(x2 = runif(nn <- 5000))  # Another example
    ldata <- transform(ldata, loc = -1 + 2 * x2, Scale = exp(1))
    ldata <- transform(ldata, y = rlgamma(nn, loc, sc = Scale, sh = exp(0)))
    fit2 <- vglm(y ~ x2, lgamma3, data = ldata, trace = TRUE, crit = "c")
    coef(fit2, matrix = TRUE)
}

test_115 <- function() {
    ldata <- data.frame(y = rlind(n = 1000, theta = exp(3)))
    fit <- vglm(y ~ 1, lindley, data = ldata, trace = TRUE, crit = "coef")
    coef(fit, matrix = TRUE)
    Coef(fit)
    summary(fit)
}

test_116 <- function() {
    pneumo <- transform(pneumo, let = log(exposure.time))
    fit1 <- vglm(cbind(normal, mild, severe) ~ let, propodds, data = pneumo)
    coef(fit1, matrix = TRUE)
    linkfun(fit1)
    linkfun(fit1, earg = TRUE)

    fit2 <- vglm(cbind(normal, mild, severe) ~ let, multinomial, data = pneumo)
    coef(fit2, matrix = TRUE)
    linkfun(fit2)
    linkfun(fit2, earg = TRUE)
}

test_117 <- function() {
    ldata <- data.frame(y1 = rbeta(n = 1000, exp(0.5), exp(1)))  # Std beta
    fit <- vglm(y1 ~ 1, lino, data = ldata, trace = TRUE)
    coef(fit, matrix = TRUE)
    Coef(fit)
    head(fitted(fit))
    summary(fit)

    # Nonstandard beta distribution
    ldata <- transform(ldata, y2 = rlino(1000, shape1 = exp(1),
                                         shape2 = exp(2), lambda = exp(1)))
    fit2 <- vglm(y2 ~ 1,
                 lino(lshape1 = "identitylink", lshape2 = "identitylink",
                      ilamb = 10), data = ldata, trace = TRUE)
    coef(fit2, matrix = TRUE)
}

test_118 <- function() {
    x <-  c(10, 50, 100, 200, 400, 500, 800, 1000, 1e4, 1e5, 1e20, Inf, NA)
    log1pexp(x)
    log(1 + exp(x))  # Naive; suffers from overflow
    log1mexp(x)
    log(1 - exp(-x))
    y <- -x
    log1pexp(y)
    log(1 + exp(y))  # Naive; suffers from inaccuracy
}

test_119 <- function() {
    nn <- 1000
    ldata <- data.frame(y1 = rnorm(nn, +1, sd = exp(2)),  # Not proper data
                        x2 = rnorm(nn, -1, sd = exp(2)),
                        y2 = rnorm(nn, -1, sd = exp(2)))  # Not proper data
    fit1 <- vglm(y1 ~ 1 , logF, ldata, trace = TRUE)
    fit2 <- vglm(y2 ~ x2, logF, ldata, trace = TRUE)
    coef(fit2, matrix = TRUE)
    summary(fit2)
    vcov(fit2)

    head(fitted(fit1))
    with(ldata, mean(y1))
    max(abs(head(fitted(fit1)) - with(ldata, mean(y1))))
}

test_120 <- function() {
    zdata <- data.frame(x2 = runif(nn <- 50))
    zdata <- transform(zdata, Ps01    = logitlink(-0.5       , inverse = TRUE),
                              Ps02    = logitlink( 0.5       , inverse = TRUE),
                              lambda1 =  loglink(-0.5 + 2*x2, inverse = TRUE),
                              lambda2 =  loglink( 0.5 + 2*x2, inverse = TRUE))
    zdata <- transform(zdata, y1 = rzipois(nn, lambda = lambda1, pstr0 = Ps01),
                              y2 = rzipois(nn, lambda = lambda2, pstr0 = Ps02))

    with(zdata, table(y1))  # Eyeball the data
    with(zdata, table(y2))
    fit2 <- vglm(cbind(y1, y2) ~ x2, zipoisson(zero = NULL), data = zdata)

    logLik(fit2)  # Summed over the two responses
    sum(logLik(fit2, sum = FALSE))  # For checking purposes
    (ll.matrix <- logLik(fit2, sum = FALSE))  # nn x 2 matrix
    colSums(ll.matrix)  # log-likelihood for each response
}

test_121 <- function() {
    # Location unknown, scale known
    ldata <- data.frame(x2 = runif(nn <- 500))
    ldata <- transform(ldata, y1 = rlogis(nn, loc = 1+5*x2, sc = exp(2)))
    fit1 <- vglm(y1 ~ x2, logistic1(scale = exp(2)), ldata, trace = TRUE)
    coef(fit1, matrix = TRUE)

    # Both location and scale unknown
    ldata <- transform(ldata, y2 = rlogis(nn, loc = 1 + 5*x2, exp(x2)))
    fit2 <- vglm(cbind(y1, y2) ~ x2, logistic, data = ldata, trace = TRUE)
    coef(fit2, matrix = TRUE)
    vcov(fit2)
    summary(fit2)
}

test_122 <- function() {
    p <- seq(0.05, 0.99, by = 0.01); myoff <- 0.05
    logitoffsetlink(p, myoff)
    max(abs(logitoffsetlink(logitoffsetlink(p, myoff),
            myoff, inverse = TRUE) - p))  # Should be 0
}

test_123 <- function() {
    coalminers <- transform(coalminers, Age = (age - 42) / 5)
    # Get the n x 4 matrix of counts
    fit0 <- vglm(cbind(nBnW,nBW,BnW,BW) ~ Age, binom2.or, coalminers)
    counts <- round(c(weights(fit0, type = "prior")) * depvar(fit0))
    # Create a n x 2 matrix response for loglinb2()
    # bwmat <- matrix(c(0,0, 0,1, 1,0, 1,1), 4, 2, byrow = TRUE)
    bwmat <- cbind(bln = c(0,0,1,1), wheeze = c(0,1,0,1))
    matof1 <- matrix(1, nrow(counts), 1)
    newminers <-
      data.frame(bln    = kronecker(matof1, bwmat[, 1]),
                 wheeze = kronecker(matof1, bwmat[, 2]),
                 wt     = c(t(counts)),
                 Age    = with(coalminers, rep(age, rep(4, length(age)))))
    newminers <- newminers[with(newminers, wt) > 0,]

    fit <- vglm(cbind(bln,wheeze) ~ Age, loglinb2(zero = NULL),
                weight = wt, data = newminers)
    coef(fit, matrix = TRUE)  # Same! (at least for the log odds-ratio)
    summary(fit)

    # Try reconcile this with McCullagh and Nelder (1989), p.234
    (0.166-0.131) / 0.027458   # 1.275 is approximately 1.25
}

test_124 <- function() {
    lfit1 <- vglm(cbind(cyadea, beitaw, kniexc) ~ altitude,
                 loglinb3, data = hunua, trace = TRUE)
    coef(lfit1, matrix = TRUE)
    lfit2 <- vglm(cbind(cyadea, beitaw, kniexc) ~ altitude,
                 loglinb3(u123 = TRUE), hunua, trace = TRUE)
    coef(lfit2, matrix = TRUE)
    head(fitted(lfit2))
    summary(lfit2)
}

test_125 <- function() {
    lfit4 <- vglm(cbind(cyadea, beitaw, kniexc, vitluc) ~ altitude,
                  loglinb4, hunua, trace = TRUE)
    coef(lfit4, matrix = TRUE)
    head(fitted(lfit4))
    head(predict(lfit4))
    summary(lfit4, HDEtest = FALSE)
}

test_126 <- function() {
    x <- seq(0.8, 1.5, by = 0.1)
    logloglink(x)  # Has NAs
    logloglink(x, bvalue = 1.0 + .Machine$double.eps)  # Has no NAs

    x <- seq(1.01, 10, len = 100)
    logloglink(x)
    max(abs(logloglink(logloglink(x), inverse = TRUE) - x))  # 0?
}

test_127 <- function() {
    ldata2 <- data.frame(x2 = runif(nn <- 1000))
    ldata2 <- transform(ldata2, y1 = rlnorm(nn, 1 + 2 * x2, sd = exp(-1)),
                                y2 = rlnorm(nn, 1, sd = exp(-1 + x2)))
    fit1 <- vglm(y1 ~ x2, lognormal(zero = 2), data = ldata2, trace = TRUE)
    fit2 <- vglm(y2 ~ x2, lognormal(zero = 1), data = ldata2, trace = TRUE)
    coef(fit1, matrix = TRUE)
    coef(fit2, matrix = TRUE)
}

test_128 <- function() {
    ldata <- data.frame(y = rlomax(n = 1000, scale =  exp(1), exp(2)))
    fit <- vglm(y ~ 1, lomax, data = ldata, trace = TRUE)
    coef(fit, matrix = TRUE)
    Coef(fit)
    summary(fit)
}

test_129 <- function() {
    set.seed(1)
    pneumo <- transform(pneumo, let = log(exposure.time),
                                x3 = rnorm(nrow(pneumo)))
    fit <- vglm(cbind(normal, mild, severe) ~ let, propodds, pneumo)
    cbind(coef(summary(fit)),
          "signed LRT stat" = lrt.stat(fit, omit1s = FALSE))
    summary(fit, lrt0 = TRUE)  # Easy way to get it
}

test_130 <- function() {
    set.seed(1)
    pneumo <- transform(pneumo, let = log(exposure.time),
                                x3  = runif(nrow(pneumo)))
    fit1 <- vglm(cbind(normal, mild, severe) ~ let     , propodds, pneumo)
    fit2 <- vglm(cbind(normal, mild, severe) ~ let + x3, propodds, pneumo)
    fit3 <- vglm(cbind(normal, mild, severe) ~ let     , cumulative, pneumo)
    # Various equivalent specifications of the LR test for testing x3
    (ans1 <- lrtest(fit2, fit1))
    ans2 <- lrtest(fit2, 2)
    ans3 <- lrtest(fit2, "x3")
    ans4 <- lrtest(fit2, . ~ . - x3)
    c(all.equal(ans1, ans2), all.equal(ans1, ans3), all.equal(ans1, ans4))

    # Doing it manually
    (testStatistic <- 2 * (logLik(fit2) - logLik(fit1)))
    (pval <- pchisq(testStatistic, df = df.residual(fit1) - df.residual(fit2),
                    lower.tail = FALSE))

    (ans4 <- lrtest(fit3, fit1))  # Test PO (parallelism) assumption
}

test_131 <- function() {
    # Not a good example for multinomial() since the response is ordinal!!
    ii <- 3; hh <- 1/100
    pneumo <- transform(pneumo, let = log(exposure.time))
    fit <- vglm(cbind(normal, mild, severe) ~ let, multinomial, pneumo)
    fit <- vglm(cbind(normal, mild, severe) ~ let,
                cumulative(reverse = TRUE,  parallel = TRUE),
                data = pneumo)
    fitted(fit)[ii, ]

    mynewdata <- with(pneumo, data.frame(let = let[ii] + hh))
    (newp <- predict(fit, newdata = mynewdata, type = "response"))

    # Compare the difference. Should be the same as hh --> 0.
    round((newp-fitted(fit)[ii, ]) / hh, 3)  # Finite-diff approxn
    round(margeff(fit, subset = ii)["let",], 3)

    # Other examples
    round(margeff(fit), 3)
    round(margeff(fit, subset = 2)["let",], 3)
    round(margeff(fit, subset = c(FALSE, TRUE))["let",,], 3)  # Recycling
    round(margeff(fit, subset = c(2, 4, 6, 8))["let",,], 3)

    # Example 3; margeffs at a new value
    mynewdata2a <- data.frame(let = 2)  # New value
    mynewdata2b <- data.frame(let = 2 + hh)  # For finite-diff approxn
    (neweta2 <- predict(fit, newdata = mynewdata2a))
    fit@x[1, ] <- c(1, unlist(mynewdata2a))
    fit@predictors[1, ] <- neweta2  # Needed
    max(abs(margeff(fit, subset = 1)["let", ] - (
            predict(fit, newdata = mynewdata2b, type = "response") -
            predict(fit, newdata = mynewdata2a, type = "response")) / hh
    ))  # Should be 0
}

test_132 <- function() {
    summary(marital.nz)
}

test_133 <- function() {
    mdata <- data.frame(y = rmaxwell(1000, rate = exp(2)))
    fit <- vglm(y ~ 1, maxwell, mdata, trace = TRUE, crit = "coef")
    coef(fit, matrix = TRUE)
    Coef(fit)
}

test_134 <- function() {
    # Limit as theta = 0, nu = Inf:
    mdata <- data.frame(y = rnorm(1000, sd = 0.2))
    fit <- vglm(y ~ 1, mccullagh89, data = mdata, trace = TRUE)
    head(fitted(fit))
    with(mdata, mean(y))
    summary(fit)
    coef(fit, matrix = TRUE)
    Coef(fit)
}

test_135 <- function() {
    i.mix <- seq(0, 15, by = 5)
    lambda.p <- 10
    meangaitd(lambda.p, a.mix = i.mix + 1, i.mix = i.mix,
              max.support = 17, pobs.mix = 0.1, pstr.mix = 0.1)
}

test_136 <- function() {
    # Illustrates smart prediction
    pneumo <- transform(pneumo, let = log(exposure.time))
    fit <- vglm(cbind(normal,mild, severe) ~ poly(c(scale(let)), 2),
                multinomial, pneumo, trace = TRUE, x = FALSE)
    class(fit)

    check1 <- head(model.frame(fit))
    check1
    check2 <- model.frame(fit, data = head(pneumo))
    check2
    all.equal(unlist(check1), unlist(check2))  # Should be TRUE

    q0 <- head(predict(fit))
    q1 <- head(predict(fit, newdata = pneumo))
    q2 <- predict(fit, newdata = head(pneumo))
    all.equal(q0, q1)  # Should be TRUE
    all.equal(q1, q2)  # Should be TRUE
}

test_137 <- function() {
    # (I) Illustrates smart prediction ,,,,,,,,,,,,,,,,,,,,,,,
    pneumo <- transform(pneumo, let = log(exposure.time))
    fit <- vglm(cbind(normal, mild, severe) ~
                sm.poly(c(sm.scale(let)), 2),
                multinomial, data = pneumo, trace = TRUE, x = FALSE)
    class(fit)
    fit@smart.prediction  # Data-dependent parameters
    fit@x # Not saved on the object
    model.matrix(fit)
    model.matrix(fit, linpred.index = 1, type = "lm")
    model.matrix(fit, linpred.index = 2, type = "lm")

    (Check1 <- head(model.matrix(fit, type = "lm")))
    (Check2 <- model.matrix(fit, data = head(pneumo), type = "lm"))
    all.equal(c(Check1), c(Check2))  # Should be TRUE

    q0 <- head(predict(fit))
    q1 <- head(predict(fit, newdata = pneumo))
    q2 <- predict(fit, newdata = head(pneumo))
    all.equal(q0, q1)  # Should be TRUE
    all.equal(q1, q2)  # Should be TRUE

    # (II) Attributes ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
    fit2 <- vglm(cbind(normal, mild, severe) ~ let,  # x = TRUE
                 multinomial, data = pneumo, trace = TRUE)
    fit2@x  # "lm"-type; saved on the object; note the attributes
    model.matrix(fit2, type = "lm")  # Note the attributes
    model.matrix(fit2, type = "vlm")  # Note the attributes
}

test_138 <- function() {
    pneumo <- transform(pneumo, let = log(exposure.time))
    fit <- vglm(cbind(normal, mild, severe) ~ let,  # For illustration only!
                multinomial, trace = TRUE, data = pneumo)
    fitted(fit)
    predict(fit)

    multilogitlink(fitted(fit))
    multilogitlink(fitted(fit)) - predict(fit)  # Should be all 0s

    multilogitlink(predict(fit), inverse = TRUE)  # rowSums() add to unity
    multilogitlink(predict(fit), inverse = TRUE, refLevel = 1)
    multilogitlink(predict(fit), inverse = TRUE) -
    fitted(fit)  # Should be all 0s

    multilogitlink(fitted(fit), deriv = 1)
    multilogitlink(fitted(fit), deriv = 2)
}

test_139 <- function() {
    # Simulated data with various multiple responses
    size1 <- exp(1); size2 <- exp(2); size3 <- exp(0); size4 <- Inf
    ndata <- data.frame(x2 = runif(nn <- 1000))
    ndata <- transform(ndata, eta1  = -1 - 2 * x2,  # eta1 must be negative
                              size1 = size1)
    ndata <- transform(ndata,
                       mu1  = nbcanlink(eta1, size = size1, inv = TRUE))
    ndata <- transform(ndata,
                  y1 = rnbinom(nn, mu = mu1,         size = size1),  # NB-C
                  y2 = rnbinom(nn, mu = exp(2 - x2), size = size2),
                  y3 = rnbinom(nn, mu = exp(3 + x2), size = size3),  # NB-G
                  y4 =   rpois(nn, lambda = exp(1 + x2)))

    # Also known as NB-C with size known (Hilbe, 2011)
    fit1 <- vglm(y1 ~ x2, negbinomial.size(size = size1, lmu = "nbcanlink"),
                 data = ndata, trace = TRUE)
    coef(fit1, matrix = TRUE)
    head(fit1@misc$size)  # size saved here

    fit2 <- vglm(cbind(y2, y3, y4) ~ x2, data = ndata, trace = TRUE,
                 negbinomial.size(size = c(size2, size3, size4)))
    coef(fit2, matrix = TRUE)
    head(fit2@misc$size)  # size saved here
}

test_140 <- function() {
    fit <- vglm(rpois(9, 2) ~ 1, poissonff, crit = "c")
    niters(fit)
    niters(fit, history = TRUE)
}

test_141 <- function() {
    ndata <- data.frame(x2 = runif(nn <- 2000))
    # Note that coeff1 + coeff2 + coeff5 == 1. So try "multilogitlink".
    myoffset <- 10
    ndata <- transform(ndata,
               coeff1 = 0.25,  # "multilogitlink"
               coeff2 = 0.25,  # "multilogitlink"
               coeff3 = exp(-0.5),  # "loglink"
    # "logofflink" link:
               coeff4 = logofflink(+0.5, offset = myoffset, inverse = TRUE),
               coeff5 = 0.50,  # "multilogitlink"
               coeff6 = 1.00,  # "identitylink"
               v2 = runif(nn),
               v3 = runif(nn),
               v4 = runif(nn),
               v5 = rnorm(nn),
               v6 = rnorm(nn))
    ndata <- transform(ndata,
               Coeff1 =              0.25 - 0 * x2,
               Coeff2 =              0.25 - 0 * x2,
               Coeff3 =   logitlink(-0.5  - 1 * x2, inverse = TRUE),
               Coeff4 =  logloglink( 0.5  - 1 * x2, inverse = TRUE),
               Coeff5 =              0.50 - 0 * x2,
               Coeff6 =              1.00 + 1 * x2)
    ndata <- transform(ndata,
                       y1 = coeff1 * 1 +
                            coeff2 * v2 +
                            coeff3 * v3 +
                            coeff4 * v4 +
                            coeff5 * v5 +
                            coeff6 * v6 + rnorm(nn, sd = exp(0)),
                       y2 = Coeff1 * 1 +
                            Coeff2 * v2 +
                            Coeff3 * v3 +
                            Coeff4 * v4 +
                            Coeff5 * v5 +
                            Coeff6 * v6 + rnorm(nn, sd = exp(0)))

    # An intercept-only model
    fit1 <- vglm(y1 ~ 1,
                 form2 = ~ 1 + v2 + v3 + v4 + v5 + v6,
                 normal.vcm(link.list = list("(Intercept)" = "multilogitlink",
                                             "v2"          = "multilogitlink",
                                             "v3"          = "loglink",
                                             "v4"          = "logofflink",
                                             "(Default)"   = "identitylink",
                                             "v5"          = "multilogitlink"),
                            earg.list = list("(Intercept)" = list(),
                                             "v2"          = list(),
                                             "v4"          = list(offset = myoffset),
                                             "v3"          = list(),
                                             "(Default)"   = list(),
                                             "v5"          = list()),
                            zero = c(1:2, 6)),
                 data = ndata, trace = TRUE)
    coef(fit1, matrix = TRUE)
    summary(fit1)
    # This works only for intercept-only models:
    multilogitlink(rbind(coef(fit1, matrix = TRUE)[1, c(1, 2)]), inverse = TRUE)

    # A model with covariate x2 for the regression coefficients
    fit2 <- vglm(y2 ~ 1 + x2,
                 form2 = ~ 1 + v2 + v3 + v4 + v5 + v6,
                 normal.vcm(link.list = list("(Intercept)" = "multilogitlink",
                                             "v2"          = "multilogitlink",
                                             "v3"          = "logitlink",
                                             "v4"          = "logloglink",
                                             "(Default)"   = "identitylink",
                                             "v5"          = "multilogitlink"),
                            earg.list = list("(Intercept)" = list(),
                                             "v2"          = list(),
                                             "v3"          = list(),
                                             "v4"          = list(),
                                             "(Default)"   = list(),
                                             "v5"          = list()),
                            zero = c(1:2, 6)),
                 data = ndata, trace = TRUE)

    coef(fit2, matrix = TRUE)
    summary(fit2)
}

test_142 <- function() {
    pneumo <- transform(pneumo, let = log(exposure.time))
    (fit1 <- vglm(cbind(normal, mild, severe) ~ let, propodds, data = pneumo))
    coef(fit1)
    coef(fit1, matrix = TRUE)
    nparam(fit1)
    (fit2 <- vglm(hits ~ 1, poissonff, weights = ofreq, data = V1))
    coef(fit2)
    coef(fit2, matrix = TRUE)
    nparam(fit2)
    nparam(fit2, dpar = FALSE)
}

test_143 <- function() {
    alpha <- 2; kay <- exp(3)
    pdata <- data.frame(y = rpareto(n = 1000, scale = alpha, shape = kay))
    fit <- vglm(y ~ 1, paretoff, data = pdata, trace = TRUE)
    fit@extra  # The estimate of alpha is here
    head(fitted(fit))
    with(pdata, mean(y))
    coef(fit, matrix = TRUE)
    summary(fit)  # Standard errors are incorrect!!

    # Here, alpha is assumed known
    fit2 <- vglm(y ~ 1, paretoff(scale = alpha), data = pdata, trace = TRUE)
    fit2@extra  # alpha stored here
    head(fitted(fit2))
    coef(fit2, matrix = TRUE)
    summary(fit2)  # Standard errors are okay

    # Upper truncated Pareto distribution
    lower <- 2; upper <- 8; kay <- exp(2)
    pdata3 <- data.frame(y = rtruncpareto(n = 100, lower = lower,
                                          upper = upper, shape = kay))
    fit3 <- vglm(y ~ 1, truncpareto(lower, upper), data = pdata3, trace = TRUE)
    coef(fit3, matrix = TRUE)
    c(fit3@misc$lower, fit3@misc$upper)
}

test_144 <- function() {
    plotvgam.control(lcol = c("red", "blue"), scol = "darkgreen", se = TRUE)
}

test_145 <- function() {
    # Fit the proportional odds model, p.179, in McCullagh and Nelder (1989)
    pneumo <- transform(pneumo, let = log(exposure.time))
    vglm(cbind(normal, mild, severe) ~ let, propodds, data = pneumo)
}

test_146 <- function() {
    pdata <- data.frame(y = rgamma(10, shape = exp(-1)))  # Not proper data!
    ostat <- 2
    fit <- vglm(y ~ 1, poisson.points(ostat, 2), data = pdata,
                trace = TRUE, crit = "coef")
    fit <- vglm(y ~ 1, poisson.points(ostat, 3), data = pdata,
                trace = TRUE, crit = "coef")  # Slow convergence?
    fit <- vglm(y ~ 1, poisson.points(ostat, 3, idensi = 1), data = pdata,
                trace = TRUE, crit = "coef")
    head(fitted(fit))
    with(pdata, mean(y))
    coef(fit, matrix = TRUE)
    Coef(fit)
}

test_147 <- function() {
    rposbern(n = 10)
    attributes(pdata <- rposbern(n = 100))
    M.bh <- vglm(cbind(y1, y2, y3, y4, y5) ~ x2 + x3,
                 posbernoulli.b(I2 = FALSE), pdata, trace = TRUE)
    constraints(M.bh)
    summary(M.bh)
}

test_148 <- function() {
    # Albinotic children in families with 5 kids (from Patil, 1962) ,,,,
    albinos <- data.frame(y = c(rep(1, 25), rep(2, 23), rep(3, 10), 4, 5),
                          n = rep(5, 60))
    fit1 <- vglm(cbind(y, n-y) ~ 1, posbinomial, albinos, trace = TRUE)
    summary(fit1)
    Coef(fit1)  # = MLE of p = 0.3088
    head(fitted(fit1))
    sqrt(vcov(fit1, untransform = TRUE))  # SE = 0.0322

    # Fit a M_0 model (Otis et al. 1978) to the deermice data ,,,,,,,,,,
    M.0 <- vglm(cbind(    y1 + y2 + y3 + y4 + y5 + y6,
                      6 - y1 - y2 - y3 - y4 - y5 - y6) ~ 1, trace = TRUE,
                posbinomial(omit.constant = TRUE), data = deermice)
    coef(M.0, matrix = TRUE)
    Coef(M.0)
    constraints(M.0, matrix = TRUE)
    summary(M.0)
    c(   N.hat = M.0@extra$N.hat,     # As tau = 6, i.e., 6 Bernoulli trials
      SE.N.hat = M.0@extra$SE.N.hat)  # per obsn is the same for each obsn

    # Compare it to the M_b using AIC and BIC
    M.b <- vglm(cbind(y1, y2, y3, y4, y5, y6) ~ 1, trace = TRUE,
                posbernoulli.b, data = deermice)
    sort(c(M.0 = AIC(M.0), M.b = AIC(M.b)))  # Ok since omit.constant=TRUE
    sort(c(M.0 = BIC(M.0), M.b = BIC(M.b)))  # Ok since omit.constant=TRUE
}

test_149 <- function() {
    # Data from Coleman and James (1961)
    cjdata <- data.frame(y = 1:6, freq = c(1486, 694, 195, 37, 10, 1))
    fit <- vglm(y ~ 1, pospoisson, data = cjdata, weights = freq)
    Coef(fit)
    summary(fit)
    fitted(fit)

    pdata <- data.frame(x2 = runif(nn <- 1000))  # Artificial data
    pdata <- transform(pdata, lambda = exp(1 - 2 * x2))
    pdata <- transform(pdata, y1 = rgaitdpois(nn, lambda, truncate = 0))
    with(pdata, table(y1))
    fit <- vglm(y1 ~ x2, pospoisson, data = pdata, trace = TRUE, crit = "coef")
    coef(fit, matrix = TRUE)
}

test_150 <- function() {
    powerlink("a", power = 2, short = FALSE, tag = TRUE)
    powerlink(x <- 1:5)
    powerlink(x, power = 2)
    max(abs(powerlink(powerlink(x, power = 2),
                      power = 2, inverse = TRUE) - x))  # Should be 0
    powerlink(x <- (-5):5, power = 0.5)  # Has NAs

    # 1/2 = 0.5
    pdata <- data.frame(y = rbeta(n = 1000, shape1 = 2^2, shape2 = 3^2))
    fit <- vglm(y ~ 1, betaR(lshape1 = "powerlink(power = 0.5)", i1 = 3,
                             lshape2 = "powerlink(power = 0.5)", i2 = 7),
                data = pdata)
    t(coef(fit, matrix = TRUE))
    Coef(fit)  # Useful for intercept-only models
    vcov(fit, untransform = TRUE)
}

test_151 <- function() {
    prats
    colSums(subset(prats, treatment == 0))
    colSums(subset(prats, treatment == 1))
    summary(prats)
}

test_152 <- function() {
    # Illustrates smart prediction
    pneumo <- transform(pneumo, let = log(exposure.time))
    fit <- vglm(cbind(normal, mild, severe) ~ poly(c(scale(let)), 2),
                propodds, pneumo, trace = TRUE, x.arg = FALSE)
    class(fit)

    (q0 <- head(predict(fit)))
    (q1 <- predict(fit, newdata = head(pneumo)))
    (q2 <- predict(fit, newdata = head(pneumo)))
    all.equal(q0, q1)  # Should be TRUE
    all.equal(q1, q2)  # Should be TRUE

    head(predict(fit))
    head(predict(fit, untransform = TRUE))

    p0 <- head(predict(fit, type = "response"))
    p1 <- head(predict(fit, type = "response", newdata = pneumo))
    p2 <- head(predict(fit, type = "response", newdata = pneumo))
    p3 <- head(fitted(fit))
    all.equal(p0, p1)  # Should be TRUE
    all.equal(p1, p2)  # Should be TRUE
    all.equal(p2, p3)  # Should be TRUE

    predict(fit, type = "terms", se = TRUE)
}

test_153 <- function() {
    pdata <- data.frame(x2 = runif(nn <- 1000))
    pdata <- transform(pdata, loc = -1 + 2*x2, Scale = exp(1))
    pdata <- transform(pdata, y = rlgamma(nn, loc = loc, scale = Scale, shape = 1))
    fit <- vglm(y ~ x2, prentice74(zero = 2:3), data = pdata, trace = TRUE)
    coef(fit, matrix = TRUE)  # Note the coefficients for location
}

test_154 <- function() {
    head(prinia)
    summary(prinia)
    rowSums(prinia[, c("cap", "noncap")])  # 19s

    #  Fit a positive-binomial distribution (M.h) to the data:
    fit1 <- vglm(cbind(cap, noncap) ~ length + fat, posbinomial, prinia)

    #  Fit another positive-binomial distribution (M.h) to the data:
    #  The response input is suitable for posbernoulli.*-type functions.
    fit2 <- vglm(cbind(y01, y02, y03, y04, y05, y06, y07, y08, y09, y10,
                       y11, y12, y13, y14, y15, y16, y17, y18, y19) ~
                 length + fat, posbernoulli.b(drop.b = FALSE ~ 0), prinia)
}

test_155 <- function() {
    pneumo <- transform(pneumo, let = log(exposure.time))
    fit1 <- vglm(cbind(normal, mild, severe) ~ let, propodds,
                 trace = TRUE, data = pneumo)
    pfit1 <- profile(fit1, trace = FALSE)
    confint(fit1, method = "profile", trace = FALSE)
}

test_156 <- function() {
    print(sm.min1)
}

test_157 <- function() {
    ddata <- data.frame(rdiric(n = 1000, shape = c(y1 = 3, y2 = 1, y3 = 4)))
    fit <- vglm(cbind(y1, y2, y3) ~ 1, dirichlet, data = ddata, trace = TRUE)
    Coef(fit)
    coef(fit, matrix = TRUE)
}

test_158 <- function() {
    rawy <- rexp(n <- 10000, rate = exp(1))
    y <- unique(cummax(rawy))  # Keep only the records

    length(y) / y[length(y)]   # MLE of rate

    fit <- vglm(y ~ 1, rec.exp1, trace = TRUE)
    coef(fit, matrix = TRUE)
    Coef(fit)
}

test_159 <- function() {
    nn <- 10000; mymean <- 100
    # First value is reference value or trivial record
    Rdata <- data.frame(rawy = c(mymean, rnorm(nn, mymean, exp(3))))
    # Keep only observations that are records:
    rdata <- data.frame(y = unique(cummax(with(Rdata, rawy))))

    fit <- vglm(y ~ 1, rec.normal, rdata, trace = TRUE, maxit = 200)
    coef(fit, matrix = TRUE)
    Coef(fit)
    summary(fit)
}

test_160 <- function() {
       reciprocallink(1:5)
       reciprocallink(1:5, inverse = TRUE, deriv = 2)
    negreciprocallink(1:5)
    negreciprocallink(1:5, inverse = TRUE, deriv = 2)

    x <- (-3):3
    reciprocallink(x)  # Has Inf
    reciprocallink(x, bvalue = .Machine$double.eps)  # Has no Inf
}

test_161 <- function() {
    pneumo <- transform(pneumo, let = log(exposure.time))
    fit <- vglm(cbind(normal, mild, severe) ~ let, propodds, pneumo)
    resid(fit)  # Same as having type = "working" (the default)
    resid(fit, type = "response")
    resid(fit, type = "pearson")
    resid(fit, type = "stdres")  # Test for independence
}

test_162 <- function() {
    rdata <- data.frame(y = rchisq(100, df = 14))  # Not 'proper' data!!
    fit <- vglm(y ~ 1, rigff, rdata, trace = TRUE)
    fit <- vglm(y ~ 1, rigff, rdata, trace = TRUE, crit = "c")
    summary(fit)
}

test_163 <- function() {
    set.seed(1); x <- sort(rcauchy(10))
    x3 <- round2(x, 3)
    x3 == round2(x, 3)  # Supposed to be reliable (all TRUE)
    rbind(x, x3)  # Comparison
    (x3[1]  * 2^(0:9)) / 2^(0:9)
    print((x3[1]  * 2^(0:11)), digits = 14)

    # Round to approx 1 d.p.
    x1 <- round2(x, 1)
    x1 == round2(x, 1)  # Supposed to be reliable (all TRUE)
    rbind(x, x1)
    x1[8] == 0.75  # 3/4
    print((x1[1]  * 2^(0:11)), digits = 9)
    seq(31) / 32
}

test_164 <- function() {
    lambdahat <- with(ruge, weighted.mean(number, w = counts))
    (N <- with(ruge, sum(counts)))
    with(ruge, cbind(number, counts,
                     fitted = round(N * dpois(number, lambdahat))))
}

test_165 <- function() {
    set.seed(1)
    pneumo <- transform(pneumo, let = log(exposure.time),
                                x3 = rnorm(nrow(pneumo)))
    (pfit <- vglm(cbind(normal, mild, severe) ~ let + x3, propodds, pneumo))
    score.stat(pfit)  # No HDE here; should be similar to the next line:
    coef(summary(pfit))[, "z value"]  # Wald statistics computed at the MLE
    summary(pfit, score0 = TRUE)
}

test_166 <- function() {
    sdata <- data.frame(mvector = round(rnorm(nn <- 100, m = 10, sd = 2)),
                        x2 = runif(nn))
    sdata <- transform(sdata, prob1 = logitlink(+2 - x2, inverse = TRUE),
                              prob2 = logitlink(-2 + x2, inverse = TRUE))
    sdata <- transform(sdata, successes1 = rbinom(nn, size = mvector,    prob = prob1))
    sdata <- transform(sdata, successes2 = rbinom(nn, size = successes1, prob = prob2))
    sdata <- transform(sdata, y1 = successes1 / mvector)
    sdata <- transform(sdata, y2 = successes2 / successes1)
    fit <- vglm(cbind(y1, y2) ~ x2, seq2binomial, weight = mvector,
                data = sdata, trace = TRUE)
    coef(fit)
    coef(fit, matrix = TRUE)
    head(fitted(fit))
    head(depvar(fit))
    head(weights(fit, type = "prior"))  # Same as with(sdata, mvector)
    # Number of first successes:
    head(depvar(fit)[, 1] * c(weights(fit, type = "prior")))
    # Number of second successes:
    head(depvar(fit)[, 2] * c(weights(fit, type = "prior")) *
                              depvar(fit)[, 1])
}

test_167 <- function() {
    sdata <- data.frame(x2 = runif(nn <- 1000))
    sdata <- transform(sdata, eta1 = 1 + 2 * x2,
                              eta2 = 1 - 2 * x2)
    sdata <- transform(sdata, y = rsimplex(nn, mu = logitlink(eta1, inverse = TRUE),
                                           dispersion = exp(eta2)))
    (fit <- vglm(y ~ x2, simplex(zero = NULL), data = sdata, trace = TRUE))
    coef(fit, matrix = TRUE)
    summary(fit)
}

test_168 <- function() {
    nn <- 10; mysize <- 20; set.seed(123)
    bdata <- data.frame(x2 = rnorm(nn))
    bdata <- transform(bdata,
      y1   = rbinom(nn, size = mysize, p = logitlink(1+x2, inverse = TRUE)),
      y2   = rbinom(nn, size = mysize, p = logitlink(1+x2, inverse = TRUE)),
      f1   = factor(as.numeric(rbinom(nn, size = 1,
                                      p = logitlink(1+x2, inverse = TRUE)))))
    (fit1 <- vglm(cbind(y1, aaa = mysize - y1) ~ x2,  # Matrix response (2-colns)
                  binomialff, data = bdata))
    (fit2 <- vglm(f1 ~ x2, binomialff, model = TRUE, data = bdata)) # Factor response

    set.seed(123); simulate(fit1, nsim = 8)
    set.seed(123); c(simulate(fit2, nsim = 3))  # Use c() when model = TRUE

    # An n x N x F example
    set.seed(123); n <- 100
    bdata <- data.frame(x2 = runif(n), x3 = runif(n))
    bdata <- transform(bdata, y1 = rnorm(n, 1 + 2 * x2),
                              y2 = rnorm(n, 3 + 4 * x2))
    fit1 <- vglm(cbind(y1, y2) ~ x2, binormal(eq.sd = TRUE), data = bdata)
    nsim <- 1000  # Number of simulations for each observation
    my.sims <- simulate(fit1, nsim = nsim)
    dim(my.sims)  # A data frame
    aaa <- array(unlist(my.sims), c(n, nsim, ncol(fitted(fit1))))  # n by N by F
    summary(rowMeans(aaa[, , 1]) - fitted(fit1)[, 1])  # Should be all 0s
    summary(rowMeans(aaa[, , 2]) - fitted(fit1)[, 2])  # Should be all 0s

    # An n x F x N example
    n <- 100; set.seed(111); nsim <- 1000
    zdata <- data.frame(x2 = runif(n))
    zdata <- transform(zdata, lambda1 =  loglink(-0.5 + 2 * x2, inverse = TRUE),
                              lambda2 =  loglink( 0.5 + 2 * x2, inverse = TRUE),
                              pstr01  = logitlink( 0,            inverse = TRUE),
                              pstr02  = logitlink(-1.0,          inverse = TRUE))
    zdata <- transform(zdata, y1 = rzipois(n, lambda = lambda1, pstr0 = pstr01),
                              y2 = rzipois(n, lambda = lambda2, pstr0 = pstr02))
    zip.fit  <- vglm(cbind(y1, y2) ~ x2, zipoissonff, data = zdata, crit = "coef")
    my.sims <- simulate(zip.fit, nsim = nsim)
    dim(my.sims)  # A data frame
    aaa <- array(unlist(my.sims), c(n, ncol(fitted(zip.fit)), nsim))  # n by F by N
    summary(rowMeans(aaa[, 1, ]) - fitted(zip.fit)[, 1])  # Should be all 0s
    summary(rowMeans(aaa[, 2, ]) - fitted(zip.fit)[, 2])  # Should be all 0s
}

test_169 <- function() {
    mu  <- seq(0.01, 3, length = 10)
    sloglink(mu)
    max(abs(sloglink(sloglink(mu), inv = TRUE) - mu))  # 0?
}

test_170 <- function() {
    print(sm.min2)
}

test_171 <- function() {
    print(sm.min1)
    smart.mode.is()  # Returns "neutral"
    smart.mode.is(smart.mode.is())  # Returns TRUE
}

test_172 <- function() {
    abdata <- data.frame(y = 0:7, w = c(182, 41, 12, 2, 2, 0, 0, 1))
    fit1 <- vglm(y ~ 1, gaitdpoisson(a.mix = 0), data = abdata,
                 weight = w, subset = w > 0)
    specials(fit1)
}

test_173 <- function() {
    pneumo <- transform(pneumo, let = log(exposure.time))
    (fit <- vglm(cbind(normal, mild, severe) ~ let,
                 sratio(parallel = TRUE), data = pneumo))
    coef(fit, matrix = TRUE)
    constraints(fit)
    predict(fit)
    predict(fit, untransform = TRUE)
}

test_174 <- function() {
    data("backPain2", package = "VGAM")
    summary(backPain2)
    fit1 <- vglm(pain ~ x2 + x3 + x4 + x2:x3 + x2:x4 + x3:x4,
                 propodds, data = backPain2)
    spom1 <- step4(fit1)
    summary(spom1)
    spom1@post$anova
}

test_175 <- function() {
    tdata <- data.frame(x2 = runif(nn <- 1000))
    tdata <- transform(tdata, y1 = rt(nn, df = exp(exp(0.5 - x2))),
                              y2 = rt(nn, df = exp(exp(0.5 - x2))))
    fit1 <- vglm(y1 ~ x2, studentt, data = tdata, trace = TRUE)
    coef(fit1, matrix = TRUE)

    # df inputted into studentt2() not quite right:
    fit2 <- vglm(y1 ~ x2, studentt2(df = exp(exp(0.5))), tdata)
    coef(fit2, matrix = TRUE)

    fit3 <- vglm(cbind(y1, y2) ~ x2, studentt3, tdata, trace = TRUE)
    coef(fit3, matrix = TRUE)
}

test_176 <- function() {
    hfit <- vgam(agaaus ~ s(altitude, df = 2), binomialff, data = hunua)
    summary(hfit)
    summary(hfit)@anova  # Table for (approximate) testing of linearity
}

test_177 <- function() {
    ## For examples see example(glm)
    pneumo <- transform(pneumo, let = log(exposure.time))
    (afit <- vglm(cbind(normal, mild, severe) ~ let, acat, pneumo))
    coef(afit, matrix = TRUE)
    summary(afit)  # Might suffer from the HDE?
    coef(summary(afit))
    summary(afit, lrt0 = TRUE, score0 = TRUE, wald0 = TRUE)
    summary(afit, HDEtest = TRUE)
}

test_178 <- function() {
    tdata <- data.frame(y = rtopple(1000, logitlink(1, inverse = TRUE)))
    tfit <- vglm(y ~ 1, topple, tdata, trace = TRUE, crit = "coef")
    coef(tfit, matrix = TRUE)
    Coef(tfit)
}

test_179 <- function() {
    summary(ucberk)
}

test_180 <- function() {
    udata <- data.frame(x2 = rnorm(nn <- 200))
    udata <- transform(udata,
               y1  = rnorm(nn, m = 1 - 3*x2, sd = exp(1 + 0.2*x2)),
               y2a = rnorm(nn, m = 1 + 2*x2, sd = exp(1 + 2.0*x2)^0.5),
               y2b = rnorm(nn, m = 1 + 2*x2, sd = exp(1 + 2.0*x2)^0.5))
    fit1 <- vglm(y1 ~ x2, uninormal(zero = NULL), udata, trace = TRUE)
    coef(fit1, matrix = TRUE)
    fit2 <- vglm(cbind(y2a, y2b) ~ x2, data = udata, trace = TRUE,
                 uninormal(var = TRUE, parallel = TRUE ~ x2,
                           zero = NULL))
    coef(fit2, matrix = TRUE)

    # Generate data from N(mu=theta=10, sigma=theta) and estimate theta.
    theta <- 10
    udata <- data.frame(y3 = rnorm(100, m = theta, sd = theta))
    fit3a <- vglm(y3 ~ 1, uninormal(lsd = "identitylink"), data = udata,
                 constraints = list("(Intercept)" = rbind(1, 1)))
    fit3b <- vglm(y3 ~ 1, uninormal(lsd = "identitylink",
                            parallel = TRUE ~ 1, zero = NULL), udata)
    coef(fit3a, matrix = TRUE)
    coef(fit3b, matrix = TRUE)  # Same as fit3a
}

test_181 <- function() {
    # Fit a nonparametric proportional odds model
    pneumo <- transform(pneumo, let = log(exposure.time))
    vgam(cbind(normal, mild, severe) ~ s(let),
         cumulative(parallel = TRUE), data = pneumo)
}

test_182 <- function() {
    pneumo <- transform(pneumo, let = log(exposure.time))
    vgam(cbind(normal, mild, severe) ~ s(let, df = 2), multinomial,
         data = pneumo, trace = TRUE, eps = 1e-4, maxit = 10)
}

test_183 <- function() {
    # Example 1. See help(glm)
    (d.AD <- data.frame(treatment = gl(3, 3),
                        outcome = gl(3, 1, 9),
                        counts = c(18,17,15,20,10,20,25,13,12)))
    vglm.D93 <- vglm(counts ~ outcome + treatment, poissonff,
                     data = d.AD, trace = TRUE)
    summary(vglm.D93)


    # Example 2. Multinomial logit model
    pneumo <- transform(pneumo, let = log(exposure.time))
    vglm(cbind(normal, mild, severe) ~ let, multinomial, pneumo)


    # Example 3. Proportional odds model
    fit3 <- vglm(cbind(normal, mild, severe) ~ let, propodds, pneumo)
    coef(fit3, matrix = TRUE)
    constraints(fit3)
    model.matrix(fit3, type = "lm")  # LM model matrix
    model.matrix(fit3)               # Larger VGLM (or VLM) matrix


    # Example 4. Bivariate logistic model
    fit4 <- vglm(cbind(nBnW, nBW, BnW, BW) ~ age, binom2.or, coalminers)
    coef(fit4, matrix = TRUE)
    depvar(fit4)  # Response are proportions
    weights(fit4, type = "prior")


    # Example 5. The use of the xij argument (simple case).
    # The constraint matrix for 'op' has one column.
    nn <- 1000
    eyesdat <- round(data.frame(lop = runif(nn),
                                rop = runif(nn),
                                 op = runif(nn)), digits = 2)
    eyesdat <- transform(eyesdat, eta1 = -1 + 2 * lop,
                                  eta2 = -1 + 2 * lop)
    eyesdat <- transform(eyesdat,
               leye = rbinom(nn, 1, prob = logitlink(eta1, inv = TRUE)),
               reye = rbinom(nn, 1, prob = logitlink(eta2, inv = TRUE)))
    head(eyesdat)
    fit5 <- vglm(cbind(leye, reye) ~ op,
                 binom2.or(exchangeable = TRUE, zero = 3),
                 data = eyesdat, trace = TRUE,
                 xij = list(op ~ lop + rop + fill1(lop)),
                 form2 = ~  op + lop + rop + fill1(lop))
    coef(fit5)
    coef(fit5, matrix = TRUE)
    constraints(fit5)
    fit5@control$xij
    head(model.matrix(fit5))


    # Example 6. The use of the 'constraints' argument.
    as.character(~ bs(year,df=3))  # Get the white spaces right
    clist <- list("(Intercept)"      = diag(3),
                  "bs(year, df = 3)" = rbind(1, 0, 0))
    fit1 <- vglm(r1 ~ bs(year,df=3), gev(zero = NULL),
                 data = venice, constraints = clist, trace = TRUE)
    coef(fit1, matrix = TRUE)  # Check
}

test_184 <- function() {
    # Multinomial logit model
    pneumo <- transform(pneumo, let = log(exposure.time))
    vglm(cbind(normal, mild, severe) ~ let, multinomial, data = pneumo)
}

test_185 <- function() {
    cratio()
    cratio(link = "clogloglink")
    cratio(link = "clogloglink", reverse = TRUE)
}

test_186 <- function() {
    vdata <- data.frame(x2 = runif(nn <- 1000))
    vdata <- transform(vdata,
                       y = rnorm(nn, 2+x2, exp(0.2)))  # Bad data!!
    fit <- vglm(y  ~ x2, vonmises(zero = 2), vdata, trace = TRUE)
    coef(fit, matrix = TRUE)
    Coef(fit)
    with(vdata, range(y))  # Original data
    range(depvar(fit))     # Processed data is in [0,2*pi)
}

test_187 <- function() {
    set.seed(1)
    pneumo <- transform(pneumo, let = log(exposure.time),
                                x3 = rnorm(nrow(pneumo)))
    (fit <- vglm(cbind(normal, mild, severe) ~ let + x3, propodds, pneumo))
    wald.stat(fit)  # No HDE here
    summary(fit, wald0 = TRUE)  # See them here
    coef(summary(fit))  # Usual Wald statistics evaluated at the MLE
    wald.stat(fit, orig.SE = TRUE)  # Same as previous line
}

test_188 <- function() {
    wdata <- data.frame(y = rinv.gaussian(1000, mu =  1, exp(1)))
    wfit <- vglm(y ~ 1, waldff(ilambda = 0.2), wdata, trace = TRUE)
    coef(wfit, matrix = TRUE)
    Coef(wfit)
    summary(wfit)
}

test_189 <- function() {
    wdata <- data.frame(x2 = runif(nn <- 1000))  # Complete data
    wdata <- transform(wdata,
                y1 = rweibull(nn, exp(1), scale = exp(-2 + x2)),
                y2 = rweibull(nn, exp(2), scale = exp( 1 - x2)))
    fit <- vglm(cbind(y1, y2) ~ x2, weibullR, wdata, trace = TRUE)
    coef(fit, matrix = TRUE)
    vcov(fit)
    summary(fit)
}

test_190 <- function() {
    pneumo <- transform(pneumo, let = log(exposure.time))
    (fit <- vglm(cbind(normal, mild, severe) ~ let,
                 cumulative(parallel = TRUE, reverse = TRUE), pneumo))
    depvar(fit)  # These are sample proportions
    weights(fit, type = "prior", matrix = FALSE)  # No. of observations

    # Look at the working residuals
    nn <- nrow(model.matrix(fit, type = "lm"))
    M <- ncol(predict(fit))

    wwt <- weights(fit, type="working", deriv=TRUE)  # Matrix-band format
    wz <- m2a(wwt$weights, M = M)  # In array format
    wzinv <- array(apply(wz, 3, solve), c(M, M, nn))
    wresid <- matrix(NA, nn, M)  # Working residuals
    for (ii in 1:nn)
      wresid[ii, ] <- wzinv[, , ii, drop = TRUE] %*% wwt$deriv[ii, ]
    max(abs(c(resid(fit, type = "work")) - c(wresid)))  # Should be 0

    (zedd <- predict(fit) + wresid)  # Adjusted dependent vector
}

test_191 <- function() {
    wine
    summary(wine)
}

test_192 <- function() {
    zdata <- data.frame(x2 = runif(nn <- 1000))
    zdata <- transform(zdata, size  = 10,
                              prob  = logitlink(-2 + 3*x2, inverse = TRUE),
                              pobs0 = logitlink(-1 + 2*x2, inverse = TRUE))
    zdata <- transform(zdata,
                       y1 = rzabinom(nn, size = size, prob = prob, pobs0 = pobs0))
    with(zdata, table(y1))

    zfit <- vglm(cbind(y1, size - y1) ~ x2, zabinomial(zero = NULL),
                 data = zdata, trace = TRUE)
    coef(zfit, matrix = TRUE)
    head(fitted(zfit))
    head(predict(zfit))
    summary(zfit)
}

test_193 <- function() {
    zdata <- data.frame(x2 = runif(nn <- 1000))
    zdata <- transform(zdata, pobs0 = logitlink(-1 + 2*x2, inverse = TRUE),
                              prob  = logitlink(-2 + 3*x2, inverse = TRUE))
    zdata <- transform(zdata, y1 = rzageom(nn, prob = prob, pobs0 = pobs0),
                              y2 = rzageom(nn, prob = prob, pobs0 = pobs0))
    with(zdata, table(y1))

    fit <- vglm(cbind(y1, y2) ~ x2, zageometric, data = zdata, trace = TRUE)
    coef(fit, matrix = TRUE)
    head(fitted(fit))
    head(predict(fit))
    summary(fit)
}

test_194 <- function() {
    zdata <- data.frame(x2 = runif(nn <- 1000))
    zdata <- transform(zdata, pobs0  = logitlink( -1 + 1*x2, inverse = TRUE),
                              lambda = loglink(-0.5 + 2*x2, inverse = TRUE))
    zdata <- transform(zdata, y = rgaitdpois(nn, lambda, pobs.mlm = pobs0,
                                            a.mlm = 0))

    with(zdata, table(y))
    fit <- vglm(y ~ x2, zapoisson, data = zdata, trace = TRUE)
    fit <- vglm(y ~ x2, zapoisson, data = zdata, trace = TRUE, crit = "coef")
    head(fitted(fit))
    head(predict(fit))
    head(predict(fit, untransform = TRUE))
    coef(fit, matrix = TRUE)
    summary(fit)

    # Another example ------------------------------
    # Data from Angers and Biswas (2003)
    abdata <- data.frame(y = 0:7, w = c(182, 41, 12, 2, 2, 0, 0, 1))
    abdata <- subset(abdata, w > 0)
    Abdata <- data.frame(yy = with(abdata, rep(y, w)))
    fit3 <- vglm(yy ~ 1, zapoisson, data = Abdata, trace = TRUE, crit = "coef")
    coef(fit3, matrix = TRUE)
    Coef(fit3)  # Estimate lambda (they get 0.6997 with SE 0.1520)
    head(fitted(fit3), 1)
    with(Abdata, mean(yy))  # Compare this with fitted(fit3)
}

test_195 <- function() {
    args(multinomial)
    args(binom2.or)
    args(gpd)

    #LMS quantile regression example
    fit <- vglm(BMI ~ sm.bs(age, df = 4), lms.bcg(zero = c(1, 3)),
                data = bmi.nz, trace = TRUE)
    coef(fit, matrix = TRUE)
}

test_196 <- function() {
    zdata <- data.frame(y = 1:5, w =  c(63, 14, 5, 1, 2))  # Knight, p.304
    fit <- vglm(y ~ 1, zetaff, data = zdata, trace = TRUE, weight = w, crit = "c")
    (phat <- Coef(fit))  # 1.682557
    with(zdata, cbind(round(dzeta(y, phat) * sum(w), 1), w))

    with(zdata, weighted.mean(y, w))
    fitted(fit, matrix = FALSE)
    predict(fit)

    # The following should be zero at the MLE:
    with(zdata, mean(log(rep(y, w))) + zeta(1+phat, deriv = 1) / zeta(1+phat))
}

test_197 <- function() {
    size <- 10  # Number of trials; N in the notation above
    nn <- 200
    zdata <- data.frame(pstr0 = logitlink( 0, inverse = TRUE),  # 0.50
                        mubin = logitlink(-1, inverse = TRUE),  # Mean of usual binomial
                        sv    = rep(size, length = nn))
    zdata <- transform(zdata,
                       y = rzibinom(nn, size = sv, prob = mubin, pstr0 = pstr0))
    with(zdata, table(y))
    fit <- vglm(cbind(y, sv - y) ~ 1, zibinomialff, data = zdata, trace = TRUE)
    fit <- vglm(cbind(y, sv - y) ~ 1, zibinomialff, data = zdata, trace = TRUE,
                stepsize = 0.5)

    coef(fit, matrix = TRUE)
    Coef(fit)  # Useful for intercept-only models
    head(fitted(fit, type = "pobs0"))  # Estimate of P(Y = 0)
    head(fitted(fit))
    with(zdata, mean(y))  # Compare this with fitted(fit)
    summary(fit)
}

test_198 <- function() {
    gdata <- data.frame(x2 = runif(nn <- 1000) - 0.5)
    gdata <- transform(gdata, x3 = runif(nn) - 0.5,
                              x4 = runif(nn) - 0.5)
    gdata <- transform(gdata, eta1 =  1.0 - 1.0 * x2 + 2.0 * x3,
                              eta2 = -1.0,
                              eta3 =  0.5)
    gdata <- transform(gdata, prob1 = logitlink(eta1, inverse = TRUE),
                              prob2 = logitlink(eta2, inverse = TRUE),
                              prob3 = logitlink(eta3, inverse = TRUE))
    gdata <- transform(gdata, y1 = rzigeom(nn, prob1, pstr0 = prob3),
                              y2 = rzigeom(nn, prob2, pstr0 = prob3),
                              y3 = rzigeom(nn, prob2, pstr0 = prob3))
    with(gdata, table(y1))
    with(gdata, table(y2))
    with(gdata, table(y3))
    head(gdata)

    fit1 <- vglm(y1 ~ x2 + x3 + x4, zigeometric(zero = 1), data = gdata, trace = TRUE)
    coef(fit1, matrix = TRUE)
    head(fitted(fit1, type = "pstr0"))

    fit2 <- vglm(cbind(y2, y3) ~ 1, zigeometric(zero = 1), data = gdata, trace = TRUE)
    coef(fit2, matrix = TRUE)
    summary(fit2)
}

test_199 <- function() {
    zdata <- data.frame(y = 1:5, ofreq = c(63, 14, 5, 1, 2))
    zfit <- vglm(y ~ 1, zipf, data = zdata, trace = TRUE, weight = ofreq)
    zfit <- vglm(y ~ 1, zipf(lshape = "identitylink", ishape = 3.4), data = zdata,
                trace = TRUE, weight = ofreq, crit = "coef")
    zfit@misc$N
    (shape.hat <- Coef(zfit))
    with(zdata, weighted.mean(y, ofreq))
    fitted(zfit, matrix = FALSE)
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

print("Running test_88")
test_88()

print("Running test_89")
test_89()

print("Running test_90")
test_90()

print("Running test_91")
test_91()

print("Running test_92")
test_92()

print("Running test_93")
test_93()

print("Running test_94")
test_94()

print("Running test_95")
test_95()

print("Running test_96")
test_96()

print("Running test_97")
test_97()

print("Running test_98")
test_98()

print("Running test_99")
test_99()

print("Running test_100")
test_100()

print("Running test_101")
test_101()

print("Running test_102")
test_102()

print("Running test_103")
test_103()

print("Running test_104")
test_104()

print("Running test_105")
test_105()

print("Running test_106")
test_106()

print("Running test_107")
test_107()

print("Running test_108")
test_108()

print("Running test_109")
test_109()

print("Running test_110")
test_110()

print("Running test_111")
test_111()

print("Running test_112")
test_112()

print("Running test_113")
test_113()

print("Running test_114")
test_114()

print("Running test_115")
test_115()

print("Running test_116")
test_116()

print("Running test_117")
test_117()

print("Running test_118")
test_118()

print("Running test_119")
test_119()

print("Running test_120")
test_120()

print("Running test_121")
test_121()

print("Running test_122")
test_122()

print("Running test_123")
test_123()

print("Running test_124")
test_124()

print("Running test_125")
test_125()

print("Running test_126")
test_126()

print("Running test_127")
test_127()

print("Running test_128")
test_128()

print("Running test_129")
test_129()

print("Running test_130")
test_130()

print("Running test_131")
test_131()

print("Running test_132")
test_132()

print("Running test_133")
test_133()

print("Running test_134")
test_134()

print("Running test_135")
test_135()

print("Running test_136")
test_136()

print("Running test_137")
test_137()

print("Running test_138")
test_138()

print("Running test_139")
test_139()

print("Running test_140")
test_140()

print("Running test_141")
test_141()

print("Running test_142")
test_142()

print("Running test_143")
test_143()

print("Running test_144")
test_144()

print("Running test_145")
test_145()

print("Running test_146")
test_146()

print("Running test_147")
test_147()

print("Running test_148")
test_148()

print("Running test_149")
test_149()

print("Running test_150")
test_150()

print("Running test_151")
test_151()

print("Running test_152")
test_152()

print("Running test_153")
test_153()

print("Running test_154")
test_154()

print("Running test_155")
test_155()

print("Running test_156")
test_156()

print("Running test_157")
test_157()

print("Running test_158")
test_158()

print("Running test_159")
test_159()

print("Running test_160")
test_160()

print("Running test_161")
test_161()

print("Running test_162")
test_162()

print("Running test_163")
test_163()

print("Running test_164")
test_164()

print("Running test_165")
test_165()

print("Running test_166")
test_166()

print("Running test_167")
test_167()

print("Running test_168")
test_168()

print("Running test_169")
test_169()

print("Running test_170")
test_170()

print("Running test_171")
test_171()

print("Running test_172")
test_172()

print("Running test_173")
test_173()

print("Running test_174")
test_174()

print("Running test_175")
test_175()

print("Running test_176")
test_176()

print("Running test_177")
test_177()

print("Running test_178")
test_178()

print("Running test_179")
test_179()

print("Running test_180")
test_180()

print("Running test_181")
test_181()

print("Running test_182")
test_182()

print("Running test_183")
test_183()

print("Running test_184")
test_184()

print("Running test_185")
test_185()

print("Running test_186")
test_186()

print("Running test_187")
test_187()

print("Running test_188")
test_188()

print("Running test_189")
test_189()

print("Running test_190")
test_190()

print("Running test_191")
test_191()

print("Running test_192")
test_192()

print("Running test_193")
test_193()

print("Running test_194")
test_194()

print("Running test_195")
test_195()

print("Running test_196")
test_196()

print("Running test_197")
test_197()

print("Running test_198")
test_198()

print("Running test_199")
test_199()

