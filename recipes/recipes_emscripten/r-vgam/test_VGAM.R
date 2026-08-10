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