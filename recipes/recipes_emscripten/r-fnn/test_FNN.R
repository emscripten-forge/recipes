library(FNN)
test_1 <- function() {
        set.seed(1000)
        X<- rexp(10000, rate=0.2)
        Y<- rexp(10000, rate=0.4)
    
        KL.dist(X, Y, k=5)                 
        KLx.dist(X, Y, k=5) 
        #thoretical distance = (0.2-0.4)^2/(0.2*0.4) = 0.5
}

test_2 <- function() {
        set.seed(1000)
        X<- rexp(10000, rate=0.2)
        Y<- rexp(10000, rate=0.4)

        KL.divergence(X, Y, k=5)
        #theoretical divergence = log(0.2/0.4)+(0.4/0.2)-1 = 1-log(2) = 0.307
}

test_3 <- function() {
      data<- query<- cbind(1:10, 1:10)

      get.knn(data, k=5)
      get.knnx(data, query, k=5)
      get.knnx(data, query, k=5, algo="kd_tree")

      th<- runif(10, min=0, max=2*pi)
      data2<-  cbind(cos(th), sin(th))
      get.knn(data2, k=5, algo="CR")
}

test_4 <- function() {
        data(iris3)
        train <- rbind(iris3[1:25,,1], iris3[1:25,,2], iris3[1:25,,3])
        test <- rbind(iris3[26:50,,1], iris3[26:50,,2], iris3[26:50,,3])
        cl <- factor(c(rep("s",25), rep("c",25), rep("v",25)))
        knn(train, test, cl, k = 3, prob=TRUE)
        attributes(.Last.value)
}

test_5 <- function() {
      data(iris3)
      train <- rbind(iris3[,,1], iris3[,,2], iris3[,,3])
      cl <- factor(c(rep("s",50), rep("c",50), rep("v",50)))
      knn.cv(train, cl, k = 3, prob = TRUE)
      attributes(.Last.value)
}

test_6 <- function() {
      if(require(mvtnorm))
      {
        sigma<- function(v, r, p)
        {
          	V<- matrix(r^2, ncol=p, nrow=p)
        	  diag(V)<- 1
            V*v
        }

        X<- rmvnorm(1000, mean=rep(0, 20), sigma(1, .5, 20))
        print(system.time(knn.dist(X)) )
        print(system.time(knn.dist(X, algorithm = "kd_tree")))

      }
}

test_7 <- function() {
      data<- query<- cbind(1:10, 1:10)

      knn.index(data, k=5)
      knnx.index(data, query, k=5)
      knnx.index(data, query, k=5, algo="kd_tree")
}

test_8 <- function() {
      if(require(chemometrics)){
        data(PAC);
        pac.knn<- knn.reg(PAC$X, y=PAC$y, k=3);
    
        plot(PAC$y, pac.knn$pred, xlab="y", ylab=expression(hat(y)))
      }
}

test_9 <- function() {
        data(iris3)
        train <- rbind(iris3[1:25,,1], iris3[1:25,,2], iris3[1:25,,3])
        test <- rbind(iris3[26:50,,1], iris3[26:50,,2], iris3[26:50,,3])
        cl <- factor(c(rep("s",25), rep("c",25), rep("v",25)))
        testcl <- factor(c(rep("s",25), rep("c",25), rep("v",25)))
        out <- ownn(train, test, cl, testcl)
        out
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

