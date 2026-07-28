print('Loading sensitivity package')
library(sensitivity)
print('... sensitivity package loaded successfully')

test_1 <- function() {

    # Model: Ishigami
  
    n = 100
    X = matrix(runif(3*n, -pi, pi), ncol = 3)
  
    y = ishigami.fun(X)
	
    # Test the significance of X1, H0: S1 = 0
    EPtest(X[, 1], y, u = NULL)

    # Test if X1 is sufficient to explain Y, H0: S1 = S123
    EPtest(X, y, u = 1)
  
    # Test if X3 is significant in presence of X2, H0: S2 = S23
    EPtest(X[, 2:3], y, u = 1)
}

test_2 <- function() {


    # Model: Ishigami function with a treshold at -7
    # Failure points are those < -7

      distributionIshigami = list()
    	for (i in 1:3){
    		distributionIshigami[[i]]=list("unif",c(-pi,pi))
    		distributionIshigami[[i]]$r=("runif")
    	}
  
    # Monte Carlo sampling to obtain failure points

      N = 100000
    	X = matrix(0,ncol=3,nrow=N)
    	for( i in 1:3) X[,i] = runif(N,-pi,pi)
    	T = ishigami.fun(X)
    	s = sum(as.numeric(T < -7)) # Number of failure
    	pdefchap = s/N      # Failure probability
    	ptsdef = X[T < -7,]	# Failure points
	
    # sensitivity indices with perturbation of the mean 
  
    	v_delta = seq(-3,3,1/20) 
    	Toto = PLI(failurepoints=ptsdef,failureprobabilityhat=pdefchap,samplesize=N,
    		deltasvector=v_delta,InputDistributions=distributionIshigami,type="MOY",
    		samedelta=TRUE)
    	BIshm = Toto[[1]]
    	SIshm = Toto[[2]]

    	par(mfrow=c(1,1),mar=c(4,5,1,1))
    	plot(v_delta,BIshm[,2],ylim=c(-4,4),xlab=expression(delta),
    		ylab=expression(hat(PLI[i*delta])),pch=19,cex=1.5)
    	points(v_delta,BIshm[,1],col="darkgreen",pch=15,cex=1.5)
    	points(v_delta,BIshm[,3],col="red",pch=17,cex=1.5)
    	lines(v_delta,BIshm[,2]+1.96*SIshm[,2],col="black")
    	lines(v_delta,BIshm[,2]-1.96*SIshm[,2],col="black")
    	lines(v_delta,BIshm[,1]+1.96*SIshm[,1],col="darkgreen")
    	lines(v_delta,BIshm[,1]-1.96*SIshm[,1],col="darkgreen")
    	lines(v_delta,BIshm[,3]+1.96*SIshm[,3],col="red")
    	lines(v_delta,BIshm[,3]-1.96*SIshm[,3],col="red")
    	abline(h=0,lty=2)
    	legend(0,3,legend=c("X1","X2","X3"),
    		col=c("darkgreen","black","red"),pch=c(15,19,17),cex=1.5)
  
    # sensitivity indices with perturbation of the variance 

    	v_delta = seq(1,5,1/4) # user parameter. (the true variance is 3.29)	
    	Toto = PLI(failurepoints=ptsdef,failureprobabilityhat=pdefchap,samplesize=N,
    		deltasvector=v_delta,InputDistributions=distributionIshigami,type="VAR",
    		samedelta=TRUE)
    	BIshv=Toto[[1]]
    	SIshv=Toto[[2]]

    	par(mfrow=c(2,1),mar=c(1,5,1,1)+0.1)
    	plot(v_delta,BIshv[,2],ylim=c(-.5,.5),xlab=expression(V_f),
    		ylab=expression(hat(PLI[i*delta])),pch=19,cex=1.5)
    	points(v_delta,BIshv[,1],col="darkgreen",pch=15,cex=1.5)
    	points(v_delta,BIshv[,3],col="red",pch=17,cex=1.5)
    	lines(v_delta,BIshv[,2]+1.96*SIshv[,2],col="black")
    	lines(v_delta,BIshv[,2]-1.96*SIshv[,2],col="black")
    	lines(v_delta,BIshv[,1]+1.96*SIshv[,1],col="darkgreen")
    	lines(v_delta,BIshv[,1]-1.96*SIshv[,1],col="darkgreen")
    	lines(v_delta,BIshv[,3]+1.96*SIshv[,3],col="red")
    	lines(v_delta,BIshv[,3]-1.96*SIshv[,3],col="red")

    	par(mar=c(4,5.1,1.1,1.1))
    	plot(v_delta,BIshv[,2],ylim=c(-30,.7),xlab=expression(V[f]),
    		ylab=expression(hat(PLI[i*delta])),pch=19,cex=1.5)
    	points(v_delta,BIshv[,1],col="darkgreen",pch=15,cex=1.5)
    	points(v_delta,BIshv[,3],col="red",pch=17,cex=1.5)
    	lines(v_delta,BIshv[,2]+1.96*SIshv[,2],col="black")
    	lines(v_delta,BIshv[,2]-1.96*SIshv[,2],col="black")
    	lines(v_delta,BIshv[,1]+1.96*SIshv[,1],col="darkgreen")
    	lines(v_delta,BIshv[,1]-1.96*SIshv[,1],col="darkgreen")
    	lines(v_delta,BIshv[,3]+1.96*SIshv[,3],col="red")
    	lines(v_delta,BIshv[,3]-1.96*SIshv[,3],col="red")
    	legend(2.5,-10,legend=c("X1","X2","X3"),col=c("darkgreen","black","red"),
    		pch=c(15,19,17),cex=1.5)
  
    ##############################################################
    # Example with an inverse probability transform 
    # (to obtain Gaussian inputs from Uniform ones)

    # Monte Carlo sampling (the inputs are Uniform)

      N = 100000
    	X = matrix(0,ncol=3,nrow=N)
    	for( i in 1:3) X[,i] = runif(N,-pi,pi)
    	T = ishigami.fun(X)
    	s = sum(as.numeric(T < -7)) # Number of failure
    	pdefchap = s/N      # Failure probability
	
    # Empirical transform (applied on the sample)

      Xn <- matrix(0,nrow=N,ncol=3)
      for (i in 1:3){
        ecdfx <- ecdf(X[,i])
        q <- ecdfx(X[,i])
        Xn[,i] <- qnorm(q) # Gaussian anamorphosis
        # infinite max values => putting the symetrical values of min values
        Xn[which(Xn[,i]==Inf),i] <- - Xn[which.min(Xn[,i]),i] 
        }
    # Visualization of a perturbed density (the one of X1 perturbed on the mean)
      delta_mean_gauss <- 1 # perturbed value on the mean of the Gaussian transform
      Xtr <- quantile(ecdfx,pnorm(Xn[,1] + delta_mean_gauss)) # backtransform
    	par(mfrow=c(1,1))
      plot(density(Xtr), col="red") ; lines(density(X[,1]))
  
    # sensitivity indices with perturbation of the mean 
  
      distributionIshigami = list()
    	for (i in 1:3){
    		distributionIshigami[[i]]=list("norm",c(0,1))
    		distributionIshigami[[i]]$r=("rnorm")
    	}
	
    	ptsdef = Xn[T < -7,]	# Failure points # failure points with Gaussian distrib.
	
    	v_delta = seq(-1.5,1.5,1/20) 
    	Toto = PLI(failurepoints=ptsdef,failureprobabilityhat=pdefchap,samplesize=N,
    		deltasvector=v_delta,InputDistributions=distributionIshigami,type="MOY",
    		samedelta=TRUE)
    	BIshm = Toto[[1]]
    	SIshm = Toto[[2]]

    	par(mfrow=c(1,1),mar=c(4,5,1,1))
    	plot(v_delta,BIshm[,2],ylim=c(-4,4),xlab=expression(delta),
    		ylab=expression(hat(PLI[i*delta])),pch=19,cex=1.5)
    	points(v_delta,BIshm[,1],col="darkgreen",pch=15,cex=1.5)
    	points(v_delta,BIshm[,3],col="red",pch=17,cex=1.5)
    	lines(v_delta,BIshm[,2]+1.96*SIshm[,2],col="black")
    	lines(v_delta,BIshm[,2]-1.96*SIshm[,2],col="black")
    	lines(v_delta,BIshm[,1]+1.96*SIshm[,1],col="darkgreen")
    	lines(v_delta,BIshm[,1]-1.96*SIshm[,1],col="darkgreen")
    	lines(v_delta,BIshm[,3]+1.96*SIshm[,3],col="red")
    	lines(v_delta,BIshm[,3]-1.96*SIshm[,3],col="red")
    	abline(h=0,lty=2)
    	legend(0,3,legend=c("X1","X2","X3"),
    		col=c("darkgreen","black","red"),pch=c(15,19,17),cex=1.5)
}


print("Running test_1")
test_1()

print("Running test_2")
test_2()