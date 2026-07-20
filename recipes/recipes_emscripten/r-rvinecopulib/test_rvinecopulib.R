print('Loading rvinecopulib package')
library(rvinecopulib)
print('... rvinecopulib package loaded successfully')

test_1 <- function() {
    ## bicop_dist objects
    bicop_dist("gaussian", 0, 0.5)
    str(bicop_dist("gauss", 0, 0.5))
    bicop <- bicop_dist("clayton", 90, 3)

    ## bicop objects
    u <- rbicop(500, "gauss", 0, 0.5)
    fit1 <- bicop(u, family = "par")
    fit1

    ## vinecop_dist objects
    ## specify pair-copulas
    bicop <- bicop_dist("bb1", 90, c(3, 2))
    pcs <- list(
      list(bicop, bicop), # pair-copulas in first tree
      list(bicop) # pair-copulas in second tree
    )
    ## specify R-vine matrix
    mat <- matrix(c(1, 2, 3, 1, 2, 0, 1, 0, 0), 3, 3)
    ## build the vinecop_dist object
    vc <- vinecop_dist(pcs, mat)
    summary(vc)

    ## vinecop objects
    u <- sapply(1:3, function(i) runif(50))
    vc <- vinecop(u, family = "par")
    summary(vc)

    ## vine_dist objects
    vc <- vine_dist(list(list(distr = "norm")), pcs, mat)
    summary(vc)

    ## vine objects
    x <- sapply(1:3, function(i) rnorm(50))
    vc <- vine(x, copula_controls = list(family_set = "par"))
    summary(vc)
}

test_2 <- function() {
    as.bicop(list(family = "gumbel", rotation = 90, parameters = 2, npars = 1))
}

test_3 <- function() {
    # R-vine structures can be constructed from the order vector and struct_array
    rvine_structure(order = 1:4, struct_array = list(
      c(4, 4, 4),
      c(3, 3),
      2
    ))

    # ... or a similar list can be coerced into an R-vine structure
    as_rvine_structure(list(order = 1:4, struct_array = list(
      c(4, 4, 4),
      c(3, 3),
      2
    )))

    # similarly, standard matrices can be coerced into R-vine structures
    mat <- matrix(c(4, 3, 2, 1, 4, 3, 2, 0, 4, 3, 0, 0, 4, 0, 0, 0), 4, 4)
    as_rvine_structure(mat)

    # or truncate and construct the structure
    mat[3, 1] <- 0
    as_rvine_structure(mat)

    # throws an error
    mat[3, 1] <- 5
    try(as_rvine_structure(mat))
}

test_4 <- function() {
    ## fitting a continuous model from simulated data
    u <- rbicop(100, "clayton", 90, 3)
    fit <- bicop(u, family_set = "par")
    summary(fit)

    ## compare fit with true model
    contour(fit)
    contour(bicop_dist("clayton", 90, 3), col = 2, add = TRUE)

    ## fit a model from discrete data
    x_disc <- qpois(u, 1)  # transform to Poisson margins
    plot(x_disc)
    udisc <- cbind(ppois(x_disc, 1), ppois(x_disc - 1, 1))
    fit_disc <- bicop(udisc, var_types = c("d", "d"))
    summary(fit_disc)
}

test_5 <- function() {
    ## Clayton 90Â° copula with parameter 3
    cop <- bicop_dist("clayton", 90, 3)
    cop
    str(cop)

    ## visualization
    plot(cop)
    contour(cop)
    plot(rbicop(200, cop))

    ## BB8 copula model for discrete data
    cop_disc <- bicop_dist("bb8", 0, c(2, 0.5), var_types = c("d", "d"))
    cop_disc
}

test_6 <- function() {
    ## evaluate the copula density
    dbicop(c(0.1, 0.2), "clay", 90, 3)
    dbicop(c(0.1, 0.2), bicop_dist("clay", 90, 3))

    ## evaluate the copula cdf
    pbicop(c(0.1, 0.2), "clay", 90, 3)

    ## simulate data
    plot(rbicop(500, "clay", 90, 3))

    ## h-functions
    joe_cop <- bicop_dist("joe", 0, 3)
    # h_1(0.1, 0.2)
    hbicop(c(0.1, 0.2), 1, "bb8", 0, c(2, 0.5))
    # h_2^{-1}(0.1, 0.2)
    hbicop(c(0.1, 0.2), 2, joe_cop, inverse = TRUE)

    ## mixed discrete and continuous data
    x <- cbind(rpois(10, 1), rnorm(10, 1))
    u <- cbind(ppois(x[, 1], 1), pnorm(x[, 2]), ppois(x[, 1] - 1, 1))
    pbicop(u, "clay", 90, 3, var_types = c("d", "c"))
}

test_7 <- function() {
    # Simulate and fit a bivariate copula model
    u <- rbicop(500, "gauss", 0, 0.5)
    fit <- bicop(u, family = "par", keep_data = TRUE)

    # Predictions
    all.equal(predict(fit, u, "hfunc1"), fitted(fit, "hfunc1"),
              check.environment = FALSE)
}

test_8 <- function() {
    # fit ECDF on simulated data
    x <- rnorm(100)
    cdf <- emp_cdf(x)

    # output is bounded away from 0 and 1
    cdf(-50)
    cdf(50)
}

test_9 <- function() {
    # specify pair-copulas
    bicop <- bicop_dist("bb1", 90, c(3, 2))
    pcs <- list(
      list(bicop, bicop), # pair-copulas in first tree
      list(bicop) # pair-copulas in second tree
    )

    # specify R-vine matrix
    mat <- matrix(c(1, 2, 3, 1, 2, 0, 1, 0, 0), 3, 3)

    # set up vine copula model
    vc <- vinecop_dist(pcs, mat)

    # get the structure
    get_structure(vc)
    all(get_matrix(vc) == mat)

    # get pair-copulas
    get_pair_copula(vc, 1, 1)
    get_all_pair_copulas(vc)
    all.equal(get_all_pair_copulas(vc), pcs,
              check.attributes = FALSE, check.environment = FALSE)
}

test_10 <- function() {
    u <- sapply(1:5, function(i) runif(50))
    fit <- vinecop(u, family = "par", keep_data = TRUE)
    mBICV(fit, 0.9) # with a 0.9 prior probability of a non-independence copula
    mBICV(fit, 0.1) # with a 0.1 prior probability of a non-independence copula
}

test_11 <- function() {
    u <- replicate(3, runif(100))
    pairs_copula_data(u)
}

test_12 <- function() {
    # the following are equivalent
    par_to_ktau(bicop_dist("clayton", 0, 3))
    par_to_ktau("clayton", 0, 3)

    ktau_to_par("clayton", 0.5)
    ktau_to_par(bicop_dist("clayton", 0, 3), 0.5)
}

test_13 <- function() {

    ## construct bicop_dist object for a student t copula
    obj <- bicop_dist(family = "t", rotation = 0, parameters = c(0.7, 4))

    ## plots
    plot(obj) # surface plot of copula density
    contour(obj) # contour plot with standard normal margins
    contour(obj, margins = "unif") # contour plot of copula density
}

test_14 <- function() {
    plot(cvine_structure(1:5))
    plot(rvine_structure_sim(5))
    mat <- rbind(c(1, 1, 1), c(2, 2, 0), c(3, 0, 0))
    plot(rvine_matrix(mat))
    plot(rvine_matrix_sim(5))
}

test_15 <- function() {
    # set up vine copula model
    u <- matrix(runif(20 * 10), 20, 10)
    vc <- vinecop(u, family = "indep")

    # plot
    plot(vc, tree = c(1, 2))
    plot(vc, edge_labels = "pair")

    # extract igraph representation
    plt <- plot(vc, edge_labels = "family_tau")
    igr_obj <- get("g", plt$plot_env)[[1]]
    igr_obj  # print object
    igraph::E(igr_obj)$name  # extract edge labels

    # set up another vine copula model
    pcs <- lapply(1:3, function(j) # pair-copulas in tree j
      lapply(runif(4 - j), function(cor) bicop_dist("gaussian", 0, cor)))
    mat <- rvine_matrix_sim(4)
    vc <- vinecop_dist(pcs, mat)

    # contour plot
    contour(vc)
}

test_16 <- function() {
    # pseudo-observations for a vector
    pseudo_obs(rnorm(10))

    # pseudo-observations for a matrix
    pseudo_obs(cbind(rnorm(10), rnorm(10)))
}

test_17 <- function() {
    # simulate data with some dependence
    x <- replicate(3, rnorm(200))
    x[, 2:3] <- x[, 2:3] + x[, 1]
    pairs(x)

    # estimate a vine distribution model
    fit <- vine(x, copula_controls = list(family_set = "par"))

    # transform into independent uniforms
    u <- rosenblatt(x, fit)
    pairs(u)

    # inversion
    pairs(inverse_rosenblatt(u, fit))

    # works similarly for vinecop models
    vc <- fit$copula
    rosenblatt(pseudo_obs(x), vc)
}

test_18 <- function() {

    # R-vine structures can be constructed from the order vector and struct_array
    rvine_structure(order = 1:4, struct_array = list(
      c(4, 4, 4),
      c(3, 3),
      2
    ))

    # R-vine matrices can be constructed from standard matrices
    mat <- matrix(c(4, 3, 2, 1, 4, 3, 2, 0, 4, 3, 0, 0, 4, 0, 0, 0), 4, 4)
    rvine_matrix(mat)

    # coerce to R-vine structure
    str(as_rvine_structure(mat))

    # truncate and construct the R-vine matrix
    mat[3, 1] <- 0
    rvine_matrix(mat)

    # or use directly the R-vine structure constructor
    rvine_structure(order = 1:4, struct_array = list(
      c(4, 4, 4),
      c(3, 3)
    ))

    # throws an error
    mat[3, 1] <- 5
    try(rvine_matrix(mat))

    # C-vine structure
    cvine <- cvine_structure(1:5)
    cvine
    plot(cvine)

    # D-vine structure
    dvine <- dvine_structure(c(1, 4, 2, 3, 5))
    dvine
    plot(dvine)
}

test_19 <- function() {
    rvine_structure_sim(10)

    rvine_structure_sim(10, natural_order = TRUE)  # counter-diagonal is 1:d

    rvine_matrix_sim(10)
}

test_20 <- function() {
    # specify pair-copulas
    bicop <- bicop_dist("bb1", 90, c(3, 2))
    pcs <- list(
      list(bicop, bicop), # pair-copulas in first tree
      list(bicop) # pair-copulas in second tree
    )

    # specify R-vine matrix
    mat <- matrix(c(1, 2, 3, 1, 2, 0, 1, 0, 0), 3, 3)

    # set up vine structure
    structure <- as_rvine_structure(mat)

    # truncate the model
    truncate_model(structure, 1)

    # set up vine copula model
    vc <- vinecop_dist(pcs, mat)

    # truncate the model
    truncate_model(vc, 1)
}

test_21 <- function() {
    # specify pair-copulas
    bicop <- bicop_dist("bb1", 90, c(3, 2))
    pcs <- list(
      list(bicop, bicop), # pair-copulas in first tree
      list(bicop) # pair-copulas in second tree
    )

    # specify R-vine matrix
    mat <- matrix(c(1, 2, 3, 1, 2, 0, 1, 0, 0), 3, 3)

    # set up vine copula model with Gaussian margins
    vc <- vine_dist(list(list(distr = "norm")), pcs, mat)

    # show model
    summary(vc)

    # simulate some data
    x <- rvine(50, vc)

    # estimate a vine copula model
    fit <- vine(x, copula_controls = list(family_set = "par"))
    summary(fit)

    ## model for discrete data
    x <- as.data.frame(x)
    x[, 1] <- ordered(round(x[, 1]), levels = seq.int(-5, 5))
    fit_disc <- vine(x, copula_controls = list(family_set = "par"))
    summary(fit_disc)
}

test_22 <- function() {
    # specify pair-copulas
    bicop <- bicop_dist("bb1", 90, c(3, 2))
    pcs <- list(
      list(bicop, bicop), # pair-copulas in first tree
      list(bicop) # pair-copulas in second tree
    )

    # set up vine copula model
    mat <- rvine_matrix_sim(3)
    vc <- vine_dist(list(list(distr = "norm")), pcs, mat)

    # simulate from the model
    x <- rvine(200, vc)
    pairs(x)

    # evaluate the density and cdf
    dvine(x[1, ], vc)
    pvine(x[1, ], vc)
}

test_23 <- function() {
    x <- sapply(1:5, function(i) rnorm(50))
    fit <- vine(x, copula_controls = list(family_set = "par"), keep_data = TRUE)
    all.equal(predict(fit, x), fitted(fit), check.environment = FALSE)
}

test_24 <- function() {
    ## simulate dummy data
    x <- rnorm(30) * matrix(1, 30, 5) + 0.5 * matrix(rnorm(30 * 5), 30, 5)
    u <- pseudo_obs(x)

    ## fit and select the model structure, family and parameters
    fit <- vinecop(u)
    summary(fit)
    plot(fit)
    contour(fit)

    ## select by log-likelihood criterion from one-paramter families
    fit <- vinecop(u, family_set = "onepar", selcrit = "bic")
    summary(fit)

    ## 1-truncated, Gaussian D-vine
    fit <- vinecop(u, structure = dvine_structure(1:5), family = "gauss", trunc_lvl = 1)
    plot(fit)
    contour(fit)

    ## Partial structure selection with only first tree specified
    structure <- rvine_structure(order = 1:5, list(rep(5, 4)))
    structure
    fit <- vinecop(u, structure = structure, family = "gauss")
    plot(fit)

    ## Model for discrete data
    x <- qpois(u, 1)  # transform to Poisson margins
    # we require two types of observations (see Details)
    u_disc <- cbind(ppois(x, 1), ppois(x - 1, 1))
    fit <- vinecop(u_disc, var_types = rep("d", 5))

    ## Model for mixed data
    x <- qpois(u[, 1], 1)  # transform first variable to Poisson margin
    # we require two types of observations (see Details)
    u_disc <- cbind(ppois(x, 1), u[, 2:5], ppois(x - 1, 1))
    fit <- vinecop(u_disc, var_types = c("d", rep("c", 4)))
}

test_25 <- function() {
    # specify pair-copulas
    bicop <- bicop_dist("bb1", 90, c(3, 2))
    pcs <- list(
      list(bicop, bicop), # pair-copulas in first tree
      list(bicop) # pair-copulas in second tree
    )

    # specify R-vine matrix
    mat <- matrix(c(1, 2, 3, 1, 2, 0, 1, 0, 0), 3, 3)

    # set up vine copula model
    vc <- vinecop_dist(pcs, mat)

    # visualization
    plot(vc)
    contour(vc)

    # simulate from the model
    pairs(rvinecop(200, vc))
}

test_26 <- function() {
    ## simulate dummy data
    x <- rnorm(30) * matrix(1, 30, 5) + 0.5 * matrix(rnorm(30 * 5), 30, 5)
    u <- pseudo_obs(x)

    ## fit a model
    vc <- vinecop(u, family = "clayton")

    # simulate from the model
    u <- rvinecop(100, vc)
    pairs(u)

    # evaluate the density and cdf
    dvinecop(u[1, ], vc)
    pvinecop(u[1, ], vc)

    ## Discrete models
    vc$var_types <- rep("d", 5)  # convert model to discrete

    # with discrete data we need two types of observations (see Details)
    x <- qpois(u, 1)  # transform to Poisson margins
    u_disc <- cbind(ppois(x, 1), ppois(x - 1, 1))

    dvinecop(u_disc[1:5, ], vc)
    pvinecop(u_disc[1:5, ], vc)

    # simulated data always has uniform margins
    pairs(rvinecop(200, vc))
}

test_27 <- function() {
    u <- sapply(1:5, function(i) runif(50))
    fit <- vinecop(u, family = "par", keep_data = TRUE)
    all.equal(predict(fit, u), fitted(fit), check.environment = FALSE)
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

