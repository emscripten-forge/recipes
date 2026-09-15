print('Loading parallelly package')
library(parallelly)
print('... parallelly package loaded successfully')

test_1 <- function() {
    cl1 <- makeClusterPSOCK(2, dryrun = TRUE)
    cl2 <- makeClusterPSOCK(c("n1", "server.remote.org"), dryrun = TRUE)
    cl <- c(cl1, cl2)
    print(cl)
}

test_2 <- function() {
    cl <- makeClusterPSOCK(2, dryrun = TRUE)
    cl <- autoStopCluster(cl)
    print(cl)
    rm(list = "cl")
    gc()
}

test_3 <- function() {
    total <- availableConnections()
    message("You can have ", total, " connections open in this R installation")
    free <- freeConnections()
    message("There are ", free, " connections remaining")
}


print("Running test_1")
test_1()

print("Running test_2")
test_2()

print("Running test_3")
test_3()


