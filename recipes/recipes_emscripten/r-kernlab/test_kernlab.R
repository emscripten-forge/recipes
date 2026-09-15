library(kernlab)
test_1 <- function() {
    ## Create toy data
    x <- rbind(matrix(rnorm(10),,2),matrix(rnorm(10,mean=3),,2))
    y <- matrix(c(rep(1,5),rep(-1,5)))

    ### Use as.kernelMatrix to label the cov. matrix as a kernel matrix
    ### which is eq. to using a linear kernel 

    K <- as.kernelMatrix(crossprod(t(x)))

    K

    svp2 <- ksvm(K, y, type="C-svc")

    svp2
}

test_2 <- function() {
    ## create artificial pairwise probabilities
    pairs <- matrix(c(0.82,0.12,0.76,0.1,0.9,0.05),2)

    couple(pairs)

    couple(pairs, coupler="pkpd")

    couple(pairs, coupler ="vote")
}

test_3 <- function() {

    data(iris)

    ## create multidimensional y matrix
    yind <- t(matrix(1:3,3,150))
    ymat <- matrix(0, 150, 3)
    ymat[yind==as.integer(iris[,5])] <- 1

    datamatrix <- as.matrix(iris[,-5])
    # initialize kernel function
    rbf <- rbfdot(sigma=0.1)
    rbf
    Z <- csi(datamatrix,ymat, kernel=rbf, rank = 30)
    dim(Z)
    pivots(Z)
    # calculate kernel matrix
    K <- crossprod(t(Z))
    # difference between approximated and real kernel matrix
    (K - kernelMatrix(kernel=rbf, datamatrix))[6,]
}

test_4 <- function() {
    data(iris)

    ## create multidimensional y matrix
    yind <- t(matrix(1:3,3,150))
    ymat <- matrix(0, 150, 3)
    ymat[yind==as.integer(iris[,5])] <- 1

    datamatrix <- as.matrix(iris[,-5])
    # initialize kernel function
    rbf <- rbfdot(sigma=0.1)
    rbf
    Z <- csi(datamatrix,ymat, kernel=rbf, rank = 30)
    dim(Z)
    pivots(Z)
    # calculate kernel matrix
    K <- crossprod(t(Z))
    # difference between approximated and real kernel matrix
    (K - kernelMatrix(kernel=rbf, datamatrix))[6,]
}

test_5 <- function() {
    rbfkernel <- rbfdot(sigma = 0.1)
    rbfkernel

    kpar(rbfkernel)

    ## create two vectors
    x <- rnorm(10)
    y <- rnorm(10)

    ## calculate dot product
    rbfkernel(x,y)
}

test_6 <- function() {
    # train model
    data(iris)
    test <- gausspr(Species~.,data=iris,var=2)
    test
    alpha(test)

    # predict on the training set
    predict(test,iris[,-5])
    # class probabilities 
    predict(test, iris[,-5], type="probabilities")

    # create regression data
    x <- seq(-20,20,0.1)
    y <- sin(x)/x + rnorm(401,sd=0.03)

    # regression with gaussian processes
    foo <- gausspr(x, y)
    foo

    # predict and plot
    ytest <- predict(foo, x)
    plot(x, y, type ="l")
    lines(x, ytest, col="red")


    #predict and variance
    x = c(-4, -3, -2, -1,  0, 0.5, 1, 2)
    y = c(-2,  0,  -0.5,1,  2, 1, 0, -1)
    plot(x,y)
    foo2 <- gausspr(x, y, variance.model = TRUE)
    xtest <- seq(-4,2,0.2)
    lines(xtest, predict(foo2, xtest))
    lines(xtest,
          predict(foo2, xtest)+2*predict(foo2,xtest, type="sdeviation"),
          col="red")
    lines(xtest,
          predict(foo2, xtest)-2*predict(foo2,xtest, type="sdeviation"),
          col="red")
}

test_7 <- function() {

    # train model
    data(iris)
    test <- gausspr(Species~.,data=iris,var=2)
    test
    alpha(test)
    error(test)
    lev(test)
}

test_8 <- function() {

    data(iris)
    datamatrix <- as.matrix(iris[,-5])
    # initialize kernel function
    rbf <- rbfdot(sigma=0.1)
    rbf
    Z <- inchol(datamatrix,kernel=rbf)
    dim(Z)
    pivots(Z)
    # calculate kernel matrix
    K <- crossprod(t(Z))
    # difference between approximated and real kernel matrix
    (K - kernelMatrix(kernel=rbf, datamatrix))[6,]
}

test_9 <- function() {
    data(iris)
    datamatrix <- as.matrix(iris[,-5])
    # initialize kernel function
    rbf <- rbfdot(sigma=0.1)
    rbf
    Z <- inchol(datamatrix,kernel=rbf)
    dim(Z)
    pivots(Z)
    diagresidues(Z)
    maxresiduals(Z)
}

test_10 <- function() {

    ## create toy data set
    x <- rbind(matrix(rnorm(100),,2),matrix(rnorm(100)+3,,2))
    y <- matrix(c(rep(1,50),rep(-1,50)),,1)

    ## initialize onlearn object
    on <- inlearn(2, kernel = "rbfdot", kpar = list(sigma = 0.2),
                  type = "classification")

    ## learn one data point at the time
    for(i in sample(1:100,100))
    on <- onlearn(on,x[i,],y[i],nu=0.03,lambda=0.1)

    sign(predict(on,x))
}

test_11 <- function() {
    ## solve the Support Vector Machine optimization problem
    data(spam)

    ## sample a scaled part (500 points) of the spam data set
    m <- 500
    set <- sample(1:dim(spam)[1],m)
    x <- scale(as.matrix(spam[,-58]))[set,]
    y <- as.integer(spam[set,58])
    y[y==2] <- -1

    ##set C parameter and kernel
    C <- 5
    rbf <- rbfdot(sigma = 0.1)

    ## create H matrix etc.
    H <- kernelPol(rbf,x,,y)
    c <- matrix(rep(-1,m))
    A <- t(y)
    b <- 0
    l <- matrix(rep(0,m))
    u <- matrix(rep(C,m))
    r <- 0

    sv <- ipop(c,H,A,b,l,u,r)
    sv
    dual(sv)
}

test_12 <- function() {
    ## solve the Support Vector Machine optimization problem
    data(spam)

    ## sample a scaled part (300 points) of the spam data set
    m <- 300
    set <- sample(1:dim(spam)[1],m)
    x <- scale(as.matrix(spam[,-58]))[set,]
    y <- as.integer(spam[set,58])
    y[y==2] <- -1

    ##set C parameter and kernel
    C <- 5
    rbf <- rbfdot(sigma = 0.1)

    ## create H matrix etc.
    H <- kernelPol(rbf,x,,y)
    c <- matrix(rep(-1,m))
    A <- t(y)
    b <- 0
    l <- matrix(rep(0,m))
    u <- matrix(rep(C,m))
    r <- 0

    sv <- ipop(c,H,A,b,l,u,r)
    primal(sv)
    dual(sv)
    how(sv)
}

test_13 <- function() {

    ## dummy data
    x <- matrix(rnorm(30),15)
    y <- matrix(rnorm(30),15)

    kcca(x,y,ncomps=2)
}

test_14 <- function() {

    ## dummy data
    x <- matrix(rnorm(30),15)
    y <- matrix(rnorm(30),15)

    kcca(x,y,ncomps=2)
}

test_15 <- function() {

    rbfkernel <- rbfdot(sigma = 0.1)
    rbfkernel
    is(rbfkernel)
    kpar(rbfkernel)
}

test_16 <- function() {
    ## use the spam data
    data(spam)
    dt <- as.matrix(spam[c(10:20,3000:3010),-58])

    ## initialize kernel function 
    rbf <- rbfdot(sigma = 0.05)
    rbf

    ## calculate kernel matrix
    kernelMatrix(rbf, dt)

    yt <- as.matrix(as.integer(spam[c(10:20,3000:3010),58]))
    yt[yt==2] <- -1

    ## calculate the quadratic kernel expression
    kernelPol(rbf, dt, ,yt)

    ## calculate the kernel expansion
    kernelMult(rbf, dt, ,yt)
}

test_17 <- function() {
    data(promotergene)
    f <- kfa(~.,data=promotergene,features=2,kernel="rbfdot",
             kpar=list(sigma=0.01))
    plot(predict(f,promotergene),col=as.numeric(promotergene[,1]))
}

test_18 <- function() {
    data(promotergene)
    f <- kfa(~.,data=promotergene)
}

test_19 <- function() {
    # another example using the iris
    data(iris)
    test <- sample(1:150,70)

    kpc <- kha(~.,data=iris[-test,-5],kernel="rbfdot",
               kpar=list(sigma=0.2),features=2, eta=0.001, maxiter=65)

    #print the principal component vectors
    pcv(kpc)

    #plot the data projection on the components
    plot(predict(kpc,iris[,-5]),col=as.integer(iris[,5]),
         xlab="1st Principal Component",ylab="2nd Principal Component")
}

test_20 <- function() {
    # another example using the iris
    data(iris)
    test <- sample(1:50,20)

    kpc <- kha(~.,data=iris[-test,-5], kernel="rbfdot",
               kpar=list(sigma=0.2),features=2, eta=0.001, maxiter=65)

    #print the principal component vectors
    pcv(kpc)
    kernelf(kpc)
    eig(kpc)
}

test_21 <- function() {
    ## Cluster the iris data set.
    data(iris)

    sc <- kkmeans(as.matrix(iris[,-5]), centers=3)

    sc
    centers(sc)
    size(sc)
    withinss(sc)
}

test_22 <- function() {
    # create data
    x <- matrix(runif(300),100)
    y <- matrix(runif(300)+1,100)


    mmdo <- kmmd(x, y)

    mmdo
}

test_23 <- function() {
    # create data
    x <- matrix(runif(300),100)
    y <- matrix(runif(300)+1,100)


    mmdo <- kmmd(x, y)

    H0(mmdo)
}

test_24 <- function() {
    # another example using the iris
    data(iris)
    test <- sample(1:150,20)

    kpc <- kpca(~.,data=iris[-test,-5],kernel="rbfdot",
                kpar=list(sigma=0.2),features=2)

    #print the principal component vectors
    pcv(kpc)

    #plot the data projection on the components
    plot(rotated(kpc),col=as.integer(iris[-test,5]),
         xlab="1st Principal Component",ylab="2nd Principal Component")

    #embed remaining points 
    emb <- predict(kpc,iris[test,-5])
    points(emb,col=as.integer(iris[test,5]))
}

test_25 <- function() {
    # another example using the iris
    data(iris)
    test <- sample(1:50,20)

    kpc <- kpca(~.,data=iris[-test,-5],kernel="rbfdot",
                kpar=list(sigma=0.2),features=2)

    #print the principal component vectors
    pcv(kpc)
    rotated(kpc)
    kernelf(kpc)
    eig(kpc)
}

test_26 <- function() {
    # create data
    x <- sort(runif(300))
    y <- sin(pi*x) + rnorm(300,0,sd=exp(sin(2*pi*x)))

    # first calculate the median
    qrm <- kqr(x, y, tau = 0.5, C=0.15)

    # predict and plot
    plot(x, y)
    ytest <- predict(qrm, x)
    lines(x, ytest, col="blue")

    # calculate 0.9 quantile
    qrm <- kqr(x, y, tau = 0.9, kernel = "rbfdot",
               kpar= list(sigma=10), C=0.15)
    ytest <- predict(qrm, x)
    lines(x, ytest, col="red")

    # calculate 0.1 quantile
    qrm <- kqr(x, y, tau = 0.1,C=0.15)
    ytest <- predict(qrm, x)
    lines(x, ytest, col="green")

    # print first 10 model coefficients
    coef(qrm)[1:10]
}

test_27 <- function() {


    # create data
    x <- sort(runif(300))
    y <- sin(pi*x) + rnorm(300,0,sd=exp(sin(2*pi*x)))

    # first calculate the median
    qrm <- kqr(x, y, tau = 0.5, C=0.15)

    # predict and plot
    plot(x, y)
    ytest <- predict(qrm, x)
    lines(x, ytest, col="blue")

    # calculate 0.9 quantile
    qrm <- kqr(x, y, tau = 0.9, kernel = "rbfdot",
               kpar = list(sigma = 10), C = 0.15)
    ytest <- predict(qrm, x)
    lines(x, ytest, col="red")

    # print model coefficients and other information
    coef(qrm)
    b(qrm)
    error(qrm)
    kernelf(qrm)
}

test_28 <- function() {

    ## simple example using the spam data set
    data(spam)

    ## create test and training set
    index <- sample(1:dim(spam)[1])
    spamtrain <- spam[index[1:floor(dim(spam)[1]/2)], ]
    spamtest <- spam[index[((ceiling(dim(spam)[1]/2)) + 1):dim(spam)[1]], ]

    ## train a support vector machine
    filter <- ksvm(type~.,data=spamtrain,kernel="rbfdot",
                   kpar=list(sigma=0.05),C=5,cross=3)
    filter

    ## predict mail type on the test set
    mailtype <- predict(filter,spamtest[,-58])

    ## Check results
    table(mailtype,spamtest[,58])


    ## Another example with the famous iris data
    data(iris)

    ## Create a kernel function using the build in rbfdot function
    rbf <- rbfdot(sigma=0.1)
    rbf

    ## train a bound constraint support vector machine
    irismodel <- ksvm(Species~.,data=iris,type="C-bsvc",
                      kernel=rbf,C=10,prob.model=TRUE)

    irismodel

    ## get fitted values
    fitted(irismodel)

    ## Test on the training set with probabilities as output
    predict(irismodel, iris[,-5], type="probabilities")


    ## Demo of the plot function
    x <- rbind(matrix(rnorm(120),,2),matrix(rnorm(120,mean=3),,2))
    y <- matrix(c(rep(1,60),rep(-1,60)))

    svp <- ksvm(x,y,type="C-svc")
    plot(svp,data=x)


    ### Use kernelMatrix
    K <- as.kernelMatrix(crossprod(t(x)))

    svp2 <- ksvm(K, y, type="C-svc")

    svp2

    # test data
    xtest <- rbind(matrix(rnorm(20),,2),matrix(rnorm(20,mean=3),,2))
    # test kernel matrix i.e. inner/kernel product of test data with
    # Support Vectors

    Ktest <- as.kernelMatrix(crossprod(t(xtest),t(x[SVindex(svp2), ])))

    predict(svp2, Ktest)


    #### Use custom kernel 

    k <- function(x,y) {(sum(x*y) +1)*exp(-0.001*sum((x-y)^2))}
    class(k) <- "kernel"

    data(promotergene)

    ## train svm using custom kernel
    gene <- ksvm(Class~.,data=promotergene[c(1:20, 80:100),],kernel=k,
                 C=5,cross=5)

    gene


    #### Use text with string kernels
    data(reuters)
    is(reuters)
    tsv <- ksvm(reuters,rlabels,kernel="stringdot",
                kpar=list(length=5),cross=3,C=10)
    tsv


    ## regression
    # create data
    x <- seq(-20,20,0.1)
    y <- sin(x)/x + rnorm(401,sd=0.03)

    # train support vector machine
    regm <- ksvm(x,y,epsilon=0.01,kpar=list(sigma=16),cross=3)
    plot(x,y,type="l")
    lines(x,predict(regm,x),col="red")
}

test_29 <- function() {
    ## simple example using the promotergene data set
    data(promotergene)

    ## train a support vector machine
    gene <- ksvm(Class~.,data=promotergene,kernel="rbfdot",
                 kpar=list(sigma=0.015),C=50,cross=4)
    gene

    # the kernel  function
    kernelf(gene)
    # the alpha values
    alpha(gene)
    # the coefficients
    coef(gene)
    # the fitted values
    fitted(gene)
    # the cross validation error
    cross(gene)
}

test_30 <- function() {
    ## simple example
    data(iris)

    lir <- lssvm(Species~.,data=iris)

    lir

    lirr <- lssvm(Species~.,data= iris, reduced = FALSE)

    lirr

    ## Using the kernelMatrix interface

    iris <- unique(iris)

    rbf <- rbfdot(0.5)

    k <- kernelMatrix(rbf, as.matrix(iris[,-5]))

    klir <- lssvm(k, iris[, 5])

    klir

    pre <- predict(klir, k)
}

test_31 <- function() {

    # train model
    data(iris)
    test <- lssvm(Species~.,data=iris,var=2)
    test
    alpha(test)
    error(test)
    lev(test)
}

test_32 <- function() {
    data(musk)

    muskm <- ksvm(Class~.,data=musk,kernel="rbfdot",C=1000)

    muskm
}

test_33 <- function() {

    ## create toy data set
    x <- rbind(matrix(rnorm(100),,2),matrix(rnorm(100)+3,,2))
    y <- matrix(c(rep(1,50),rep(-1,50)),,1)

    ## initialize onlearn object
    on <- inlearn(2,kernel="rbfdot",kpar=list(sigma=0.2),
                  type="classification")

    ind <- sample(1:100,100)
    ## learn one data point at the time
    for(i in ind)
    on <- onlearn(on,x[i,],y[i],nu=0.03,lambda=0.1)

    ## or learn all the data 
    on <- onlearn(on,x[ind,],y[ind],nu=0.03,lambda=0.1)

    sign(predict(on,x))
}

test_34 <- function() {

    ## create toy data set
    x <- rbind(matrix(rnorm(100),,2),matrix(rnorm(100)+3,,2))
    y <- matrix(c(rep(1,50),rep(-1,50)),,1)

    ## initialize onlearn object
    on <- inlearn(2,kernel="rbfdot",kpar=list(sigma=0.2),
                  type="classification")

    ## learn one data point at the time
    for(i in sample(1:100,100))
    on <- onlearn(on,x[i,],y[i],nu=0.03,lambda=0.1)

    sign(predict(on,x))
}

test_35 <- function() {
    ## Demo of the plot function
    x <- rbind(matrix(rnorm(120),,2),matrix(rnorm(120,mean=3),,2))
    y <- matrix(c(rep(1,60),rep(-1,60)))

    svp <- ksvm(x,y,type="C-svc")
    plot(svp,data=x)
}

test_36 <- function() {

    ## example using the promotergene data set
    data(promotergene)

    ## create test and training set
    ind <- sample(1:dim(promotergene)[1],20)
    genetrain <- promotergene[-ind, ]
    genetest <- promotergene[ind, ]

    ## train a support vector machine
    gene <- gausspr(Class~.,data=genetrain,kernel="rbfdot",
                    kpar=list(sigma=0.015))
    gene

    ## predict gene type probabilities on the test set
    genetype <- predict(gene,genetest,type="probabilities")
    genetype
}

test_37 <- function() {
    # create data
    x <- sort(runif(300))
    y <- sin(pi*x) + rnorm(300,0,sd=exp(sin(2*pi*x)))

    # first calculate the median
    qrm <- kqr(x, y, tau = 0.5, C=0.15)

    # predict and plot
    plot(x, y)
    ytest <- predict(qrm, x)
    lines(x, ytest, col="blue")

    # calculate 0.9 quantile
    qrm <- kqr(x, y, tau = 0.9, kernel = "rbfdot",
               kpar= list(sigma=10), C=0.15)
    ytest <- predict(qrm, x)
    lines(x, ytest, col="red")
}

test_38 <- function() {

    ## example using the promotergene data set
    data(promotergene)

    ## create test and training set
    ind <- sample(1:dim(promotergene)[1],20)
    genetrain <- promotergene[-ind, ]
    genetest <- promotergene[ind, ]

    ## train a support vector machine
    gene <- ksvm(Class~.,data=genetrain,kernel="rbfdot",
                 kpar=list(sigma=0.015),C=70,cross=4,prob.model=TRUE)
    gene

    ## predict gene type probabilities on the test set
    genetype <- predict(gene,genetest,type="probabilities")
    genetype
}

test_39 <- function() {
    data(promotergene)

    ## Create classification model using Gaussian Processes

    prom <- gausspr(Class~.,data=promotergene,kernel="rbfdot",
                    kpar=list(sigma=0.02),cross=4)
    prom

    ## Create model using Support Vector Machines

    promsv <- ksvm(Class~.,data=promotergene,kernel="laplacedot",
                   kpar="automatic",C=60,cross=4)
    promsv
}

test_40 <- function() {
    data(spirals)

    ## create data from spirals
    ran <- spirals[rowSums(abs(spirals) < 0.55) == 2,]

    ## rank points according to similarity to the most upper left point  
    ranked <- ranking(ran, 54, kernel = "rbfdot",
                      kpar = list(sigma = 100), edgegraph = TRUE)
    ranked[54, 2] <- max(ranked[-54, 2])
    c<-1:86
    op <- par(mfrow = c(1, 2),pty="s")
    plot(ran)
    plot(ran, cex=c[ranked[,3]]/40)
}

test_41 <- function() {
    data(spirals)

    ## create data set to be ranked
    ran<-spirals[rowSums(abs(spirals)<0.55)==2,]

    ## rank points according to "relevance" to point 54 (up left)
    ranked<-ranking(ran,54,kernel="rbfdot",
                    kpar=list(sigma=100),edgegraph=TRUE)

    ranked
    edgegraph(ranked)[1:10,1:10]
}

test_42 <- function() {
    # create data
    x <- seq(-20,20,0.1)
    y <- sin(x)/x + rnorm(401,sd=0.05)

    # train relevance vector machine
    foo <- rvm(x, y)
    foo
    # print relevance vectors
    alpha(foo)
    RVindex(foo)

    # predict and plot
    ytest <- predict(foo, x)
    plot(x, y, type ="l")
    lines(x, ytest, col="red")
}

test_43 <- function() {

    # create data
    x <- seq(-20,20,0.1)
    y <- sin(x)/x + rnorm(401,sd=0.05)

    # train relevance vector machine
    foo <- rvm(x, y)
    foo

    alpha(foo)
    RVindex(foo)
    fitted(foo)
    kernelf(foo)
    nvar(foo)

    ## show slots
    slotNames(foo)
}

test_44 <- function() {

    ## estimate good sigma values for promotergene
    data(promotergene)
    srange <- sigest(Class~.,data = promotergene)
    srange

    s <- srange[2]
    s
    ## create test and training set
    ind <- sample(1:dim(promotergene)[1],20)
    genetrain <- promotergene[-ind, ]
    genetest <- promotergene[ind, ]

    ## train a support vector machine
    gene <- ksvm(Class~.,data=genetrain,kernel="rbfdot",
                 kpar=list(sigma = s),C=50,cross=3)
    gene

    ## predict gene type on the test set
    promoter <- predict(gene,genetest[,-1])

    ## Check results
    table(promoter,genetest[,1])
}

test_45 <- function() {
    ## Cluster the spirals data set.
    data(spirals)

    sc <- specc(spirals, centers=2)

    sc
    centers(sc)
    size(sc)
    withinss(sc)

    plot(spirals, col=sc)
}

test_46 <- function() {
    ## Cluster the spirals data set.
    data(spirals)

    sc <- specc(spirals, centers=2)

    centers(sc)
    size(sc)
}

test_47 <- function() {
    data(spirals)
    plot(spirals)
}

test_48 <- function() {

    sk <- stringdot(type="string", length=5)

    sk
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

