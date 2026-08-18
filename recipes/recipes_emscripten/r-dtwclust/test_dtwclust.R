print('Loading dtwclust package')
library(dtwclust)
library(dtw)
print('... dtwclust package loaded successfully')

test_1 <- function() {

    dm <- new("DistmatLowerTriangular",
              distmat = proxy::dist(CharTraj[1:5], method = "gak", sigma = 5.5, window.size = 10L))

    dm[2:3, 4:5]
}

test_2 <- function() {

    # load data
    data(uciCT)

    # distance between series of different lengths
    sbd <- SBD(CharTraj[[1]], CharTraj[[100]], znorm = TRUE)$dist

    # cross-distance matrix for series subset (notice the two-list input)
    sbD <- proxy::dist(CharTraj[1:10], CharTraj[1:10], method = "SBD", znorm = TRUE)
}

test_3 <- function() {

    # compare this with leaving no.expand empty
    compare_clusterings_configs(
        distances = pdc_configs("d", dtw_basic = list(window.size = 1L:2L, norm = c("L1", "L2"))),
        centroids = pdc_configs("c", dba = list(window.size = 1L:2L, norm = c("L1", "L2"))),
        no.expand = c("window.size", "norm")
    )
}

test_4 <- function() {

    data(uciCT)

    H <- compute_envelope(CharTraj[[1L]], 18L)

    matplot(do.call(cbind, H), type = "l", col = 2:3)
    lines(CharTraj[[1L]])
}

test_5 <- function() {

    cvi(CharTrajLabels, sample(CharTrajLabels), type = c("ARI", "VI"))
}

test_6 <- function() {

    # Load data
    data(uciCT)

    # Reinterpolate to same length
    data <- reinterpolate(CharTraj, new.length = max(lengths(CharTraj)))

    # Calculate the DTW distance between a certain subset aided with the lower bound
    system.time(d <- dtw_lb(data[1:5], data[6:50], window.size = 20L))

    # Nearest neighbors
    NN1 <- apply(d, 1L, which.min)

    # Calculate the DTW distances between all elements (slower)
    system.time(d2 <- proxy::dist(data[1:5], data[6:50], method = "DTW",
                                  window.type = "sakoechiba", window.size = 20L))

    # Nearest neighbors
    NN2 <- apply(d2, 1L, which.min)

    # Calculate the DTW distances between all elements using dtw_basic
    # (might be faster, see notes)
    system.time(d3 <- proxy::dist(data[1:5], data[6:50], method = "DTW_BASIC",
                                  window.size = 20L))

    # Nearest neighbors
    NN3 <- apply(d3, 1L, which.min)

    # Change order and margin for nearest neighbor search
    # (usually fastest, see notes)
    system.time(d4 <- dtw_lb(data[6:50], data[1:5],
                             window.size = 20L, nn.margin = 2L))

    # Nearest neighbors *column-wise*
    NN4 <- apply(d4, 2L, which.min)

    # Same results?
    identical(NN1, NN2)
    identical(NN1, NN3)
    identical(NN1, NN4)
}

test_7 <- function() {

    # Sample data
    data(uciCT)

    # Lower bound distance between two series
    d.lbi <- lb_improved(CharTraj[[1]], CharTraj[[2]], window.size = 20)

    # Corresponding true DTW distance
    d.dtw <- dtw(CharTraj[[1]], CharTraj[[2]],
                 window.type = "sakoechiba", window.size = 20)$distance

    d.lbi <= d.dtw

    # Calculating the LB between several time series using the 'proxy' package
    # (notice how both argments must be lists)
    D.lbi <- proxy::dist(CharTraj[1], CharTraj[2:5], method = "LB_Improved",
                         window.size = 20, norm = "L2")

    # Corresponding true DTW distance
    D.dtw <- proxy::dist(CharTraj[1], CharTraj[2:5], method = "dtw_basic",
                         norm = "L2", window.size = 20)

    D.lbi <= D.dtw
}

test_8 <- function() {

    # Sample data
    data(uciCT)

    # Lower bound distance between two series
    d.lbk <- lb_keogh(CharTraj[[1]], CharTraj[[2]], window.size = 20)$d

    # Corresponding true DTW distance
    d.dtw <- dtw(CharTraj[[1]], CharTraj[[2]],
                 window.type = "sakoechiba", window.size = 20)$distance

    d.lbk <= d.dtw

    # Calculating the LB between several time series using the 'proxy' package
    # (notice how both argments must be lists)
    D.lbk <- proxy::dist(CharTraj[1], CharTraj[2:5], method = "LB_Keogh",
                         window.size = 20, norm = "L2")

    # Corresponding true DTW distance
    D.dtw <- proxy::dist(CharTraj[1], CharTraj[2:5], method = "dtw_basic",
                         norm = "L2", window.size = 20)

    D.lbk <= D.dtw
}

test_9 <- function() {

    # Computes the distance matrix for all series
    pam_cent(CharTraj, "dtw_basic", ids = 6L:10L, window.size = 15L) # series_id = 7L

    # Computes the distance matrix for the chosen subset only
    pam_cent(CharTraj[6L:10L], "dtw_basic", window.size = 15L) # series_id = 2L
}

test_10 <- function() {

    data(uciCT)

    # list of univariate series
    series <- reinterpolate(CharTraj, 205L)

    # list of multivariate series
    series <- reinterpolate(CharTrajMV, 205L)

    # single multivariate series
    series <- reinterpolate(CharTrajMV[[1L]], 205L, TRUE)
}

test_11 <- function() {

    # Sample data
    data(uciCT)

    # Normalize desired subset
    X <- zscore(CharTraj[1:5])

    # Obtain centroid series
    C <- shape_extraction(X)

    # Result
    matplot(do.call(cbind, X),
            type = "l", col = 1:5)
    points(C)
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

