print('Loading clue package')
library(clue)
print('... clue package loaded successfully')

library(quadprog)

test_1 <- function() {
    data("Cassini")
    op <- par(mfcol = c(1, 2))
    ## Plot the data set:
    plot(Cassini$x, col = as.integer(Cassini$classes),
         xlab = "", ylab = "")
    ## Create a "random" k-means partition of the data:
    set.seed(1234)
    party <- kmeans(Cassini$x, 3)
    ## And plot that.
    plot(Cassini$x, col = cl_class_ids(party),
         xlab = "", ylab = "")
    ## (We can see the problem ...)
    par(op)
}

test_2 <- function() {
    ## Load the consensus partitions.
    data("GVME_Consensus")
    ## Pick the partitions into 2 classes.
    GVME_Consensus_2 <- GVME_Consensus[1 : 4]
    ## Fuzziness using the Partition Coefficient.
    cl_fuzziness(GVME_Consensus_2)
    ## (Corresponds to 1 - F in the source.)
    ## Dissimilarities:
    cl_dissimilarity(GVME_Consensus_2)
    cl_dissimilarity(GVME_Consensus_2, method = "comem")
}

test_3 <- function() {
    ## Load the consensus partitions.
    data("Kinship82_Consensus")
    ## Fuzziness using the Partition Coefficient.
    cl_fuzziness(Kinship82_Consensus)
    ## (Corresponds to 1 - F in the source.)
    ## Dissimilarities:
    cl_dissimilarity(Kinship82_Consensus)
    cl_dissimilarity(Kinship82_Consensus, method = "comem")
}

test_4 <- function() {
    ## An ensemble of partitions.
    data("CKME")
    pens <- CKME[1 : 20]		# for saving precious time ...
    summary(c(cl_agreement(pens)))
    summary(c(cl_agreement(pens, method = "Rand")))
    summary(c(cl_agreement(pens, method = "diag")))
    cl_agreement(pens[1:5], pens[6:7], method = "NMI")
    ## Equivalently, using subscripting.
    cl_agreement(pens, method = "NMI")[1:5, 6:7]

    ## An ensemble of hierarchies.
    d <- dist(USArrests)
    hclust_methods <-
        c("ward", "single", "complete", "average", "mcquitty")
    hclust_results <- lapply(hclust_methods, function(m) hclust(d, m))
    names(hclust_results) <- hclust_methods 
    hens <- cl_ensemble(list = hclust_results)
    summary(c(cl_agreement(hens)))
    ## Note that the Euclidean agreements are *very* small.
    ## This is because the ultrametrics differ substantially in height:
    u <- lapply(hens, cl_ultrametric)
    round(sapply(u, max), 3)
    ## Rescaling the ultrametrics to [0, 1] gives:
    u <- lapply(u, function(x) (x - min(x)) / (max(x) - min(x)))
    shens <- cl_ensemble(list = lapply(u, as.cl_dendrogram))
    summary(c(cl_agreement(shens)))
    ## Au contraire ...
    summary(c(cl_agreement(hens, method = "cophenetic")))
    cl_agreement(hens[1:3], hens[4:5], method = "gamma")
}

test_5 <- function() {
    set.seed(1234)
    ## Run BagClust1 on the Cassini data.
    data("Cassini")
    party <- cl_bag(Cassini$x, 50, 3)
    plot(Cassini$x, col = cl_class_ids(party), xlab = "", ylab = "")
    ## Actually, using fuzzy c-means as a base learner works much better:
    if(require("e1071", quietly = TRUE)) {
        party <- cl_bag(Cassini$x, 20, 3, algorithm = "cmeans")
        plot(Cassini$x, col = cl_class_ids(party), xlab = "", ylab = "")
    }
}

test_6 <- function() {
    ## Study e.g. the effect of random kmeans() initializations.
    data("Cassini")
    pens <- cl_boot(Cassini$x, 15, 3)
    diss <- cl_dissimilarity(pens)
    summary(c(diss))
    plot(hclust(diss))
}

test_7 <- function() {
    ## Consensus partition for the Rosenberg-Kim kinship terms partition
    ## data based on co-membership dissimilarities.
    data("Kinship82")
    m1 <- cl_consensus(Kinship82, method = "GV3",
                       control = list(k = 3, verbose = TRUE))
    ## (Note that one should really use several replicates of this.)
    ## Value for criterion function to be minimized:
    sum(cl_dissimilarity(Kinship82, m1, "comem") ^ 2)
    ## Compare to the consensus solution given in Gordon & Vichi (2001).
    data("Kinship82_Consensus")
    m2 <- Kinship82_Consensus[["JMF"]]
    sum(cl_dissimilarity(Kinship82, m2, "comem") ^ 2)
    ## Seems we get a better solution ...
    ## How dissimilar are these solutions?
    cl_dissimilarity(m1, m2, "comem")
    ## How "fuzzy" are they?
    cl_fuzziness(cl_ensemble(m1, m2))
    ## Do the "nearest" hard partitions fully agree?
    cl_dissimilarity(as.cl_hard_partition(m1),
                     as.cl_hard_partition(m2))

    ## Consensus partition for the Gordon and Vichi (2001) macroeconomic
    ## partition data based on Euclidean dissimilarities.
    data("GVME")
    set.seed(1)
    ## First, using k = 2 classes.
    m1 <- cl_consensus(GVME, method = "GV1",
                       control = list(k = 2, verbose = TRUE))
    ## (Note that one should really use several replicates of this.)
    ## Value of criterion function to be minimized:
    sum(cl_dissimilarity(GVME, m1, "GV1") ^ 2)
    ## Compare to the consensus solution given in Gordon & Vichi (2001).
    data("GVME_Consensus")
    m2 <- GVME_Consensus[["MF1/2"]]
    sum(cl_dissimilarity(GVME, m2, "GV1") ^ 2)
    ## Seems we get a slightly  better solution ...
    ## But note that
    cl_dissimilarity(m1, m2, "GV1")
    ## and that the maximal deviation of the memberships is
    max(abs(cl_membership(m1) - cl_membership(m2)))
    ## so the differences seem to be due to rounding.
    ## Do the "nearest" hard partitions fully agree?
    table(cl_class_ids(m1), cl_class_ids(m2))

    ## And now for k = 3 classes.
    m1 <- cl_consensus(GVME, method = "GV1",
                       control = list(k = 3, verbose = TRUE))
    sum(cl_dissimilarity(GVME, m1, "GV1") ^ 2)
    ## Compare to the consensus solution given in Gordon & Vichi (2001).
    m2 <- GVME_Consensus[["MF1/3"]]
    sum(cl_dissimilarity(GVME, m2, "GV1") ^ 2)
    ## This time we look much better ...
    ## How dissimilar are these solutions?
    cl_dissimilarity(m1, m2, "GV1")
    ## Do the "nearest" hard partitions fully agree?
    table(cl_class_ids(m1), cl_class_ids(m2))
}

test_8 <- function() {
    ## An ensemble of partitions.
    data("CKME")
    pens <- CKME[1 : 30]
    diss <- cl_dissimilarity(pens)
    summary(c(diss))
    cl_dissimilarity(pens[1:5], pens[6:7])
    ## Equivalently, using subscripting.
    diss[1:5, 6:7]
    ## Can use the dissimilarities for "secondary" clustering
    ## (e.g. obtaining hierarchies of partitions):
    hc <- hclust(diss)
    plot(hc)

    ## Example from Boorman and Arabie (1972).
    P1 <- as.cl_partition(c(1, 2, 2, 2, 3, 3, 2, 2))
    P2 <- as.cl_partition(c(1, 1, 2, 2, 3, 3, 4, 4))
    cl_dissimilarity(P1, P2, "BA/A")
    cl_dissimilarity(P1, P2, "BA/C")

    ## Hierarchical clustering.
    d <- dist(USArrests)
    x <- hclust(d)
    cl_dissimilarity(x, d, "cophenetic")
    cl_dissimilarity(x, d, "gamma")
}

test_9 <- function() {
    d <- dist(USArrests)
    hclust_methods <-
        c("ward", "single", "complete", "average", "mcquitty")
    hclust_results <- lapply(hclust_methods, function(m) hclust(d, m))
    names(hclust_results) <- hclust_methods 
    ## Now create an ensemble from the results.
    hens <- cl_ensemble(list = hclust_results)
    hens
    ## Subscripting.
    hens[1 : 3]
    ## Replication.
    rep(hens, 3)
    ## Plotting.
    plot(hens, main = names(hens))
    ## And continue to analyze the ensemble, e.g.
    round(cl_dissimilarity(hens, method = "gamma"), 4)
}

test_10 <- function() {
    if(require("e1071", quietly = TRUE)) {
        ## Use an on-line version of fuzzy c-means from package e1071 if
        ## available.
        data("Cassini")
        pens <- cl_boot(Cassini$x, B = 15, k = 3, algorithm = "cmeans",
                        parameters = list(method = "ufcl"))
        pens
        summary(cl_fuzziness(pens, "PC"))
        summary(cl_fuzziness(pens, "PE"))
    }
}

test_11 <- function() {
    data("GVME")
    ## Look at the classes obtained for 1980:
    split(cl_object_names(GVME[["1980"]]), cl_class_ids(GVME[["1980"]]))
    ## Margins:
    x <- cl_margin(GVME[["1980"]])
    ## Add names, and sort:
    names(x) <- cl_object_names(GVME[["1980"]])
    sort(x)
    ## Note the "uncertainty" of assigning Egypt to the "intermediate" class
    ## of nations.
}

test_12 <- function() {
    ## An ensemble of partitions.
    data("CKME")
    pens <- CKME[1 : 20]
    m1 <- cl_medoid(pens)
    diss <- cl_dissimilarity(pens)
    require("cluster")
    m2 <- pens[[pam(diss, 1)$medoids]]
    ## Agreement of medoid consensus partitions.
    cl_agreement(m1, m2)
    ## Or, more straightforwardly:
    table(cl_class_ids(m1), cl_class_ids(m2))
}

test_13 <- function() {
    ## Getting the memberships of a single soft partition.
    d <- dist(USArrests)
    hclust_methods <-
        c("ward", "single", "complete", "average", "mcquitty")
    hclust_results <- lapply(hclust_methods, function(m) hclust(d, m))
    names(hclust_results) <- hclust_methods 
    ## Now create an ensemble from the results.
    hens <- cl_ensemble(list = hclust_results)
    ## And add the results of agnes and diana.
    require("cluster")
    hens <- c(hens, list(agnes = agnes(d), diana = diana(d)))
    ## Create a dissimilarity object from this.
    d1 <- cl_dissimilarity(hens)
    ## And compute a soft partition.
    party <- fanny(d1, 2)
    round(cl_membership(party), 5)
    ## The "nearest" hard partition to this:
    as.cl_hard_partition(party)
    ## (which has the same class ids as cl_class_ids(party)).

    ## Extracting the memberships from the elements of an ensemble of
    ## partitions.
    pens <- cl_boot(USArrests, 30, 3)
    pens
    mems <- lapply(pens, cl_membership)
    ## And turning these raw memberships into an ensemble of partitions.
    pens <- cl_ensemble(list = lapply(mems, as.cl_partition))
    pens
    pens[[length(pens)]]
}

test_14 <- function() {
    data("Kinship82")
    party <- cl_pam(Kinship82, 3, "symdiff")
    ## Compare results with tables 5 and 6 in Gordon & Vichi (1998).
    party
    lapply(cl_prototypes(party), cl_classes)
    table(cl_class_ids(party))
}

test_15 <- function() {
    ## Use a precomputed ensemble of 50 k-means partitions of the
    ## Cassini data.
    data("CKME")
    CKME <- CKME[1 : 30]		# for saving precious time ...
    diss <- cl_dissimilarity(CKME)
    hc <- hclust(diss)
    plot(hc)
    ## This suggests using a partition with three classes, which can be
    ## obtained using cutree(hc, 3).  Could use cl_consensus() to compute
    ## prototypes as the least squares consensus clusterings of the classes,
    ## or alternatively:
    set.seed(123)
    x1 <- cl_pclust(CKME, 3, m = 1)
    x2 <- cl_pclust(CKME, 3, m = 2)
    ## Agreement of solutions.
    cl_dissimilarity(x1, x2)
    table(cl_class_ids(x1), cl_class_ids(x2))
}

test_16 <- function() {
    ## Run kmeans on a random subset of the Cassini data, and predict the
    ## memberships for the "test" data set.
    data("Cassini")
    nr <- NROW(Cassini$x)
    ind <- sample(nr, 0.9 * nr, replace = FALSE)
    party <- kmeans(Cassini$x[ind, ], 3)
    table(cl_predict(party, Cassini$x[-ind, ]),
          Cassini$classes[-ind])
}

test_17 <- function() {
    ## Show how prototypes ("centers") vary across k-means runs on
    ## bootstrap samples from the Cassini data.
    data("Cassini")
    nr <- NROW(Cassini$x)
    out <- replicate(50,
                     { kmeans(Cassini$x[sample(nr, replace = TRUE), ], 3) },
                     simplify = FALSE)
    ## Plot the data points in light gray, and the prototypes found.
    plot(Cassini$x, col = gray(0.8))
    points(do.call("rbind", lapply(out, cl_prototypes)), pch = 19)
}

test_18 <- function() {
    data("Kinship82")
    tab <- cl_tabulate(Kinship82)
    ## The counts:
    tab$counts
    ## The most frequent partition:
    tab$values[[which.max(tab$counts)]]
}

test_19 <- function() {
    hc <- hclust(dist(USArrests))
    u <- cl_ultrametric(hc)
    ## Subscripting.
    u[1 : 5, 1 : 5]
    u[1 : 5, 6 : 7]
    ## Plotting.
    plot(u)
}

test_20 <- function() {
    data("Phonemes")
    ## Note that the Phonemes data set has the consonant misclassification
    ## probabilities, i.e., the similarities between the phonemes.
    d <- as.dist(1 - Phonemes)
    ## Find the maximal dominated and miminal dominating ultrametrics by
    ## hclust() with single and complete linkage:
    y1 <- hclust(d, "single")
    y2 <- hclust(d, "complete")
    ## Note that these are quite different:
    cl_dissimilarity(y1, y2, "gamma")
    ## Now find the L2 optimal members of the respective dendrogram
    ## equivalence classes.
    u1 <- ls_fit_ultrametric_target(d, y1)
    u2 <- ls_fit_ultrametric_target(d, y2)
    ## Compute the L2 optimal ultrametric approximation to d.
    u <- ls_fit_ultrametric(d)
    ## And compare ...
    cl_dissimilarity(cl_ensemble(Opt = u, Single = u1, Complete = u2), d)
    ## The solution obtained via complete linkage is quite close:
    cl_agreement(u2, u, "cophenetic")
}

test_21 <- function() {
    hcl <- hclust(dist(USArrests))
    is.cl_dendrogram(hcl)
    is.cl_hierarchy(hcl)
}

test_22 <- function() {
    ## Two simple partitions of 7 objects.
    A <- as.cl_partition(c(1, 1, 2, 3, 3, 5, 5))
    B <- as.cl_partition(c(1, 2, 2, 3, 4, 5, 5))
    ## These disagree on objects 1-3, A splits objects 4 and 5 into
    ## separate classes.  Objects 6 and 7 are always in the same class.
    (A <= B) || (B <= A)
    ## (Neither partition is finer than the other.)
    cl_meet(A, B)
    cl_join(A, B)
    ## Meeting with the lumper (greatest) or joining with the splitter
    ## (least) partition does not make a difference: 
    C_lumper <- as.cl_partition(rep(1, n_of_objects(A)))
    cl_meet(cl_ensemble(A, B, C_lumper))
    C_splitter <- as.cl_partition(seq_len(n_of_objects(A)))
    cl_join(cl_ensemble(A, B, C_splitter))
    ## Another way of computing the join:
    range(A, B, C_splitter)$max
}

test_23 <- function() {
    ## Least squares fit of an ultrametric to the Miller-Nicely consonant
    ## phoneme confusion data.
    data("Phonemes")
    ## Note that the Phonemes data set has the consonant misclassification
    ## probabilities, i.e., the similarities between the phonemes.
    d <- as.dist(1 - Phonemes)
    u <- ls_fit_ultrametric(d, control = list(verbose = TRUE))
    ## Cophenetic correlation:
    cor(d, u)
    ## Plot:
    plot(u)
    ## ("Basically" the same as Figure 1 in de Soete (1984b).)
}

test_24 <- function() {
    data("Cassini")
    party <- kmeans(Cassini$x, 3)
    n_of_classes(party)
    ## A simple confusion matrix:
    table(cl_class_ids(party), Cassini$classes)
    ## For an "oversize" membership matrix representation:
    n_of_classes(cl_membership(party, 6))
}

test_25 <- function() {
    data("Cassini")
    pcl <- kmeans(Cassini$x, 3)
    n_of_objects(pcl)
    hcl <- hclust(dist(USArrests))
    n_of_objects(hcl)
}

test_26 <- function() {
    data("Cassini")
    pcl <- kmeans(Cassini$x, 3)
    is.cl_partition(pcl)
    is.cl_hard_partition(pcl)
    is.cl_soft_partition(pcl)
}

test_27 <- function() {
    x <- matrix(c(5, 1, 4, 3, 5, 2, 2, 4, 4), nrow = 3)
    solve_LSAP(x)
    solve_LSAP(x, maximum = TRUE)
    ## To get the optimal value (for now):
    y <- solve_LSAP(x)
    sum(x[cbind(seq_along(y), y)])
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

