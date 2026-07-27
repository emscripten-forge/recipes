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

test_3 <- function() {


    # Model: 3D function 

      distribution = list()
    	for (i in 1:3) distribution[[i]]=list("norm",c(0,1))
  
    # Monte Carlo sampling 

      N = 5000
    	X = matrix(0,ncol=3,nrow=N)
    	for(i in 1:3) X[,i] = rnorm(N,0,1)
     
    	Y = 2 * X[,1] + X[,2] + X[,3]/2
    	alpha <- 0.95 # quantile order
	
    	q95 = quantile(Y,alpha)
	
    	nboot=20 # put nboot=200 for consistency
	
    # sensitivity indices with perturbation of the mean 
  
    	v_delta = seq(-1,1,1/10) 
    	toto = PLIquantile(alpha,X,Y,deltasvector=v_delta,
    	  InputDistributions=distribution,type="MOY",samedelta=TRUE,
    	  percentage=FALSE,nboot=nboot)

    # Plotting the PLI

      par(mar=c(4,5,1,1))
    	plot(v_delta,toto$PLI[,2],ylim=c(-1.5,1.5),xlab=expression(delta),
    		ylab=expression(hat(PLI[i*delta])),pch=19,cex=1.5)
    	points(v_delta,toto$PLI[,1],col="darkgreen",pch=15,cex=1.5)
    	points(v_delta,toto$PLI[,3],col="red",pch=17,cex=1.5)
    	lines(v_delta,toto$PLICIinf[,2],col="black")
    	lines(v_delta,toto$PLICIsup[,2],col="black")
    	lines(v_delta,toto$PLICIinf[,1],col="darkgreen")
    	lines(v_delta,toto$PLICIsup[,1],col="darkgreen")
    	lines(v_delta,toto$PLICIinf[,3],col="red")
    	lines(v_delta,toto$PLICIsup[,3],col="red")
    	abline(h=0,lty=2)
    	legend(0.8,1.5,legend=c("X1","X2","X3"),
    		col=c("darkgreen","black","red"),pch=c(15,19,17),cex=1.5)
  
    # Plotting the perturbed quantiles

      par(mar=c(4,5,1,1))
    	plot(v_delta,toto$quantile[,2],ylim=c(1.5,6.5),xlab=expression(delta),
    		ylab=expression(hat(q[i*delta])),pch=19,cex=1.5)
    	points(v_delta,toto$quantile[,1],col="darkgreen",pch=15,cex=1.5)
    	points(v_delta,toto$quantile[,3],col="red",pch=17,cex=1.5)
    	lines(v_delta,toto$quantileCIinf[,2],col="black")
    	lines(v_delta,toto$quantileCIsup[,2],col="black")
    	lines(v_delta,toto$quantileCIinf[,1],col="darkgreen")
    	lines(v_delta,toto$quantileCIsup[,1],col="darkgreen")
    	lines(v_delta,toto$quantileCIinf[,3],col="red")
    	lines(v_delta,toto$quantileCIsup[,3],col="red")
    	abline(h=q95,lty=2)
    	legend(0.5,2.4,legend=c("X1","X2","X3"),
    		col=c("darkgreen","black","red"),pch=c(15,19,17),cex=1.5)
		
    ###########################################################		
    # Plotting the PLI in percentage with refined confidence intervals

    	toto = PLIquantile(alpha,X,Y,deltasvector=v_delta,
    	  InputDistributions=distribution,type="MOY",samedelta=TRUE,
    	  percentage=TRUE,nboot=nboot,bootsample=FALSE)
	  
      par(mar=c(4,5,1,1))
    	plot(v_delta,toto$PLI[,2],ylim=c(-0.6,0.6),xlab=expression(delta),
    		ylab=expression(hat(PLI[i*delta])),pch=19,cex=1.5)
    	points(v_delta,toto$PLI[,1],col="darkgreen",pch=15,cex=1.5)
    	points(v_delta,toto$PLI[,3],col="red",pch=17,cex=1.5)
    	lines(v_delta,toto$PLICIinf[,2],col="black")
    	lines(v_delta,toto$PLICIsup[,2],col="black")
    	lines(v_delta,toto$PLICIinf[,1],col="darkgreen")
    	lines(v_delta,toto$PLICIsup[,1],col="darkgreen")
    	lines(v_delta,toto$PLICIinf[,3],col="red")
    	lines(v_delta,toto$PLICIsup[,3],col="red")
    	abline(h=0,lty=2)
    	legend(0,0.6,legend=c("X1","X2","X3"),
    		col=c("darkgreen","black","red"),pch=c(15,19,17),cex=1.5)

    ###################################################		
    # another visualization by using the plotCI() fct 
    # (from plotrix package) for the CI plotting(from Vanessa Verges)

      library(plotrix)
      parameters = list(colors=c("darkgreen","black","red"),
                      symbols=c(15,19,17),overlay=c(FALSE,TRUE,TRUE))
      par(mar=c(4,5,1,1),xpd=TRUE)
      for (i in 1:3){
        plotCI(v_delta,toto$PLI[,i],ui=toto$PLICIsup[,i],li=toto$PLICIinf[,i],
             cex=1.5,col=parameters$colors[i],pch=parameters$symbols[i],
             add=parameters$overlay[i], xlab="", ylab="")
      }
      title(xlab=expression(delta),ylab=expression(hat(PLI[i*delta])),
           main=bquote("PLI-quantile (N ="~.(N) ~ ","~alpha~"="~.(alpha)~
           ") of Y="~2*X[1] + X[2] + X[3]/2))
      abline(h=0,lty=2)
      legend("topleft",legend=c("X1","X2","X3"),col=parameters$colors,
              pch=parameters$symbols,cex=1.5)
}

test_4 <- function() {


    # Model: 3D function 

    distribution = list()
    for (i in 1:3) distribution[[i]]=list("norm",c(0,1))
    N = 5000
    X = matrix(0,ncol=3,nrow=N)
    for(i in 1:3) X[,i] = rnorm(N,0,1)
    Y = 2 * X[,1] + X[,2] + X[,3]/2
    alpha <- 0.95
    nboot <- 20 # put nboot=200 for consistency

    q95 = quantile(Y,alpha)
    v_delta = seq(-1,1,1/10) 
    toto12 = PLIquantile_multivar(alpha,X,Y,c(1,2),deltasvector=v_delta,
        InputDistributions=distribution,samedelta=TRUE)
    toto = PLIquantile(alpha,X,Y,deltasvector=v_delta,InputDistributions=distribution,
        type="MOY",samedelta=TRUE,nboot=0)

    par(mar=c(4,5,1,1))
    plot(v_delta,diag(toto12$PLI),,ylim=c(-1,1),xlab=expression(delta),
        ylab=expression(hat(PLI[i*delta])),pch=16,cex=1.5,col="blue")
    points(v_delta,toto$PLI[,1],col="darkgreen",pch=15,cex=1.5)
    points(v_delta,toto$PLI[,2],col="black",pch=19,cex=1.5)
    points(v_delta,toto$PLI[,3],col="red",pch=17,cex=1.5)
    abline(h=0,lty=2)
    legend(-1,1.,legend=c("X1","X2","X3","X1X2"),col=c("darkgreen","black","red","blue"),
        pch=c(15,19,17,16),cex=1.5)

    # with bootstrap

    v_delta = seq(-1,1,2/10) 

    toto12 = PLIquantile_multivar(alpha,X,Y,c(1,2),deltasvector=v_delta,
        InputDistributions=distribution,samedelta=TRUE,nboot=nboot,bootsample=FALSE)
    toto = PLIquantile(alpha,X,Y,deltasvector=v_delta,InputDistributions=distribution,
        type="MOY",samedelta=TRUE,nboot=nboot,bootsample=FALSE)

    par(mar=c(4,5,1,1))
    plot(v_delta,diag(toto12$PLI),ylim=c(-1,1),xlab=expression(delta),
        ylab=expression(hat(PLI[i*delta])),pch=16,cex=1.5,col="blue")
    points(v_delta,toto$PLI[,1],col="darkgreen",pch=15,cex=1.5)
    points(v_delta,toto$PLI[,2],col="black",pch=19,cex=1.5)
    points(v_delta,toto$PLI[,3],col="red",pch=17,cex=1.5)
    lines(v_delta,diag(toto12$PLICIinf),col="blue")
    lines(v_delta,diag(toto12$PLICIsup),col="blue")
    lines(v_delta,toto$PLICIinf[,2],col="black")
    lines(v_delta,toto$PLICIsup[,2],col="black")
    lines(v_delta,toto$PLICIinf[,1],col="darkgreen")
    lines(v_delta,toto$PLICIsup[,1],col="darkgreen")
    lines(v_delta,toto$PLICIinf[,3],col="red")
    lines(v_delta,toto$PLICIsup[,3],col="red")
    abline(h=0,lty=2)
    legend(-1,1,legend=c("X1","X2","X3","X1X2"),col=c("darkgreen","black","red","blue"),
        pch=c(15,19,17,16),cex=1.5)

    ###################################################		
    # another visualizations by using the plotrix, 
    # viridisLite, lattice and grid packages (from Vanessa Verges)

    library(plotrix)

    parameters = list(colors=c("darkgreen","black","red"),symbols=c(15,19,17))
    par(mar=c(4,5,1,1),xpd=TRUE)
    plotCI(v_delta,diag(toto12$PLI),ui=diag(toto12$PLICIsup),li=diag(toto12$PLICIinf),
           xlab=expression(delta),ylab=expression(hat(PLI[i*delta])),
           main=bquote("PLI-quantile (N ="~.(N) ~ ","~alpha~"="~.(alpha)~
           ") on "~X[1]~"and"~X[2]~"of Y="~2*X[1] + X[2] + X[3]/2),
           cex=1.5,col="blue",pch=16)
    for (i in 1:3){
      plotCI(v_delta,toto$PLI[,i],ui=toto$PLICIsup[,i],li=toto$PLICIinf[,i],
             cex=1.5,col=parameters$colors[i],pch=parameters$symbols[i],
             add=TRUE)
    }
    abline(h=0,lty=2)
    legend("topleft",legend=c("X1","X2","X3","X1X2"),
            col=c(parameters$colors,"blue"),pch=c(parameters$symbols,16),cex=1.5)

    # Visu of all the PLIs (at any paired combinations of deltas)

    library(viridisLite)
    library(lattice)
    library(grid)

    colnames(toto12$PLI) = round(v_delta,2)
    rownames(toto12$PLI) = round(v_delta,2)
    coul = viridis(100)
    levelplot(toto12$PLI, col.regions = coul, xlab=bquote(delta[X~.(1)]), 
      ylab=bquote(delta[X~.(2)]), main=bquote(hat(PLI)[quantile[~X[1]~X[2]]]))
}

test_5 <- function() {


    # Model: 3D function 

      distribution = list()
    	for (i in 1:3) distribution[[i]]=list("norm",c(0,1))
  
    # Monte Carlo sampling 

      N = 10000
    	X = matrix(0,ncol=3,nrow=N)
    	for(i in 1:3) X[,i] = rnorm(N,0,1)
     
    	Y = 2 * X[,1] + X[,2] + X[,3]/2
    	alpha <- 0.95
	
    	q95 = quantile(Y,alpha)
      sq95a <- mean(Y*(Y>q95)/(1-alpha)) ; sq95b <- mean(Y[Y>q95])
	
    	nboot=20 # change to nboot=200 for consistency
	
    # sensitivity indices with perturbation of the mean 
  
    	v_delta = seq(-1,1,1/10) 
    	toto = PLIsuperquantile(alpha,X,Y,deltasvector=v_delta,
    	  InputDistributions=distribution,type="MOY",samedelta=TRUE,
    	  percentage=FALSE,nboot=nboot,bias=TRUE)

    # Plotting the PLI
      par(mar=c(4,5,1,1))
    	plot(v_delta,toto$PLI[,2],ylim=c(-0.5,0.5),xlab=expression(delta),
    		ylab=expression(hat(PLI[i*delta])),pch=19,cex=1.5)
    	points(v_delta,toto$PLI[,1],col="darkgreen",pch=15,cex=1.5)
    	points(v_delta,toto$PLI[,3],col="red",pch=17,cex=1.5)
    	lines(v_delta,toto$PLICIinf[,2],col="black")
    	lines(v_delta,toto$PLICIsup[,2],col="black")
    	lines(v_delta,toto$PLICIinf[,1],col="darkgreen")
    	lines(v_delta,toto$PLICIsup[,1],col="darkgreen")
    	lines(v_delta,toto$PLICIinf[,3],col="red")
    	lines(v_delta,toto$PLICIsup[,3],col="red")
    	abline(h=0,lty=2)
    	legend(-1,0.5,legend=c("X1","X2","X3"),
    		col=c("darkgreen","black","red"),pch=c(15,19,17),cex=1.5)
  
    # Plotting the perturbed superquantiles
      par(mar=c(4,5,1,1))
    	plot(v_delta,toto$superquantile[,2],ylim=c(3,7),xlab=expression(delta),
    		ylab=expression(hat(q[i*delta])),pch=19,cex=1.5)
    	points(v_delta,toto$superquantile[,1],col="darkgreen",pch=15,cex=1.5)
    	points(v_delta,toto$superquantile[,3],col="red",pch=17,cex=1.5)
    	lines(v_delta,toto$superquantileCIinf[,2],col="black")
    	lines(v_delta,toto$superquantileCIsup[,2],col="black")
    	lines(v_delta,toto$superquantileCIinf[,1],col="darkgreen")
    	lines(v_delta,toto$superquantileCIsup[,1],col="darkgreen")
    	lines(v_delta,toto$superquantileCIinf[,3],col="red")
    	lines(v_delta,toto$superquantileCIsup[,3],col="red")
    	abline(h=q95,lty=2)
    	legend(-1,7,legend=c("X1","X2","X3"),
    		col=c("darkgreen","black","red"),pch=c(15,19,17),cex=1.5)
		
    # Plotting the unbiased PLI in percentage with refined confidence intervals
    	toto = PLIsuperquantile(alpha,X,Y,deltasvector=v_delta,
    	  InputDistributions=distribution,type="MOY",samedelta=TRUE,percentage=TRUE,
    	  nboot=nboot,bootsample=FALSE,bias=FALSE)
	  
      par(mar=c(4,5,1,1))
    	plot(v_delta,toto$PLI[,2],ylim=c(-0.4,0.5),xlab=expression(delta),
    		ylab=expression(hat(PLI[i*delta])),pch=19,cex=1.5)
    	points(v_delta,toto$PLI[,1],col="darkgreen",pch=15,cex=1.5)
    	points(v_delta,toto$PLI[,3],col="red",pch=17,cex=1.5)
    	lines(v_delta,toto$PLICIinf[,2],col="black")
    	lines(v_delta,toto$PLICIsup[,2],col="black")
    	lines(v_delta,toto$PLICIinf[,1],col="darkgreen")
    	lines(v_delta,toto$PLICIsup[,1],col="darkgreen") 
    	lines(v_delta,toto$PLICIinf[,3],col="red")
    	lines(v_delta,toto$PLICIsup[,3],col="red")
    	abline(h=0,lty=2)
    	legend(-1,0.5,legend=c("X1","X2","X3"),
    		col=c("darkgreen","black","red"),pch=c(15,19,17),cex=1.5)

    ##################################################
    # another visualization by using the plotCI() fct 
    # (from plotrix package) for the CI plotting (from Vanessa Verges)

    	library(plotrix)
    	parameters = list(colors=c("darkgreen","black","red"),symbols=c(15,19,17),
    	  overlay=c(FALSE,TRUE,TRUE))
      par(mar=c(4,5,1,1),xpd=TRUE)
      for (i in 1:3){
      plotCI(v_delta,toto$PLI[,i],ui=toto$PLICIsup[,i],li=toto$PLICIinf[,i],
             cex=1.5,col=parameters$colors[i],pch=parameters$symbols[i],
             add=parameters$overlay[i], xlab="", ylab="")
      }
      title(xlab=expression(delta),ylab=expression(hat(PLI[i*delta])),
          main=bquote("PLI-superquantile (N ="~.(N) ~ ","~alpha~"="~.(alpha)~
          ") of Y="~2*X[1] + X[2] + X[3]/2))
      abline(h=0,lty=2)
      legend("topleft",legend=c("X1","X2","X3"),
              col=parameters$colors,pch=parameters$symbols,cex=1.5)
}

test_6 <- function() {


    # Model: 3D function 

    distribution = list()
    for (i in 1:3) distribution[[i]]=list("norm",c(0,1))
    N = 10000
    X = matrix(0,ncol=3,nrow=N)
    for(i in 1:3) X[,i] = rnorm(N,0,1)
    Y = 2 * X[,1] + X[,2] + X[,3]/2
    alpha <- 0.95
    nboot <- 20 # put nboot=200 for consistency

    q95 = quantile(Y,alpha)
    sq95a <- mean(Y*(Y>q95)/(1-alpha)) ; sq95b <- mean(Y[Y>q95])
  
    v_delta = seq(-1,1,1/10) 
    toto12 = PLIsuperquantile_multivar(alpha,X,Y,c(1,2),deltasvector=v_delta,
        InputDistributions=distribution,samedelta=TRUE,bias=FALSE)
    toto = PLIsuperquantile(alpha,X,Y,deltasvector=v_delta,InputDistributions=distribution,
        type="MOY",samedelta=TRUE,nboot=0,bias=FALSE)

    par(mar=c(4,5,1,1))
    plot(v_delta,diag(toto12$PLI),,ylim=c(-1,1),xlab=expression(delta),
        ylab=expression(hat(PLI[i*delta])),pch=16,cex=1.5,col="blue")
    points(v_delta,toto$PLI[,1],col="darkgreen",pch=15,cex=1.5)
    points(v_delta,toto$PLI[,2],col="black",pch=19,cex=1.5)
    points(v_delta,toto$PLI[,3],col="red",pch=17,cex=1.5)
    abline(h=0,lty=2)
    legend(-1,1.,legend=c("X1","X2","X3","X1X2"),col=c("darkgreen","black","red","blue"),
        pch=c(15,19,17,16),cex=1.5)

    # with bootstrap (put in comment because too long for the CRAN tests)

    v_delta = seq(-1,1,2/10) 

    toto12 = PLIsuperquantile_multivar(alpha,X,Y,c(1,2),deltasvector=v_delta,
        InputDistributions=distribution,samedelta=TRUE,nboot=nboot,bootsample=FALSE,bias=FALSE)
    toto = PLIsuperquantile(alpha,X,Y,deltasvector=v_delta,InputDistributions=distribution,
        type="MOY",samedelta=TRUE,nboot=nboot,bootsample=FALSE,bias=FALSE)

    par(mar=c(4,5,1,1))
    plot(v_delta,diag(toto12$PLI),ylim=c(-1,1),xlab=expression(delta),
        ylab=expression(hat(PLI[i*delta])),pch=16,cex=1.5,col="blue")
    points(v_delta,toto$PLI[,1],col="darkgreen",pch=15,cex=1.5)
    points(v_delta,toto$PLI[,2],col="black",pch=19,cex=1.5)
    points(v_delta,toto$PLI[,3],col="red",pch=17,cex=1.5)
    lines(v_delta,diag(toto12$PLICIinf),col="blue")
    lines(v_delta,diag(toto12$PLICIsup),col="blue")
    lines(v_delta,toto$PLICIinf[,2],col="black")
    lines(v_delta,toto$PLICIsup[,2],col="black")
    lines(v_delta,toto$PLICIinf[,1],col="darkgreen")
    lines(v_delta,toto$PLICIsup[,1],col="darkgreen")
    lines(v_delta,toto$PLICIinf[,3],col="red")
    lines(v_delta,toto$PLICIsup[,3],col="red")
    abline(h=0,lty=2)
    legend(-1,1,legend=c("X1","X2","X3","X1X2"),col=c("darkgreen","black","red","blue"),
        pch=c(15,19,17,16),cex=1.5)

    ###################################################		
    # another visualizations by using the plotrix, 
    # viridisLite, lattice and grid packages (from Vanessa Verges)

    library(plotrix)
    parameters = list(colors=c("darkgreen","black","red"),symbols=c(15,19,17))
    par(mar=c(4,5,1,1),xpd=TRUE)
    plotCI(v_delta,diag(toto12$PLI),ui=diag(toto12$PLICIsup),li=diag(toto12$PLICIinf),
           xlab=expression(delta),ylab=expression(hat(PLI[i*delta])),
           main=bquote("PLI-superquantile (N ="~.(N) ~ ","~alpha~"="~.(alpha)~
           ") on "~X[1]~"and"~X[2]~"of Y="~2*X[1] + X[2] + X[3]/2),
           cex=1.5,col="blue",pch=16)
    for (i in 1:3){
      plotCI(v_delta,toto$PLI[,i],ui=toto$PLICIsup[,i],li=toto$PLICIinf[,i],
             cex=1.5,col=parameters$colors[i],pch=parameters$symbols[i],
             add=TRUE)
    }
    abline(h=0,lty=2)
    legend("topleft",legend=c("X1","X2","X3","X1X2"),
            col=c(parameters$colors,"blue"),pch=c(parameters$symbols,16),cex=1.5)

    # Visu of all the PLIs (at any paired combinations of deltas)

    library(viridisLite)
    library(lattice)
    library(grid)

    colnames(toto12$PLI) = round(v_delta,2)
    rownames(toto12$PLI) = round(v_delta,2)
    coul = viridis(100)
    levelplot(toto12$PLI,col.regions=coul,main=bquote(hat(PLI)[superquantile[~X[1]~X[2]]]),
              xlab=bquote(delta[X~.(1)]),ylab=bquote(delta[X~.(2)]))
}

test_7 <- function() {

    # A simple example

    g <- function(x, a){
      res <- x[, 1] + a*x[, 1]*x[, 2]
      attr(res, "grad") <- cbind(1 + a * x[, 2], a * x[, 1])
      return(res)
    }

    n <- 1e3
    set.seed(0)
    X <- matrix(runif(2*n, min = -1/2, max = 1/2), nrow = n, ncol = 2)
    a <- 3
    fX <- g(X, a = a)

    out_1 <- out_2 <- PoincareOptimal(distr = list("unif", -1/2, 1/2), 
                                      only.values = FALSE, der = TRUE, 
                                      method = "quad")
    out <- list(out_1, out_2)

    # Lower bounds for X1
    c2_10 <- PoincareChaosSqCoef(PoincareEigen = out, multiIndex = c(1, 0), 
                                 design = X, output = fX, outputGrad = attr(fX, "grad"), 
                                 inputIndex = 1, der = FALSE)
    c2_11 <- PoincareChaosSqCoef(PoincareEigen = out, multiIndex = c(1, 1), 
                                 design = X, output = fX, outputGrad = attr(fX, "grad"), 
                                 inputIndex = 1, der = FALSE)
    c2_10_der <- PoincareChaosSqCoef(PoincareEigen = out, multiIndex = c(1, 0), 
                                     design = X, output = fX, outputGrad = attr(fX, "grad"), 
                                     inputIndex = 1, der = TRUE)
    c2_11_der <- PoincareChaosSqCoef(PoincareEigen = out, multiIndex = c(1, 1), 
                                     design = X, output = fX, outputGrad = attr(fX, "grad"), 
                                     inputIndex = 1, der = TRUE)

    LB1 <- c(8/pi^4, c2_10, c2_10_der)
    LB1tot <- LB1 + c(64/pi^8 * a^2, c2_11, c2_11_der)
    LB <- cbind(LB1, LB1tot)
    rownames(LB) <- c("True lower bound value", 
                      "Estimated, no derivatives", "Estimated, with derivatives")
    colnames(LB) <- c("D1", "D1tot")
    cat("True values of D1 and D1tot:", c(1/12, 1/12 + a^2 / 144),"\n")
    cat("Sample size: ", n, "\n")
    cat("Lower bounds computed with the first Poincare eigenvalue:\n")
    print(LB)
    cat("\nN.B. Increase the sample size to see the convergence to true lower bound values.\n")

    ############################################################
    # Flood model example (see Roustant et al., 2017, 2019)



    library(evd) # Gumbel law
    library(triangle) # Triangular law

    # Flood model
    Fcrues_full2=function(X,ans=0){ 
      # ans=1 gives Overflow output; ans=2 gives Cost output; ans=0 gives both
      mat=matrix(X,ncol=8);
      if (ans==0){ reponse=matrix(NA,nrow(mat),2);}
      else{ reponse=rep(NA,nrow(mat));}
      for (i in 1:nrow(mat)) {
        H = (mat[i,1] / (mat[i,2]*mat[i,8]*sqrt((mat[i,4] - mat[i,3])/mat[i,7])))^(0.6) ;
        S = mat[i,3] + H - mat[i,5] - mat[i,6] ;
        if (S > 0){ Cp = 1 ;}
        else{ Cp = 0.2 + 0.8 * (1 - exp(-1000 / S^4));}
        if (mat[i,5]>8){ Cp = Cp + mat[i,5]/20 ;}
        else{ Cp = Cp + 8/20 ;}
        if (ans==0){
          reponse[i,1] = S ;
          reponse[i,2] = Cp ;
        }
        if (ans==1){ reponse[i] = S ;}
        if (ans==2){ reponse[i] = Cp ;}
    
      }
      return(RES=reponse)
    }

    # Flood model derivatives (by finite-differences)
    dFcrues_full2 <- function(X, i, ans, eps){
      der = X
      X1 = X
      X1[,i] = X[,i]+eps
      der = (Fcrues_full2(X1,ans) - Fcrues_full2(X,ans))/(eps)
      return(der)
    }

    # Function for flood model inputs sampling
    EchantFcrues_full2<-function(taille){
      X = matrix(NA,taille,8)
      X[,1] = rgumbel.trunc(taille,loc=1013.0,scale=558.0,min=500,max=3000)
      X[,2] = rnorm.trunc(taille,mean=30.0,sd=8,min=15.)
      X[,3] = rtriangle(taille,a=49,b=51,c=50)
      X[,4] = rtriangle(taille,a=54,b=56,c=55)
      X[,5] = runif(taille,min=7,max=9)
      X[,6] = rtriangle(taille,a=55,b=56,c=55.5)
      X[,7] = rtriangle(taille,a=4990,b=5010,c=5000)
      X[,8] = rtriangle(taille,a=295,b=305,c=300)
      return(X)
    }

    d <- 8
    n <- 1e3
    eps <- 1e-7 # finite-differences for derivatives
    x <- EchantFcrues_full2(n)
    yy <- Fcrues_full2(x, ans=2)
    y <- scale(yy, center = TRUE, scale = FALSE)[,1]
    dy <- NULL
    for (i in 1:d) dy <- cbind(dy, dFcrues_full2(x, i, ans=2, eps))

    method <- "quad"
    out_1 <- PoincareOptimal(distr = list("gumbel", 1013, 558), min=500,max=3000, 
                             only.values = FALSE, der = TRUE, method = method)
    out_2 <- PoincareOptimal(distr = list("norm", 30, 8), min=15, max=200, 
                             only.values = FALSE, der = TRUE, method = method)
    out_3 <- PoincareOptimal(distr = list("triangle", 49, 51, 50), 
                             only.values = FALSE, der = TRUE, method = method)
    out_4 <- PoincareOptimal(distr = list("triangle", 54, 56, 55), 
                             only.values = FALSE, der = TRUE, method = method)
    out_5 <- PoincareOptimal(distr = list("unif", 7, 9), 
                             only.values = FALSE, der = TRUE, method = method)
    out_6 <- PoincareOptimal(distr = list("triangle", 55, 56, 55.5), 
                             only.values = FALSE, der = TRUE, method = method)
    out_7 <- PoincareOptimal(distr = list("triangle", 4990, 5010, 5000), 
                             only.values = FALSE, der = TRUE, method = method)
    out_8 <- PoincareOptimal(distr = list("triangle", 295, 305, 300), 
                             only.values = FALSE, der = TRUE, method = method)
    out_ <- list(out_1,out_2,out_3,out_4,out_5,out_6,out_7,out_8)

    c2 <- c2der <- c2tot <- c2totder <- rep(0,d)

    for (i in 1:d){
      m <- diag(1,d,d) ; m[,i] <- 1
  
      for (j in 1:d){
        cc <- PoincareChaosSqCoef(PoincareEigen = out_, multiIndex = m[j,], 
                design = x, output = y, outputGrad = NULL, 
                inputIndex = i, der = FALSE)
        c2tot[i] <- c2tot[i] + cc
        if (j == i) c2[i] <- cc
    
        cc <- PoincareChaosSqCoef(PoincareEigen = out_, multiIndex = m[j,], 
                design = x, output = y, outputGrad = dy, 
                inputIndex = i, der = TRUE)
        c2totder[i] <- c2totder[i] + cc
        if (j == i) c2der[i] <- cc
      }
    }

    print("Lower bounds of first-order Sobol' indices without derivatives:")
    print(c2/var(y))
    print("Lower bounds of first-order Sobol' indices with derivatives:")
    print(c2der/var(y))

    print("Lower bounds of total Sobol' indices without derivatives:")
    print(c2tot/var(y))
    print("Lower bounds of total Sobol' indices with derivatives:")
    print(c2totder/var(y))
}

test_8 <- function() {

    # Exponential law (log-concave)
    PoincareConstant(dfct=dexp,qfct=qexp,pfct=NULL,rate=1,
      logconcave=TRUE) # log-concave assumption
    PoincareConstant(dfct=dexp,qfct=NULL,pfct=pexp,rate=1,
      optimize.interval=c(0, 15)) # logistic transport approach

    # Weibull law (log-concave)
    PoincareConstant(dfct=dweibull,qfct=NULL,pfct=pweibull,
      optimize.interval=c(0, 15),shape=1,scale=1) # logistic transport approach


    # Triangular law (log-concave)
    library(triangle)
    PoincareConstant(dfct=dtriangle, qfct=qtriangle, pfct=NULL, a=-1, b=1, c=0, 
      logconcave=TRUE) # log-concave assumption
    PoincareConstant(dfct=dtriangle, qfct=NULL, pfct=ptriangle, a=-1, b=1, c=0, 
      transport="double_exp", optimize.interval=c(-1,1)) # Double-exp transport 
    PoincareConstant(dfct=dtriangle, qfct=NULL, pfct=ptriangle, a=-1, b=1, c=0, 
      optimize.interval=c(-1,1)) # Logistic transport calculation

    # Normal N(0,1) law truncated on [-1.87,+infty]
    PoincareConstant(dfct=dnorm,qfct=qnorm,pfct=pnorm,mean=0,sd=1,logconcave=TRUE, 
      transport="double_exp", truncated=TRUE, min=-1.87, max=999) # log-concave hyp 
    # Double-exponential transport approach
    PoincareConstant(dfct=dnorm.trunc, qfct=qnorm.trunc, pfct=pnorm.trunc, 
      mean=0, sd=1, truncated=TRUE, min=-1.87, max=999,   transport="double_exp", 
        optimize.interval=c(-1.87,20)) 
    # Logistic transport approach
    PoincareConstant(dfct=dnorm.trunc, qfct=qnorm.trunc, pfct=pnorm.trunc, 
      mean=0, sd=1, truncated=TRUE, min=-1.87, max=999, optimize.interval=c(-1.87,20)) 


    # Gumbel law (log-concave)
    library(evd)
    PoincareConstant(dfct=dgumbel, qfct=qgumbel, pfct=NULL, loc=0, scale=1, 
      logconcave=TRUE, transport="double_exp") # log-concave assumption
    PoincareConstant(dfct=dgumbel, qfct=NULL, pfct=pgumbel, loc=0, scale=1, 
      transport="double_exp", optimize.interval=c(-3,20)) # Double-exp transport 
    PoincareConstant(dfct=dgumbel, qfct=qgumbel, pfct=pgumbel, loc=0, scale=1, 
      optimize.interval=c(-3,20)) # Logistic transport approach

    # Truncated Gumbel law (log-concave)
    # Double-exponential transport approach
    PoincareConstant(dfct=dgumbel, qfct=qgumbel, pfct=pgumbel, loc=0, scale=1, 
      logconcave=TRUE, transport="double_exp", truncated=TRUE, 
      min=-0.92, max=3.56) # log-concave assumption
    PoincareConstant(dfct=dgumbel.trunc, qfct=NULL, pfct=pgumbel.trunc, loc=0, scale=1, 
      truncated=TRUE, min=-0.92, max=3.56, transport="double_exp", 
      optimize.interval=c(-0.92,3.56))
    # Logistic transport approach
    PoincareConstant(dfct=dgumbel.trunc, qfct=qgumbel.trunc, pfct=pgumbel.trunc, 
      loc=0, scale=1, truncated=TRUE, min=-0.92, max=3.56, 
      optimize.interval=c(-0.92,3.56))
}

test_9 <- function() {


    # uniform on [a, b]
    a <- -1 ; b <- 1
    out <- PoincareOptimal(distr = list("unif", a, b))
    cat("Poincare constant (theory -- estimated):", (b-a)^2/pi^2, "--", out$opt, "\n")

    # truncated standard normal on [-1, 1]
    # the optimal Poincare constant is then equal to 1/3,
    # as -1 and 1 are consecutive roots of the 2nd Hermite polynomial X*X - 1.
    out <- PoincareOptimal(distr = dnorm, min = -1, max = 1, 
                           plot = TRUE, only.values = FALSE)
    cat("Poincare constant (theory -- estimated):", 1/3, "--", out$opt, "\n")


    # truncated standard normal on [-1.87, +infty]
    out <- PoincareOptimal(distr = list("norm", 0, 1), min = -1.87, max = 5, 
                           method = "integral", n = 500)
    print(out$opt)

    # truncated Gumbel(0,1) on [-0.92, 3.56]
    library(evd)
    out <- PoincareOptimal(distr = list("gumbel", 0, 1), min = -0.92, max = 3.56, 
                           method = "integral", n = 500)
    print(out$opt)

    # symetric triangular [-1,1]
    library(triangle)
    out <- PoincareOptimal(distr = list("triangle", -1, 1, 0), min = NULL, max = NULL)
    cat("Poincare constant (theory -- estimated):", 0.1729, "--", out$opt, "\n")


    # Lognormal distribution
    out <- PoincareOptimal(distr = list("lognorm", 1, 2), min = 3, max = 10, 
                           only.values = FALSE, plot = TRUE, method = "integral")
    print(out$opt)


    ## -------------------------------

    ## Illustration for eigenfunctions on the uniform distribution
    ## (corresponds to Fourier series)
    b <- 1
    a <- -b
    out <- PoincareOptimal(distr = list("unif", a, b), 
                           only.values = FALSE, der = TRUE, method = "quad")

    # Illustration for 3 eigenvalues

    par(mfrow = c(3,2))
    eigenNumber <- 1:3 # eigenvalue number
    for (k in eigenNumber[1:3]){ # keep the 3 first ones (for graphics)
      plot(out$knots, out$vectors[, k + 1], type = "l", 
           ylab = "", main = paste("Eigenfunction", k), 
           xlab = paste("Eigenvalue:", round(out$values[k+1], digits = 3)))
      sgn <- sign(out$vectors[1, k + 1])
      lines(out$knots, sgn * sqrt(2) * cos(pi * k * (out$knots/(b-a) + 0.5)), 
            col = "red", lty = "dotted")
  
      plot(out$knots, out$der[, k + 1], type = "l", 
           ylab = "", main = paste("Eigenfunction derivative", k), 
           xlab = "")
      sgn <- sign(out$vectors[1, k + 1])
      lines(out$knots, - sgn * sqrt(2) / (b-a) * pi * k * sin(pi * k * (out$knots/(b-a) + 0.5)), 
            col = "red", lty = "dotted")
    }


    # how to create a function for one eigenfunction and eigenvalue,
    # given N values 
    eigenFun <- approxfun(x = out$knots, y = out$vectors[, 2])
    eigenDerFun <- approxfun(x = out$knots, y = out$der[, 2])
    x <- runif(n = 3, min = -1/2, max = 1/2)
    eigenFun(x)
    eigenDerFun(x)
}

test_10 <- function() {


    library(parallel)
    library(boot)
    library(car)

    library(mvtnorm)

    set.seed(1234)
    n <- 100
    sigma<-matrix(c(1,0,0,0.9, 0,1,-0.8,0, 0,-0.8,1,0, 0.9,0,0,1), nr=4, nc=4)

    ############################
    # Gaussian correlated inputs

    X <- as.data.frame(rmvnorm(n, rep(0,4), sigma))
    colnames(X) <- c("X1","X2","X3","X4")

    #############################
    # Linear Model with small noise, two correlated inputs (X2 and X3) and 
    # one dummy input (X4) correlated with another (X1)
    epsilon <- rnorm(n,0,0.1)
    y <- with(X, X1 - X2 + 0.5 * X3 + epsilon)

    # Without Bootstrap confidence intervals
    x <- VIM(X, y)
    print(x)
    plot(x)
    library(ggplot2) ; ggplot(x)

    # With Boostrap confidence intervals
    x <- VIM(X, y, nboot=100, conf=0.9)
    print(x)
    plot(x)
    library(ggplot2) ; ggplot(x)

    ############################
    # Logistic Regression (same regression model)

    epsilon <- rnorm(n,0,0.1)
    y <- with(X, X1 - X2 + 0.5 * X3 + epsilon > 0)

    x <- VIM(X, y, logistic = TRUE)
    print(x)
    plot(x)
    library(ggplot2) ; ggplot(x)
}

test_11 <- function() {
    dimension <- 6
    levels <- 7
    OA <- addelman_const(dimension,levels,choice="U")
}

test_12 <- function() {
    x <- runif(100)
    y <- round(x)
    correlRatio(x,y)
}

test_13 <- function() {
    # Example of use of fast99 with "model = NULL"
    x <- fast99(model = NULL, factors = 3, n = 1000,
                q = "qunif", q.arg = list(min = -pi, max = pi))
    y <- ishigami.fun(x$X)
    tell(x, y)
    print(x)
    plot(x)
}

test_14 <- function() {
    # Test case : the non-monotonic Sobol g-function
    # (there are 8 factors, all following the uniform distribution on [0,1])


    library(randtoolbox)
    x <- delsa(model=sobol.fun,
               par.ranges=replicate(8,c(0,1),simplify=FALSE),
               samples=100,method="sobol")

    # Summary of sensitivity indices of each parameter across parameter space
    print(x)

    library(ggplot2)
    library(reshape2)
    plot(x)
}

test_15 <- function() {
    dimension <- 2
    n <- 40
    X <- matrix(runif(n*dimension),n,dimension)
    discrepancyCriteria_cplus(X)
}

test_16 <- function() {
    # Test case : the non-monotonic Ishigami function
    x <- fast99(model = ishigami.fun, factors = 3, n = 1000,
                q = "qunif", q.arg = list(min = -pi, max = pi))
    print(x)
    plot(x)
}

test_17 <- function() {

    ##################################
    # Same example than the one in src()

    # a 100-sample with X1 ~ U(0.5, 1.5)
    #                   X2 ~ U(1.5, 4.5)
    #                   X3 ~ U(4.5, 13.5)

    library(boot)
    n <- 100
    X <- data.frame(X1 = runif(n, 0.5, 1.5),
                    X2 = runif(n, 1.5, 4.5),
                    X3 = runif(n, 4.5, 13.5))

    # linear model : Y = X1 + X2 + X3

    y <- with(X, X1 + X2 + X3)

    # sensitivity analysis

    x <- johnson(X, y, nboot = 100)
    print(x)
    plot(x)

    library(ggplot2)
    ggplot(x)


    #################################
    # Same examples than the ones in lmg()

    library(boot)
    library(mvtnorm)

    set.seed(1234)
    n <- 1000
    beta<-c(1,-1,0.5)
    sigma<-matrix(c(1,0,0,
                    0,1,-0.8,
                    0,-0.8,1),
                  nrow=3,
                  ncol=3)

    ##########
    # Gaussian correlated inputs

    X <-rmvnorm(n, rep(0,3), sigma)
    colnames(X)<-c("X1","X2", "X3")

    #########
    # Linear Model

    y <- X%*%beta + rnorm(n,0,2)

    # Without Bootstrap confidence intervals
    x<-johnson(X, y)
    print(x)
    plot(x)

    # With Boostrap confidence intervals
    x<-johnson(X, y, nboot=100, conf=0.95)
    print(x)
    plot(x)

    # Rank-based analysis
    x<-johnson(X, y, rank=TRUE, nboot=100, conf=0.95)
    print(x)
    plot(x)

    #######
    # Logistic Regression
    y<-as.numeric(X%*%beta + rnorm(n)>0)
    x<-johnson(X,y, logistic = TRUE)
    plot(x)
    print(x)

    #################################
    # Test on a modified Linkletter fct with: 
    # - multivariate normal inputs (all multicollinear)
    # - in dimension 50 (there are 42 dummy inputs)
    # - large-size sample (1e4)

    library(mvtnorm)

    n <- 1e4
    d <- 50
    sigma <- matrix(0.5,ncol=d,nrow=d)
    diag(sigma) <- 1
    X <- rmvnorm(n, rep(0,d), sigma)

    y <- linkletter.fun(X)
    joh <- johnson(X,y)
    sum(joh$johnson) # gives the R2
    plot(joh)
}

test_18 <- function() {

    library(ggplot2)
    library(boot)

    #####################################################
    # Test case: the non-monotonic Sobol g-function (with independent inputs)
    n <- 1000
    X <- data.frame(matrix(runif(8 * n), nrow = n))
    x <- johnsonshap(model = sobol.fun, X1 = X, N = n)
    print(x)
    plot(x)
    ggplot(x)


    #############################################
    # 3D analytical toy functions described in Iooss & Clouvel (2023)

    library(mvtnorm)

    Xall <- function(n) mvtnorm::rmvnorm(n,mu,Covmat)
    # 2 correlated inputs
    Cov3d2 <- function(rho){ # correl (X1,X2)
      Cormat <- matrix(c(1,rho,0,rho,1,0,0,0,1),3,3)
      return( ( sig %*% t(sig) ) * Cormat)
    }
    mu3d <- c(1,0,0) ; sig3d <- c(0.25,1,1)
    d <- 3 ; mu <- mu3d ; sig <- sig3d ; Covm <- Cov3d2
    Xvec <- c("X1","X2","X3")

    n <- 1e4    # initial sample size
    N <- 1e4    # cost to estimate indices 
    rho <- 0.9  # correlation coef for dependent inputs' case

    ################
    # Linear model + a strong 2nd order interaction

    toy3d <- function(x) return(x[,1]*(1+x[,1]*(cos(x[,2]+x[,3])^2))) 
    # interaction X2X3
    toy <- toy3d 

    # Independent case

    Covmat <- Covm(0)
    X <- as.data.frame(Xall(n))
    Y <- toy(X)
    joh <- johnson(X, Y, nboot=100)
    print(joh)
    johshap <- johnsonshap(model = toy, X1 = X, N = N, nboot=100)
    print(johshap)
    ggplot(johshap)

    # Dependent case

    Covmat <- Covm(rho)
    Xdep <- as.data.frame(Xall(n))
    Ydep <- toy(Xdep)
    joh <- johnson(Xdep, Ydep, nboot=0)
    print(joh)
    johshap <- johnsonshap(model = toy, X1 = Xdep, N = N, nboot=100)
    print(johshap)
    ggplot(johshap)

    ################
    # Strongly non-inear model + a strong 2nd order interaction

    toy3dNL <- function(x) return(sin(x[,1]*pi/2)*(1+x[,1]*(cos(x[,2]+x[,3])^2))) 
    # non linearity in X1
    toy <- toy3dNL

    # Independent case

    Covmat <- Covm(0)
    X <- as.data.frame(Xall(n))
    Y <- toy(X)
    joh <- johnson(X, Y, nboot=100)
    print(joh)
    johshap <- johnsonshap(model = toy, X1 = X, N = N, nboot=100)
    print(johshap)
    ggplot(johshap)

    # Dependent case

    Covmat <- Covm(rho)
    Xdep <- as.data.frame(Xall(n))
    Ydep <- toy(Xdep)
    joh <- johnson(Xdep, Ydep, nboot=0)
    print(joh)
    johshap <- johnsonshap(model = NULL, X1 = Xdep, N = N, nboot=100)
    y <- toy(johshap$X)
    tell(johshap, y)
    print(johshap)
    ggplot(johshap)
}

test_19 <- function() {
    library(parallel)
    library(doParallel)
    library(foreach)
    library(gtools)
    library(boot)

    library(mvtnorm)

    set.seed(1234)
    n <- 1000
    beta<-c(1,-1,0.5)
    sigma<-matrix(c(1,0,0,
                    0,1,-0.8,
                    0,-0.8,1),
                  nrow=3,
                  ncol=3)

    ############################
    # Gaussian correlated inputs

    X <-rmvnorm(n, rep(0,3), sigma)
    colnames(X)<-c("X1","X2", "X3")

    #############################
    # Linear Model

    y <- X%*%beta + rnorm(n,0,2)

    # Without Bootstrap confidence intervals
    x<-lmg(X, y)
    print(x)
    plot(x)

    # With Boostrap confidence intervals
    x<-lmg(X, y, nboot=100, conf=0.95)
    print(x)
    plot(x)

    # Rank-based analysis
    x<-lmg(X, y, rank=TRUE, nboot=100, conf=0.95)
    print(x)
    plot(x)

    ############################
    # Logistic Regression
    y<-as.numeric(X%*%beta + rnorm(n)>0)
    x<-lmg(X,y, logistic = TRUE)
    plot(x)
    print(x)

    # Parallel computing
    #x<-lmg(X,y, logistic = TRUE, parl=2)
    #plot(x)
    #print(x)
}

test_20 <- function() {
    dimension <- 2
    n <- 40
    X <- matrix(runif(n*dimension),n,dimension)
    maximin_cplus(X)
}

test_21 <- function() {
    # Test case : the non-monotonic function of Morris
    x <- morris(model = morris.fun, factors = 20, r = 4,
                design = list(type = "oat", levels = 5, grid.jump = 3))
    print(x)
    plot(x)

    library(rgl)
    plot3d.morris(x)  # (requires the package 'rgl')


    # Only for demonstration purposes: a model function returning a matrix
    morris.fun_matrix <- function(X){
      res_vector <- morris.fun(X)
      cbind(res_vector, 2 * res_vector)
    }
    x <- morris(model = morris.fun_matrix, factors = 20, r = 4,
                design = list(type = "oat", levels = 5, grid.jump = 3))
    plot(x, y_col = 2)
    title(main = "y_col = 2")

    # Also only for demonstration purposes: a model function returning a
    # three-dimensional array
    morris.fun_array <- function(X){
      res_vector <- morris.fun(X)
      res_matrix <- cbind(res_vector, 2 * res_vector)
      array(data = c(res_matrix, 5 * res_matrix), 
            dim = c(length(res_vector), 2, 2))
    }
    x <- morris(model = morris.fun_array, factors = 20, r = 4,
                design = list(type = "simplex", scale.factor = 1))
    plot(x, y_col = 2, y_dim3 = 2)
    title(main = "y_col = 2, y_dim3 = 2")
}

test_22 <- function() {

      mdl <- function (X) t(atantemp.fun(X))

      x = morrisMultOut(model = mdl, factors = 4, r = 50, 
      design = list(type = "oat", levels = 5, grid.jump = 3), binf = -1, bsup = 5, 
        scale = FALSE)
      print(x)
      plot(x)

      x = morrisMultOut(model = NULL, factors = 4, r = 50, 
      design = list(type = "oat", levels = 5, grid.jump = 3), binf = -1, bsup = 5, 
        scale = FALSE)
      Y = mdl(x[['X']])
      tell(x, Y)	
      print(x)
      plot(x)
}

test_23 <- function() {

    X.grid <- parameterSets(par.ranges=list(V1=c(1,1000),V2=c(1,4)),
                              samples=c(10,10),method="grid")
    plot(X.grid)

    X.innergrid<-parameterSets(par.ranges=list(V1=c(1,1000),V2=c(1,4)),
                              samples=c(10,10),method="innergrid")
    points(X.innergrid,col="red")


    library(randtoolbox)
    X.sobol<-parameterSets(par.ranges=list(V1=c(1,1000),V2=c(1,4)),
                               samples=100,method="sobol")
    plot(X.sobol)
}

test_24 <- function() {

    # a 100-sample with X1 ~ U(0.5, 1.5)
    #                   X2 ~ U(1.5, 4.5)
    #                   X3 ~ U(4.5, 13.5)
    library(boot)
    n <- 100
    X <- data.frame(X1 = runif(n, 0.5, 1.5),
                    X2 = runif(n, 1.5, 4.5),
                    X3 = runif(n, 4.5, 13.5))

    # linear model : Y = X1^2 + X2 + X3
    y <- with(X, X1^2 + X2 + X3)

    # sensitivity analysis
    x <- pcc(X, y, nboot = 100)
    print(x)
    plot(x)

    library(ggplot2)
    ggplot(x)
    ggplot(x, ylim = c(-1.5,1.5))

    x <- pcc(X, y, semi = TRUE, nboot = 100)
    print(x)
    plot(x)
}

test_25 <- function() {
  
  
    library(parallel)
    library(doParallel)
    library(foreach)
    library(gtools)
    library(boot)
    library(RANN)

    ###########################################################
    # Linear Model with Gaussian correlated inputs

    library(mvtnorm)

    set.seed(1234)
    n <- 1000
    beta<-c(1,-1,0.5)
    sigma<-matrix(c(1,0,0,
                    0,1,-0.8,
                    0,-0.8,1),
                  nrow=3,
                  ncol=3)

    X <-rmvnorm(n, rep(0,3), sigma)
    colnames(X)<-c("X1","X2", "X3")


    y <- X%*%beta + rnorm(n,0,2)

    # Without Bootstrap confidence intervals
    x<-pme_knn(model=NULL, X=X,
                n.knn=3,
                noise=TRUE)
    tell(x,y)
    print(x)
    plot(x)

    # With Boostrap confidence intervals
    x<-pme_knn(model=NULL, X=X,
                nboot=10, 
                n.knn=3,
                noise=TRUE,
                boot.level=0.7, 
                conf=0.95)
    tell(x,y)
    print(x)
    plot(x)

    #####################################################
    # Test case: the Ishigami function
    # Example with given data and the use of approximate nearest neighbour search
    n <- 5000
    X <- data.frame(matrix(-pi+2*pi*runif(3 * n), nrow = n))
    Y <- ishigami.fun(X)
    x <- pme_knn(model = NULL, X = X,  method = "knn", n.knn = 5, 
                           n.limit = 2000)
    tell(x,Y)
    plot(x)

    library(ggplot2) ; ggplot(x)

    ######################################################
    # Test case : Linear model (3 Gaussian inputs including 2 dependent) with scaling
    # See Iooss and Prieur (2019)
    library(mvtnorm) # Multivariate Gaussian variables
    library(whitening) # For scaling
    modlin <- function(X) apply(X,1,sum)
    d <- 3
    n <- 10000
    mu <- rep(0,d)
    sig <- c(1,1,2)
    ro <- 0.9
    Cormat <- matrix(c(1,0,0,0,1,ro,0,ro,1),d,d)
    Covmat <- ( sig %*% t(sig) ) * Cormat
    Xall <- function(n) mvtnorm::rmvnorm(n,mu,Covmat)
    X <- Xall(n)
    x <- pme_knn(model = modlin, X = X, method = "knn", n.knn = 5, 
                           rescale = TRUE, n.limit = 2000)
    print(x)
    plot(x)
}

test_26 <- function() {
    library(parallel)
    library(gtools)
    library(boot)

    library(mvtnorm)

    set.seed(1234)
    n <- 100
    beta<-c(1,-2,3)
    sigma<-matrix(c(1,0,0,
                    0,1,-0.8,
                    0,-0.8,1),
                  nrow=3,
                  ncol=3)

    ############################
    # Gaussian correlated inputs

    X <-rmvnorm(n, rep(0,3), sigma)

    #############################
    # Linear Model

    y <- X%*%beta + rnorm(n)

    # Without Bootstrap confidence intervals
    x<-pmvd(X, y)
    print(x)
    plot(x)

    # With Boostrap confidence intervals
    x<-pmvd(X, y, nboot=100, conf=0.95)
    print(x)
    plot(x)

    # Rank-based analysis
    x<-pmvd(X, y, rank=TRUE, nboot=100, conf=0.95)
    print(x)
    plot(x)

    ############################
    # Logistic Regression
    y<-as.numeric(X%*%beta + rnorm(n)>0)
    x<-pmvd(X,y, logistic = TRUE)
    plot(x)
    print(x)

    # Parallel computing
    #x<-pmvd(X,y, logistic = TRUE, parl=2)
    #plot(x)
    #print(x)
}

test_27 <- function() {
 
    library(ks)
    library(ggplot2)
    library(boot)

    # Test case : difference of two exponential distributions (Fort et al. (2016))
    # We use two samples with different sizes
    n1 <- 5000
    X1 <- data.frame(matrix(rexp(2 * n1,1), nrow = n1))
    n2 <- 1000
    X2 <- data.frame(matrix(rexp(2 * n2,1), nrow = n2))
    Y1 <- X1[,1] - X1[,2]
    Y2 <- X2[,1] - X2[,2]
    x <- qosa(model = NULL, X1, X2, type = "quantile", alpha = 0.1)
    tell(x,c(Y1,Y2))
    print(x)
    ggplot(x)

    # Test case : difference of two exponential distributions (Fort et al. (2016))
    # We use only one sample
    n <- 1000 # put n=10000 for more consistency
    X <- data.frame(matrix(rexp(2 * n,1), nrow = n))
    Y <- X[,1] - X[,2]
    x <- qosa(model = NULL, X1 = X, type = "quantile", alpha = 0.7)
    tell(x,Y)
    print(x)
    ggplot(x)

    # Test case : the Ishigami function
    # We estimate first-order Sobol' indices (by specifying 'mean')
    # Next lines are put in comment because too long fro CRAN tests
    #n <- 5000 
    #nboot <- 50 
    #X <- data.frame(matrix(-pi+2*pi*runif(3 * n), nrow = n))
    #x <- qosa(model = ishigami.fun, X1 = X, type = "mean", nboot = nboot)
    #print(x)
    #ggplot(x)
}

test_28 <- function() {
    # a model with interactions
    p <- 50
    beta <- numeric(length = p)
    beta[1:5] <- runif(n = 5, min = 10, max = 50)
    beta[6:p] <- runif(n = p - 5, min = 0, max = 0.3)
    beta <- sample(beta)
    gamma <- matrix(data = runif(n = p^2, min = 0, max = 0.1), nrow = p, ncol = p)
    gamma[lower.tri(gamma, diag = TRUE)] <- 0
    gamma[1,2] <- 5
    gamma[5,9] <- 12
    f <- function(x) { return(sum(x * beta) + (x %*% gamma %*% x))}

    # 10 iterations of SB
    sa <- sb(p, interaction = TRUE)
    for (i in 1 : 10) {
      x <- ask(sa)
      y <- list()
      for (i in names(x)) {
        y[[i]] <- f(x[[i]])
      }
      tell(sa, y)
    }
    print(sa)
    plot(sa)
}

test_29 <- function() {

    library(ks)

    # Test case : the non-monotonic Sobol g-function
    n <- 100
    X <- data.frame(matrix(runif(8 * n), nrow = n))

    # Density-based sensitivity analysis
    # the next lines are put in comment because too long for CRAN tests
    #x <- sensiFdiv(model = sobol.fun, X = X, fdiv = c("TV","KL"), nboot=30)
    #print(x)
    #library(ggplot2)
    #ggplot(x)
}

test_30 <- function() {
 
    ############################
    ### HSIC indices for GSA ###
    ############################

    # Test case 1: the Friedman function
    # --> 5 input variables

    ### GSA with a given model ###

    n <- 800
    p <- 5
    X <- matrix(runif(n*p), n, p)

    kernelX <- c("rbf", "rbf", "laplace", "laplace", "sobolev1")
    paramX <- c(0.2, 0.3, 0.4, NA, NA)

    # kernel for X1: Gaussian kernel with given parameter 0.2
    # kernel for X2: Gaussian kernel with given parameter 0.3
    # kernel for X3: exponential kernel with given parameter 0.4
    # kernel for X4: exponential kernel with automatic computation of the parameter
    # kernel for X5: Sobolev kernel (r=1) with no parameter

    kernelY <- "raquad"
    paramY <- NA 

    sensi <- sensiHSIC(model=friedman.fun, X,
                       kernelX=kernelX, paramX=paramX, 
                       kernelY=kernelY, paramY=paramY)

    print(sensi)
    plot(sensi)
    title("GSA for the Friedman function")

    ### GSA with given data ###

    Y <- friedman.fun(X)
    sensi <- sensiHSIC(model=NULL, X,
                       kernelX=kernelX, paramX=paramX, 
                       kernelY=kernelY, paramY=paramY)
    sensi <- tell(sensi, y=Y)

    print(sensi)

    ### GSA from a prior object of class "sensiHSIC" ###

    new.sensi <- sensiHSIC(model=friedman.fun, X,
                           kernelX=kernelX, paramX=paramX, 
                           kernelY=kernelY, paramY=paramY,
                           estimator.type="U-stat", 
                           sensi=sensi,
                           save.GM=list(KX=FALSE, KY=FALSE))

    print(new.sensi)

    # U-statistics are computed without rebuilding all Gram matrices.
    # Those Gram matrices are not saved a second time.

    ##################################
    ### HSIC-ANOVA indices for GSA ###
    ##################################

    # Test case 2: the Matyas function with Gaussian input variables
    # --> 3 input variables (including 1 dummy variable)

    n <- 10^3
    p <- 2

    X <- matrix(rnorm(n*p), n, p)

    # The Sobolev kernel (with r=1) is used to achieve the HSIC-ANOVA decomposition.
    # Both first-order and total-order HSIC-ANOVA indices are expected.

    ### AUTOMATIC RESCALING ###

    kernelX <- "sobolev1"
    anova <- list(obj="both", is.uniform=FALSE)

    sensi.A <- sensiHSIC(model=matyas.fun, X, kernelX=kernelX, anova=anova)

    print(sensi.A)
    plot(sensi.A)
    title("GSA for the Matyas function")

    ### PROBLEM REFORMULATION ###

    U <- matrix(runif(n*p), n, p)
    new.matyas.fun <- function(U){ matyas.fun(qnorm(U)) }

    kernelX <- "sobolev1"
    anova <- list(obj="both", is.uniform=TRUE)

    sensi.B <- sensiHSIC(model=new.matyas.fun, U, kernelX=kernelX, anova=anova)

    print(sensi.B)

    ####################################
    ### T-HSIC indices for target SA ###
    ####################################

    # Test case 3: the Sobol function
    # --> 8 input variables

    n <- 10^3
    p <- 8

    X <- matrix(runif(n*p), n, p)

    kernelY <- "categ"
    target <- list(c=0.4, type="indicTh")

    sensi <- sensiHSIC(model=sobol.fun, X, kernelY=kernelY, target=target)

    print(sensi)
    plot(sensi)
    title("TSA for the Sobol function")

    #########################################
    ### C-HSIC indices for conditional SA ###
    #########################################

    # Test case 3: the Sobol function
    # --> 8 input variables

    n <- 10^3
    p <- 8

    X <- matrix(runif(n*p), n, p)

    cond <- list(c=0.2, type="exp1side", upper=FALSE)

    sensi <- sensiHSIC(model=sobol.fun, X, cond=cond)

    print(sensi)
    plot(sensi)
    title("CSA for the Sobol function")

    ##########################################
    ### How to deal with discrete outputs? ###
    ##########################################

    # Test case 4: classification of the Ishigami output
    # --> 3 input variables
    # --> 3 categories

    classif <- function(X){
  
      Ytemp <- ishigami.fun(X) 
      Y <- rep(NA, n)
      Y[Ytemp<0] <- 0
      Y[Ytemp>=0 & Ytemp<10] <- 1                
      Y[Ytemp>=10] <- 2  
  
      return(Y)
  
    }

    ###

    n <- 10^3
    p <- 3

    X <- matrix(runif(n*p, -pi, pi), n, p)

    kernelY <- "categ"
    paramY <- 0

    sensi <- sensiHSIC(model=classif, X, kernelY=kernelY, paramY=paramY)
    print(sensi)
    plot(sensi)
    title("GSA for the classified Ishigami function")

    ############################################
    ### How to deal with functional outputs? ###
    ############################################

    # Test case 5: the arctangent temporal function
    # --> 3 input variables (including 1 dummy variable)

    n <- 500
    p <- 3

    X <- matrix(runif(n*p,-7,7), n, p)

    ### with a preliminary dimension reduction by PCA ###

    kernelY <- list(method="PCA", 
                    data.centering=TRUE, data.scaling=TRUE,
                    fam="rbf", expl.var=0.95, combi="sum", position="extern")

    sensi <- sensiHSIC(model=atantemp.fun, X, kernelY=kernelY)

    print(sensi)
    plot(sensi)
    title("PCA-based GSA for the arctangent temporal function")

    ### with a kernel based on dynamic time warping ###

    kernelY <- list(method="DTW", fam="rbf")

    sensi <- sensiHSIC(model=atantemp.fun, X, kernelY=kernelY)

    print(sensi)
    plot(sensi)
    title("DTW-based GSA for the arctangent temporal function")



    ### with the global alignment kernel ###

    kernelY <- list(method="GAK")

    sensi <- sensiHSIC(model=atantemp.fun, X, kernelY=kernelY)

    print(sensi)
    plot(sensi)
    title("GAK-based GSA for the arctangent temporal function")
}

test_31 <- function() {

    # packages for the plots of the matrices
    library(gplots)
    library(graphics)


    # the following function improves the plots of the matrices
    sig=function(x,alpha=0.4)
    {
      return(1/(1+exp(-x/alpha)))
    }


    # 1) we generate the parameters by groups in order

    K=4 # number or groups

    pk=rep(0,K)
    for(k in 1:K)
    {
      pk[k]=round(6+4*runif(1))
    }
    p=sum(pk)
    Sigma_ord=matrix(0,nrow=p, ncol=p)
    ind_min=0
    L=5
    for(k in 1:K)
    {
      p_k=pk[k]
      ind=ind_min+(1:p_k)
      ind_min=ind_min+p_k
  
      A=2*matrix(runif(p_k*L),nrow=L,ncol=p_k)-1
      Sigma_ord[ind,ind]=t(A)%*%A + 0.2*diag(rep(1,p_k))
    }


    image((0:p)+0.5,(0:p)+0.5,z=sig(Sigma_ord),col=cm.colors(100), zlim=c(0,1),
          ylim=c(p+0.5,0.5), main=expression(Sigma["order"]), 
          cex.main=3,ylab = "", xlab = "",axes=FALSE)
    box()


    Beta_ord=3*runif(p)+1
    eta_ord=shapleyLinearGaussian(Beta=Beta_ord, Sigma=Sigma_ord)
    barplot(eta_ord,main=expression(eta["order"]),cex.axis = 2,cex.main=3)


    # 2) We sample the input variables to get an input vector more general

    samp=sample(1:p)
    Sigma=Sigma_ord[samp,samp]

    image((0:p)+0.5,(0:p)+0.5,z=sig(Sigma),col=cm.colors(100), zlim=c(0,1),
          ylim=c(p+0.5,0.5), main=expression(Sigma), 
          cex.main=3,ylab = "",xlab = "",axes=FALSE)
    box()


    Beta=Beta_ord[samp]
    eta=shapleyLinearGaussian(Beta=Beta, Sigma=Sigma)
    barplot(eta,main=expression(eta),cex.axis = 2,cex.main=3)




    # 3) We generate the observations with these parameters

    n=5*p #sample size


    C=chol(Sigma)
    X0=matrix(rnorm(p*n),ncol=p)
    X=X0%*%C

    S=var(X) #empirical covariance matrix
    image((0:p)+0.5,(0:p)+0.5,z=sig(S),col=cm.colors(100), zlim=c(0,1),
          ylim=c(p+0.5,0.5), main=expression(S), 
          cex.main=3,ylab = "", xlab = "",axes=FALSE)
    box()

    beta0=rnorm(1)
    Y=X%*%as.matrix(Beta)+beta0+0.2*rnorm(p)



    # 4) We estimate the block-diagonal covariance matrix 
    # and the Shapley effects using the observations
    # We assume that we know that the groups are smaller than 15

    Estim=shapleyBlockEstimationX(X,Y,delta=3/4, M=15, tol=10^(-6))

    eta_hat=Estim$Shapley
    S_B=Estim$S_B

    image((0:p)+0.5,(0:p)+0.5,z=sig(S_B),col=cm.colors(100), zlim=c(0,1),
          ylim=c(p+0.5,0.5), main=expression(S[hat(B)]), 
          cex.main=3,ylab = "",xlab = "",axes=FALSE)
    box()

    barplot(eta_hat,main=expression(hat(eta)),cex.axis = 2,cex.main=3)


    sum(abs(eta_hat-eta))
}

test_32 <- function() {

    library(MASS)
    library(igraph)

    # First example:

    p=5 #dimension
    A=matrix(rnorm(p^2),nrow=p,ncol=p)
    Sigma=t(A)%*%A
    Beta=runif(p)
    Shapley=shapleyLinearGaussian(Beta,Sigma)
    plot(Shapley)


    # Second Example, block-diagonal:

    K=5 #number of groups
    m=5 # number of variables in each group
    p=K*m
    Sigma=matrix(0,ncol=p,nrow=p)

    for(k in 1:K)
    {
      A=matrix(rnorm(m^2),nrow=m,ncol=m)
      Sigma[(m*(k-1)+1):(m*k),(m*(k-1)+1):(m*k)]=t(A)%*%A
    }
    # we mix the variables:
    samp=sample(1:p,p)
    Sigma=Sigma[samp,samp]

    Beta=runif(p)
    Shapley=shapleyLinearGaussian(Beta,Sigma)
    plot(Shapley)
}

test_33 <- function() {



    ##################################
    # Test case : the Ishigami function (3 uniform independent inputs)
    # See Iooss and Prieur (2019)

    library(gtools)

    d <- 3
    Xall <- function(n) matrix(runif(d*n,-pi,pi),nc=d)
    Xset <- function(n, Sj, Sjc, xjc) matrix(runif(n*length(Sj),-pi,pi),nc=length(Sj))

    x <- shapleyPermEx(model = ishigami.fun, Xall=Xall, Xset=Xset, d=d, Nv=1e4, No = 1e3, Ni = 3)
    print(x)
    plot(x)

    library(ggplot2)
    ggplot(x)

    ##################################
    # Test case : Linear model (3 Gaussian inputs including 2 dependent)
    # See Iooss and Prieur (2019)

    library(ggplot2)
    library(gtools)
    library(mvtnorm) # Multivariate Gaussian variables
    library(condMVNorm) # Conditional multivariate Gaussian variables

    modlin <- function(X) apply(X,1,sum)

    d <- 3
    mu <- rep(0,d)
    sig <- c(1,1,2)
    ro <- 0.9
    Cormat <- matrix(c(1,0,0,0,1,ro,0,ro,1),d,d)
    Covmat <- ( sig %*% t(sig) ) * Cormat

    Xall <- function(n) mvtnorm::rmvnorm(n,mu,Covmat)

    Xset <- function(n, Sj, Sjc, xjc){
      if (is.null(Sjc)){
        if (length(Sj) == 1){ rnorm(n,mu[Sj],sqrt(Covmat[Sj,Sj]))
        } else{ mvtnorm::rmvnorm(n,mu[Sj],Covmat[Sj,Sj])}
      } else{ condMVNorm::rcmvnorm(n, mu, Covmat, dependent.ind=Sj, given.ind=Sjc, 
                                    X.given=xjc)}}

    x <- shapleyPermEx(model = modlin, Xall=Xall, Xset=Xset, d=d, Nv=1e4, 
                        No = 1e3, Ni = 3)
    print(x)
    ggplot(x)
}

test_34 <- function() {



    ##################################
    # Test case : the Ishigami function
    # See Iooss and Prieur (2019)

    library(gtools)

    d <- 3
    Xall <- function(n) matrix(runif(d*n,-pi,pi),nc=d)
    Xset <- function(n, Sj, Sjc, xjc) matrix(runif(n*length(Sj),-pi,pi),nc=length(Sj))

    x <- shapleyPermRand(model = ishigami.fun, Xall=Xall, Xset=Xset, d=d, Nv=1e4, 
                          m=1e4, No = 1, Ni = 3)
    print(x)
    plot(x)

    library(ggplot2)
    ggplot(x)

    ##################################
    # Test case : Linear model (3 Gaussian inputs including 2 dependent)
    # See Iooss and Prieur (2019)

    library(ggplot2)
    library(gtools)
    library(mvtnorm) # Multivariate Gaussian variables
    library(condMVNorm) # Conditional multivariate Gaussian variables

    modlin <- function(X) apply(X,1,sum)

    d <- 3
    mu <- rep(0,d)
    sig <- c(1,1,2)
    ro <- 0.9
    Cormat <- matrix(c(1,0,0,0,1,ro,0,ro,1),d,d)
    Covmat <- ( sig %*% t(sig) ) * Cormat

    Xall <- function(n) mvtnorm::rmvnorm(n,mu,Covmat)

    Xset <- function(n, Sj, Sjc, xjc){
      if (is.null(Sjc)){
        if (length(Sj) == 1){ rnorm(n,mu[Sj],sqrt(Covmat[Sj,Sj]))
        } else{ mvtnorm::rmvnorm(n,mu[Sj],Covmat[Sj,Sj])}
      } else{ condMVNorm::rcmvnorm(n, mu, Covmat, dependent.ind=Sj, given.ind=Sjc, 
                                    X.given=xjc)}}

    m <- 1e3 # put m)1e4 for more precised results
    x <- shapleyPermRand(model = modlin, Xall=Xall, Xset=Xset, d=d, Nv=1e3, m = m, 
                          No = 1, Ni = 3)
    print(x)
    ggplot(x)
}

test_35 <- function() {


    # First example: the linear Gaussian framework

    # we generate a covariance matrice Sigma
    p <- 4 #dimension
    A <- matrix(rnorm(p^2),nrow=p,ncol=p)
    Sigma <- t(A)%*%A # it means t(A)%*%A
    C <- chol(Sigma)
    n <- 500 #sample size (put n=2000 for more consistency)

    Z=matrix(rnorm(p*n),nrow=n,ncol=p)
    X=Z%*%C # X is a gaussian vector with zero mean and covariance Sigma
    Y=rowSums(X) 
    Shap=shapleySubsetMc(X=X,Y=Y,Ntot=5000)
    plot(Shap)


    #Second example: The Sobol model with heterogeneous inputs

    p=8 #dimension
    A=matrix(rnorm(p^2),nrow=p,ncol=p)
    Sigma=t(A)%*%A
    C=chol(Sigma)
    n=500 #sample size (put n=5000 for more consistency)

    Z=matrix(rnorm(p*n),nrow=n,ncol=p)
    X=Z

    #we create discrete and categorical variables
    X[,1]=round(X[,1]/2) 
    X[,2]=X[,2]>2
    X[,4]=-2*round(X[,4])+4
    X[(X[,6]>0 &X[,6]<1),6]=1

    cat=c(1,2)  # we choose to take X1 and X2 as categorical variables 
                #   (with the discrete distance)
    discrete=c(4,6) # we indicate that X4 and X6 can take several times the same value

    Y=sobol.fun(X)
    Ntot <- 2000 # put Ntot=20000 for more consistency
    Shap=shapleySubsetMc(X=X,Y=Y, cat=cat, discrete=discrete, Ntot=Ntot, Ni=10)

    plot(Shap)
}

test_36 <- function() {
  
  
    library(parallel)
    library(doParallel)
    library(foreach)
    library(gtools)
    library(boot)
    library(RANN)

    ###########################################################
    # Linear Model with Gaussian correlated inputs

    library(mvtnorm)

    set.seed(1234)
    n <- 1000
    beta<-c(1,-1,0.5)
    sigma<-matrix(c(1,0,0,
                    0,1,-0.8,
                    0,-0.8,1),
                  nrow=3,
                  ncol=3)

    X <-rmvnorm(n, rep(0,3), sigma)
    colnames(X)<-c("X1","X2", "X3")


    y <- X%*%beta + rnorm(n,0,2)

    # Without Bootstrap confidence intervals
    x<-shapleysobol_knn(model=NULL, X=X,
                n.knn=3,
                noise=TRUE)
    tell(x,y)
    print(x)
    plot(x)

    #Using the extract method to get first-order and total Sobol' indices
    extract(x)

    # With Boostrap confidence intervals
    x<-shapleysobol_knn(model=NULL, X=X,
                nboot=10, 
                n.knn=3,
                noise=TRUE,
                boot.level=0.7, 
                conf=0.95)
    tell(x,y)
    print(x)
    plot(x)

    #####################
    # Extracting Sobol' indices with Bootstrap confidence intervals

    nboot <- 10 # put nboot=50 for consistency

    #Total Sobol' indices
    x<-shapleysobol_knn(model=NULL, X=X,
                nboot=nboot, 
                n.knn=3,
                U=0,
                noise=TRUE,
                boot.level=0.7, 
                conf=0.95)
    tell(x,y)
    print(x)
    plot(x)

    #First-order Sobol' indices
    x<-shapleysobol_knn(model=NULL, X=X,
                nboot=nboot, 
                n.knn=3,
                U=1,
                noise=TRUE,
                boot.level=0.7, 
                conf=0.95)
    tell(x,y)
    print(x)
    plot(x)

    #Closed Sobol' indices for specific subsets (list)
    x<-shapleysobol_knn(model=NULL, X=X,
                nboot=nboot, 
                n.knn=3,
                U=list(c(1,2), c(1,2,3), 2),
                noise=TRUE,
                boot.level=0.7, 
                conf=0.95)
    tell(x,y)
    print(x)
    plot(x)


    #####################################################
    # Test case: the non-monotonic Sobol g-function
    # Example with a call to a numerical model
    # First compute first-order indices with ranking
    
    n <- 1000
    X <- data.frame(matrix(runif(8 * n), nrow = n))
    x <- shapleysobol_knn(model = sobol.fun, X = X, U = 1, method = "rank")
    print(x)
    plot(x)

    library(ggplot2) ; ggplot(x)

    # We can use the output sample generated for this estimation to compute total indices 
    # without additional calls to the model
    x2 <- shapleysobol_knn(model = NULL, X = X, U = 0, method = "knn", n.knn = 5)
    tell(x2,x$y)
    plot(x2)

    ggplot(x2)


    #####################################################
    # Test case: the Ishigami function
    # Example with given data and the use of approximate nearest neighbour search
    n <- 5000
    X <- data.frame(matrix(-pi+2*pi*runif(3 * n), nrow = n))
    Y <- ishigami.fun(X)
    x <- shapleysobol_knn(model = NULL, X = X, U = NULL, method = "knn", n.knn = 5, 
                           n.limit = 2000)
    tell(x,Y)
    plot(x)

    library(ggplot2) ; ggplot(x)

    # Extract first-order and total Sobol indices
    x1 <- extract(x) ; print(x1)
    
    ######################################################
    # Test case : Linear model (3 Gaussian inputs including 2 dependent) with scaling
    # See Iooss and Prieur (2019)
    library(mvtnorm) # Multivariate Gaussian variables
    library(whitening) # For scaling
    modlin <- function(X) apply(X,1,sum)
    d <- 3
    n <- 10000
    mu <- rep(0,d)
    sig <- c(1,1,2)
    ro <- 0.9
    Cormat <- matrix(c(1,0,0,0,1,ro,0,ro,1),d,d)
    Covmat <- ( sig %*% t(sig) ) * Cormat
    Xall <- function(n) mvtnorm::rmvnorm(n,mu,Covmat)
    X <- Xall(n)
    x <- shapleysobol_knn(model = modlin, X = X, U = NULL, method = "knn", n.knn = 5, 
                           rescale = TRUE, n.limit = 2000)
    print(x)
    plot(x)
}

test_37 <- function() {
    # Test case : the non-monotonic Sobol g-function

    # The method of sobol requires 2 samples
    # (there are 8 factors, all following the uniform distribution on [0,1])
    library(boot)
    n <- 1000
    X1 <- data.frame(matrix(runif(8 * n), nrow = n))
    X2 <- data.frame(matrix(runif(8 * n), nrow = n))

    # sensitivity analysis
    x <- sobol(model = sobol.fun, X1 = X1, X2 = X2, order = 2, nboot = 100)
    print(x)
    #plot(x)

    library(ggplot2)
    ggplot(x)
}

test_38 <- function() {
    # Test case : the non-monotonic Sobol g-function

    # The method of sobol requires 2 samples
    # There are 8 factors, all following the uniform distribution
    # on [0,1]

    library(boot)
    n <- 1000
    X1 <- data.frame(matrix(runif(8 * n), nrow = n))
    X2 <- data.frame(matrix(runif(8 * n), nrow = n))

    # sensitivity analysis

    x <- sobol2002(model = sobol.fun, X1, X2, nboot = 100)
    print(x)
    plot(x)

    library(ggplot2)
    ggplot(x)
}

test_39 <- function() {
    # Test case : the non-monotonic Sobol g-function

    # The method of sobol requires 2 samples
    # There are 8 factors, all following the uniform distribution
    # on [0,1]

    library(boot)
    n <- 1000
    X1 <- data.frame(matrix(runif(8 * n), nrow = n))
    X2 <- data.frame(matrix(runif(8 * n), nrow = n))

    # sensitivity analysis

    x <- sobol2007(model = sobol.fun, X1, X2, nboot = 100)
    print(x)
    plot(x)

    library(ggplot2)
    ggplot(x)
}

test_40 <- function() {
    # Test case : the non-monotonic Sobol g-function

    # The method of sobol requires 2 samples
    # (there are 8 factors, all following the uniform distribution on [0,1])
    n <- 1000
    X1 <- data.frame(matrix(runif(8 * n), nrow = n))
    X2 <- data.frame(matrix(runif(8 * n), nrow = n))

    # sensitivity analysis
    x <- sobolEff(model = sobol.fun, X1 = X1, X2 = X2, nboot = 0)
    print(x)

    library(ggplot2)
    ggplot(x)
}

test_41 <- function() {


    library(DiceKriging)

    #--------------------------------------#
    # kriging model building
    #--------------------------------------#

    d <- 2; n <- 16
    design.fact <- expand.grid(x1=seq(0,1,length=4), x2=seq(0,1,length=4))
    y <- apply(design.fact, 1, branin) 

    m <- km(design=design.fact, response=y)

    #--------------------------------------#
    # sobol samples & candidate points
    #--------------------------------------#

    n <- 1000
    X1 <- data.frame(matrix(runif(d * n), nrow = n))
    X2 <- data.frame(matrix(runif(d * n), nrow = n))

    candidate <- data.frame(matrix(runif(d * 100), nrow = 100))

    #--------------------------------------#
    # Kriging-based Sobol
    #--------------------------------------#

    nsim <- 10 # put nsim <- 100
    nboot <- 10 # put nboot <- 100

    res <- sobolGP(
    model = m,
    type="UK",
    MCmethod="sobol",
    X1,
    X2,
    nsim = nsim,
    conf = 0.95,
    nboot = nboot,
    sequential = TRUE,
    candidate,
    sequential.tot=FALSE,
    max_iter = 1000
    ) 

    res
    plot(res)

    x <- ask(res)
    y <- branin(x)

    # The following line doesn't work (uncorrected bug: 
    #     unused argument in km(), passed by update(), eval(), tell.sobolGP() ??)
    #res.new <- tell(res,y,x)
    #res.new
}

test_42 <- function() {
  
    
        # Tests on the functional toy fct 'Arctangent temporal function'
    
        y0 <- atantemp.fun(matrix(c(-7,0,7,-7,0,7),ncol=2))
        #plot(y0[1,],type="l")
        #apply(y0,1,lines)
    
        n <- 100
        X <- matrix(c(runif(2*n,-7,7)),ncol=2)
        y <- atantemp.fun(X)
        plot(y0[2,],ylim=c(-2,2),type="l")
        apply(y,1,lines)
    
        # Sobol indices computations
    
        n <- 1000
        X1 <- data.frame(matrix(runif(2*n,-7,7), nrow = n))
        X2 <- data.frame(matrix(runif(2*n,-7,7), nrow = n))
    
        sa <- sobolMultOut(model=atantemp.fun, q=100, X1, X2, 
                           MCmethod="soboljansen", ubiquitous=TRUE)
        print(sa)
        plot(sa)
        plotMultOut(sa)
    
        library(ggplot2)
        ggplot(sa)
}

test_43 <- function() {
    # Test case : the non-monotonic Sobol g-function

    # The method of sobol requires 2 samples
    # There are 8 factors, all following the uniform distribution
    # on [0,1]

    library(boot)
    n <- 1000
    X1 <- data.frame(matrix(runif(8 * n), nrow = n))
    X2 <- data.frame(matrix(runif(8 * n), nrow = n))

    # sensitivity analysis

    x <- sobolSalt(model = sobol.fun, X1, X2, scheme="A", nboot = 100)
    print(x)
    plot(x, choice=1)

    library(ggplot2)
    ggplot(x, choice=1)
}

test_44 <- function() {
    	X = matrix(runif(5000), ncol = 10)
    	Y = sobol.fun(X)
    	sa = sobolSmthSpl(Y, X)
    	plot(sa)
}

test_45 <- function() {
    # Test case : the Ishigami function

    # The method requires 2 samples
    n <- 1000
    X1 <- data.frame(matrix(runif(3 * n, -pi, pi), nrow = n))
    X2 <- data.frame(matrix(runif(3 * n, -pi, pi), nrow = n))

    # sensitivity analysis (the true values of the scaled TIIs are 0, 0.244, 0)
    x <- sobolTIIlo(model = ishigami.fun, X1 = X1, X2 = X2)
    print(x)

    # plot of tiis and FANOVA graph
    plot(x)

    library(ggplot2)
    ggplot(x)


    library(igraph)
    plotFG(x)
}

test_46 <- function() {
    # Test case : the Ishigami function

    # The method requires 2 samples
    n <- 1000
    X1 <- data.frame(matrix(runif(3 * n, -pi, pi), nrow = n))
    X2 <- data.frame(matrix(runif(3 * n, -pi, pi), nrow = n))

    # sensitivity analysis (the true values are 0, 0.244, 0)
    x <- sobolTIIpf(model = ishigami.fun, X1 = X1, X2 = X2)
    print(x)

    # plot of tiis and FANOVA graph
    plot(x)

    library(ggplot2)
    ggplot(x)


    library(igraph)
    plotFG(x)
}

test_47 <- function() {
    # Test case : the non-monotonic Sobol g-function

    # The method of sobol requires 2 samples
    # There are 8 factors, all following the uniform distribution
    # on [0,1]

    library(boot)
    n <- 1000
    X1 <- data.frame(matrix(runif(8 * n), nrow = n))
    X2 <- data.frame(matrix(runif(8 * n), nrow = n))

    # sensitivity analysis

    x <- soboljansen(model = sobol.fun, X1, X2, nboot = 100)
    print(x)
    plot(x)

    library(ggplot2)
    ggplot(x)


    # Only for demonstration purposes: a model function returning a matrix
    sobol.fun_matrix <- function(X){
      res_vector <- sobol.fun(X)
      cbind(res_vector, 2 * res_vector)
    }
    x_matrix <- soboljansen(model = sobol.fun_matrix, X1, X2)
    plot(x_matrix, y_col = 2)
    title(main = "y_col = 2")

    # Also only for demonstration purposes: a model function returning a
    # three-dimensional array
    sobol.fun_array <- function(X){
      res_vector <- sobol.fun(X)
      res_matrix <- cbind(res_vector, 2 * res_vector)
      array(data = c(res_matrix, 5 * res_matrix), 
            dim = c(length(res_vector), 2, 2))
    }
    x_array <- soboljansen(model = sobol.fun_array, X1, X2)
    plot(x_array, y_col = 2, y_dim3 = 2)
    title(main = "y_col = 2, y_dim3 = 2")
}

test_48 <- function() {
    # Test case : the non-monotonic Sobol g-function

    # The method of sobolmara requires 1 sample
    # (there are 8 factors, all following the uniform distribution on [0,1])
    n <- 1000
    X1 <- data.frame(matrix(runif(8 * n), nrow = n))

    # sensitivity analysis
    x <- sobolmara(model = sobol.fun, X1 = X1)
    print(x)
    plot(x)

    library(ggplot2)
    ggplot(x)
}

test_49 <- function() {
    # Test case : the non-monotonic Sobol g-function

    # The method of sobol requires 2 samples
    # There are 8 factors, all following the uniform distribution
    # on [0,1]

    library(boot)
    n <- 1000
    X1 <- data.frame(matrix(runif(8 * n), nrow = n))
    X2 <- data.frame(matrix(runif(8 * n), nrow = n))

    # sensitivity analysis

    x <- sobolmartinez(model = sobol.fun, X1, X2, nboot = 0)
    print(x)
    plot(x)

    library(ggplot2)
    ggplot(x)


    # Only for demonstration purposes: a model function returning a matrix
    sobol.fun_matrix <- function(X){
      res_vector <- sobol.fun(X)
      cbind(res_vector, 2 * res_vector)
    }
    x_matrix <- sobolmartinez(model = sobol.fun_matrix, X1, X2)
    plot(x_matrix, y_col = 2)
    title(main = "y_col = 2")

    # Also only for demonstration purposes: a model function returning a
    # three-dimensional array
    sobol.fun_array <- function(X){
      res_vector <- sobol.fun(X)
      res_matrix <- cbind(res_vector, 2 * res_vector)
      array(data = c(res_matrix, 5 * res_matrix), 
            dim = c(length(res_vector), 2, 2))
    }
    x_array <- sobolmartinez(model = sobol.fun_array, X1, X2)
    plot(x_array, y_col = 2, y_dim3 = 2)
    title(main = "y_col = 2, y_dim3 = 2")
}

test_50 <- function() {
    # Test case : the non-monotonic Sobol g-function

    # The method of sobolowen requires 3 samples
    # There are 8 factors, all following the uniform distribution
    # on [0,1]

    library(boot)
    n <- 1000
    X1 <- data.frame(matrix(runif(8 * n), nrow = n))
    X2 <- data.frame(matrix(runif(8 * n), nrow = n))
    X3 <- data.frame(matrix(runif(8 * n), nrow = n))

    # sensitivity analysis


    x <- sobolowen(model = sobol.fun, X1, X2, X3, nboot = 10) # put nboot=100
    print(x)
    plot(x)

    library(ggplot2)
    ggplot(x)
}

test_51 <- function() {
    # Test case : the non-monotonic Sobol g-function
    # Example with a call to a numerical model
    library(boot)
    n <- 1000
    X <- data.frame(matrix(runif(8 * n), nrow = n))
    x <- sobolrank(model = sobol.fun, X = X, nboot = 100)
    print(x)
    library(ggplot2)
    ggplot(x)
    # Test case : the Ishigami function
    # Example with given data
    n <- 500
    X <- data.frame(matrix(-pi+2*pi*runif(3 * n), nrow = n))
    Y <- ishigami.fun(X)
    x <- sobolrank(model = NULL, X)
    tell(x,Y)
    print(x)
    ggplot(x)
}

test_52 <- function() {
	
    # Test case: the non-monotonic Sobol g-function

    # The method of sobol requires 2 samples
    # (there are 8 factors, all following the uniform distribution on [0,1])

    # first-order indices estimation
    x <- sobolrec(model = sobol.fun, factors = 8, layers=rep(2,each=15), order=1,
                  precision = c(5*10^(-2),2), method=NULL, tail=TRUE)
    print(x)

    # closed second-order indices estimation
    x <- sobolrec(model = sobol.fun, factors = 8, layers=11^2, order=2,
                  precision = c(10^(-2),3), method="al", tail=TRUE)
    print(x)


    # Test case: dealing with external model 
    # put in comment because of bug with ask use !

    #x <- sobolrec(model = NULL, factors = 8, layers=rep(2,each=15), order=1,
    #              precision = c(5*10^(-2),2), method=NULL, tail=TRUE)
    #toy <- sobol.fun
    #k <- 1
    #stop_crit <- FALSE
    #while(!(stop_crit) & (k<length(x$layers))){
    #  ask(x, index=k)
    #  y <- toy(x$block)
    #  tell(x, y, index=k)
    #  stop_crit <- x$stop_crit
    #  k <- k+1
    #}
    #print(x)
}

test_53 <- function() {
    # Test case: the non-monotonic Sobol g-function

    # The method of sobol requires 2 samples
    # (there are 8 factors, all following the uniform distribution on [0,1])

    x <- sobolrep(model = sobol.fun, factors = 8, N = 1000, nboot=100, nbrep=1, total=FALSE)
    print(x)
    plot(x,choice=1)
    plot(x,choice=2)

    # Test case: dealing with non-uniform distributions

    x <- sobolrep(model = NULL, factors = 3, N = 1000, nboot=0, nbrep=1, total=FALSE)

    # X1 follows a log-normal distribution:
    x$X[,1] <- qlnorm(x$X[,1])

    # X2 follows a standard normal distribution:
    x$X[,2] <- qnorm(x$X[,2])

    # X3 follows a gamma distribution:
    x$X[,3] <- qgamma(x$X[,3],shape=0.5)

    # toy example
    toy <- function(x){rowSums(x)}
    y <- toy(x$X)
    tell(x, y)
    print(x)
    plot(x,choice=1)
    plot(x,choice=2)
}

test_54 <- function() {
    library(boot)
    library(numbers)

    ####################
    # Test case: the non-monotonic Sobol g-function

    # The method of sobol requires 2 samples
    # (there are 8 factors, all following the uniform distribution on [0,1])

    # first-order sensitivity indices
    x <- sobolroalhs(model = sobol.fun, factors = 8, N = 1000, order = 1, nboot=100)
    print(x)
    plot(x)

    library(ggplot2)
    ggplot(x)

    # closed second-order sensitivity indices
    x <- sobolroalhs(model = sobol.fun, factors = 8, N = 1000, order = 2, nboot=100)
    print(x)
    ggplot(x)

    ####################
    # Test case: dealing with non-uniform distributions

    x <- sobolroalhs(model = NULL, factors = 3, N = 1000, order =1, nboot=0)

    # X1 follows a log-normal distribution:
    x$X[,1] <- qlnorm(x$X[,1])

    # X2 follows a standard normal distribution:
    x$X[,2] <- qnorm(x$X[,2])

    # X3 follows a gamma distribution:
    x$X[,3] <- qgamma(x$X[,3],shape=0.5)

    # toy example
    toy <- function(x){rowSums(x)}
    y <- toy(x$X)
    tell(x, y)
    print(x)
    ggplot(x)

    ####################
    # Test case : multidimensional outputs


    toy <- function(x){cbind(x[,1]+x[,2]+x[,1]*x[,2],2*x[,1]+3*x[,1]*x[,2]+x[,2])}
    x <- sobolroalhs(model = toy, factors = 3, N = 1000, p=2, order =1, nboot=100)
    print(x)
    ggplot(x)
}

test_55 <- function() {
    library(boot)
    library(numbers)

    # Test case: the non-monotonic Sobol g-function
    # (there are 8 factors, all following the uniform distribution on [0,1])

    # Suppose we have the inequality constraints: X1 <= X3 and X4 <= X6.

    # first-order sensitivity indices
    x <- sobolroauc(model = sobol.fun, factors = 8, constraints = list(c(1,3),c(4,6)), 
                    N = 1000, order = 1, nboot=100)
    print(x)
    plot(x)

    library(ggplot2)
    ggplot(x)

    # closed second-order sensitivity indices
    x <- sobolroauc(model = sobol.fun, factors = 8, constraints = list(c(1,3),c(4,6)), 
                    N = 1000, order = 2, nboot=100)
    print(x)
    ggplot(x)
}

test_56 <- function() {
  
        # Test case: the non-monotonic Sobol g-function
        # Example with a call to a numerical model
        # First compute first-order indices with ranking
        n <- 1000
        X <- data.frame(matrix(runif(8 * n), nrow = n))
        x <- sobolshap_knn(model = sobol.fun, X = X, U = 1, method = "rank")
        print(x)
        library(ggplot2)
        ggplot(x)
        # We can use the output sample generated for this estimation to compute 
        # total indices without additional calls to the model
        x2 <- sobolshap_knn(model = NULL, X = X, U = 0, method = "knn", n.knn = 5)
        tell(x2,x$y)
        ggplot(x2)
    
        # Test case: the Ishigami function
        # Example with given data and the use of approximate nearest neighbour search
        library(RANN)
        n <- 5000
        X <- data.frame(matrix(-pi+2*pi*runif(3 * n), nrow = n))
        Y <- ishigami.fun(X)
        x <- sobolshap_knn(model = NULL, X = X, U = NULL, method = "knn", n.knn = 5, 
                           return.shap = TRUE, n.limit = 2000)
        tell(x,Y)
        library(ggplot2)
        ggplot(x)
        # We can also extract first-order and total Sobol indices
        x1 <- extract(x)
        print(x1)
    
        # Test case : Linear model (3 Gaussian inputs including 2 dependent) with scaling
        # See Iooss and Prieur (2019)
        library(mvtnorm) # Multivariate Gaussian variables
        library(whitening) # For scaling
        modlin <- function(X) apply(X,1,sum)
        d <- 3
        n <- 10000
        mu <- rep(0,d)
        sig <- c(1,1,2)
        ro <- 0.9
        Cormat <- matrix(c(1,0,0,0,1,ro,0,ro,1),d,d)
        Covmat <- ( sig %*% t(sig) ) * Cormat
        Xall <- function(n) mvtnorm::rmvnorm(n,mu,Covmat)
        X <- Xall(n)
        x <- sobolshap_knn(model = modlin, X = X, U = NULL, method = "knn", n.knn = 5, 
                           return.shap = TRUE, rescale = TRUE, n.limit = 2000)
        print(x)
    
        # Test case: functional toy fct 'Arctangent temporal function'
        n <- 3000
        X <- data.frame(matrix(runif(2*n,-7,7), nrow = n))
        Y <- atantemp.fun(X)
        x <- sobolshap_knn(model = NULL, X = X, U = NULL, method = "knn", n.knn = 5, 
                           return.shap = TRUE, n.limit = 2000)
        tell(x,Y)
        library(ggplot2)
        library(reshape2)
        ggplot(x, type.multout="lines")
}

test_57 <- function() {
    # Test case : the non-monotonic Sobol g-function

    # The method of sobol requires 2 samples
    # There are 8 factors, all following the uniform distribution
    # on [0,1]

    library(boot)
    n <- 1000
    X1 <- data.frame(matrix(runif(8 * n), nrow = n))
    X2 <- data.frame(matrix(runif(8 * n), nrow = n))

    # sensitivity analysis

    x <- soboltouati(model = sobol.fun, X1, X2)
    print(x)
    plot(x)

    library(ggplot2)
    ggplot(x)
}

test_58 <- function() {
    n <- 100  # sample size
    nsim <- 100 # number of simulations
    mu <- 0

    T <- Tunb <- rep(NA, nsim)
    theta <- mu^2  # E(X)^2, with X following N(mu, 1)

    for (i in 1:nsim){
      x <- rnorm(n, mean = mu, sd = 1)
      T[i] <- squaredIntEstim(x, method = "biased")
      Tunb[i] <- squaredIntEstim(x, method = "unbiased")
    }

    par(mfrow = c(1, 1))
    boxplot(cbind(T, Tunb))
    abline(h = theta, col = "red")
    abline(h = c(mean(T), mean(Tunb)), col = c("blue", "cyan"), lty = "dotted")
    # look at the difference between median and mean
}

test_59 <- function() {

    # a 100-sample with X1 ~ U(0.5, 1.5)
    #                   X2 ~ U(1.5, 4.5)
    #                   X3 ~ U(4.5, 13.5)

    library(boot)
    n <- 100
    X <- data.frame(X1 = runif(n, 0.5, 1.5),
                    X2 = runif(n, 1.5, 4.5),
                    X3 = runif(n, 4.5, 13.5))

    # linear model : Y = X1 + X2 + X3

    y <- with(X, X1 + X2 + X3)

    # sensitivity analysis

    x <- src(X, y, nboot = 100)
    print(x)
    plot(x)

    library(ggplot2)
    ggplot(x)
}

test_60 <- function() {


    # -----------------
    # ishigami function
    # -----------------
    n <- 5000
    n.points <- 1000
    d <- 3

    set.seed(0)
    X <- matrix(runif(d*n, min = -pi, max = pi), n, d)
    Xnew <- matrix(seq(from = -pi, to = pi, length=n.points), n.points, d)

    b <- support(model = ishigami.fun, X, Xnew)

    # plot method (x-axis in probability scale), of the normalized support index functions
    plot(b, col = c("lightskyblue4", "lightskyblue1", "black"), 
         xprob = TRUE, p = 'punif', p.arg = list(min = -pi, max = pi), ylim = c(0, 2))

    # below : diagonal scatterplots of the gradient, 
    # on which are based the estimation by smoothing
    scatterplot(b, xprob = TRUE) 

    # now with normal margins
    # -----------------------
    X <- matrix(rnorm(d*n), n, d)
    Xnew <- matrix(rnorm(d*n.points), n.points, d)
    b <- support(model = ishigami.fun, X, Xnew)

    plot(b, col = c("lightskyblue4", "lightskyblue1", "black"), xprob = FALSE)
    scatterplot(b, xprob = FALSE, type = "histogram", bins = 10, cex = 1, cex.lab = 1.5)
}

test_61 <- function() {
    txt <- c("Hello $(name)!", "$(a) + $(b) = @{$(a)+$(b)}",
             "pi = @{format(pi,digits=5)}")
    replacement <- list(name = "world", a = 1, b = 2)
    # 1. without code evaluation:
    txt.rpl1 <- template.replace(txt, replacement)
    print(txt.rpl1)
    # 2. with code evalutation:
    txt.rpl2 <- template.replace(txt, replacement, eval = TRUE)
    print(txt.rpl2)
}

test_62 <- function() {
  
    # Test case: the Matyas function.

    n <- 300  # nb of samples
    p <- 3    # nb of input variables (including 1 dummy variable)

    ########################################
    ### PRELIMINARY SENSITIVITY ANALYSIS ###
    ########################################

    X <- matrix(runif(n*p), n, p)
    sensi <- sensiHSIC(model=matyas.fun, X, 
                       kernelX="sobolev1", anova=list(obj="both", is.uniform=TRUE))
    print(sensi)
    plot(sensi)
    title("GSA for the Matyas function")

    #############################
    ### TESTS OF INDEPENDENCE ###
    #############################

    ### HSIC indices ###

    test.asymp <- testHSIC(sensi)

    test.perm <- testHSIC(sensi, test.method="Permutation")

    test.seq.screening <- testHSIC(sensi, test.method="Seq_Permutation")

    test.seq.ranking <- testHSIC(sensi, test.method="Seq_Permutation", 
                                 seq.options=list(criterion="ranking"))

    test.seq.both <- testHSIC(sensi, test.method="Seq_Permutation", 
                              seq.options=list(criterion="both"))

    test.gamma <- testHSIC(sensi, test.method="Gamma")

    # comparison of p-values

    res <- rbind( t(as.matrix(test.asymp$pval)), t(as.matrix(test.perm$pval)), 
                  t(as.matrix(test.seq.screening$pval)), t(as.matrix(test.seq.ranking$pval)),
                  t(as.matrix(test.seq.both$pval)), t(as.matrix(test.gamma$pval)) )

    rownames(res) <- c("asymp", "perm", "seq_perm_screening", 
                       "seq_perm_ranking", "seq_perm_both", "gamma")
    res

    ### total-order HSIC-ANOVA indices ###

    test.tot.perm <- testHSIC(sensi, test.method="Tot_Permutation")

    test.tot.seq.screening <- testHSIC(sensi, test.method="Tot_Seq_Permutation")

    test.tot.seq.ranking <- testHSIC(sensi, test.method="Tot_Seq_Permutation", 
                                 seq.options=list(criterion="ranking"))

    test.tot.seq.both <- testHSIC(sensi, test.method="Tot_Seq_Permutation", 
                              seq.options=list(criterion="both"))

    test.tot.gamma <- testHSIC(sensi, test.method="Tot_Gamma")

    res <- rbind( t(as.matrix(test.tot.perm$pval)), 
                  t(as.matrix(test.tot.seq.screening$pval)), 
                  t(as.matrix(test.tot.seq.ranking$pval)),
                  t(as.matrix(test.tot.seq.both$pval)), 
                  t(as.matrix(test.tot.gamma$pval)) )

    rownames(res) <- c("tot_perm", "tot_seq_perm_screening", 
                       "tot_seq_perm_ranking", "tot_seq_perm_both", "tot_gamma")
    res

    #####################
    ### VISUALIZATION ###
    #####################

    # simulated values of HSIC indices under H0 (random permutations)
    Hperm <- t(unname(test.perm$Hperm))

    # simulated values of total-order HSIC-ANOVA indices under H0 (random permutations)
    tot.Hperm <- t(unname(test.tot.perm$Hperm))

    for(i in 1:p){
  
      ttl <- paste0("First-order and total-order HSIC-ANOVA indices for X", i)
  
      ######################################
      ### FIRST-ORDER HSIC-ANOVA INDICES ###
      ######################################
  
      # histogram of the test statistic under H0 (random permutations)
  
      hist(Hperm[,i], probability=TRUE,
           nclass=70, main=ttl, xlab="", ylab="", col="cyan")
  
      xx <- seq(0, max(tot.Hperm[,i]), length.out=200)
  
      # asymptotic Gamma distribution
  
      shape.asymp <- test.asymp$param[i, "shape"]
      scale.asymp <- test.asymp$param[i, "scale"]
  
      dens.asymp <- dgamma(xx, shape=shape.asymp, scale=scale.asymp)
  
      lines(xx, dens.asymp, lwd=2, col="darkorchid")
  
      # finite-sample Gamma distribution
  
      shape.perm <- test.gamma$param[i, "shape"]
      scale.perm <- test.gamma$param[i, "scale"]
  
      dens.perm <- dgamma(xx, shape=shape.perm, scale=scale.perm)
  
      lines(xx, dens.perm, lwd=2, col="blue")
  
      ######################################
      ### TOTAL-ORDER HSIC-ANOVA INDICES ###
      ######################################
  
      # histogram of the test statistic under H0 (random permutations)
  
      hist(tot.Hperm[,i], probability=TRUE, add=TRUE,
           nclass=70, xlab="", ylab="", col="deeppink")
  
      # finite-sample Gamma distribution
  
      shape.tot.perm <- test.tot.gamma$param[i, "shape"]
      scale.tot.perm <- test.tot.gamma$param[i, "scale"]
  
      dens.tot.perm <- dgamma(xx, shape=shape.tot.perm, scale=scale.tot.perm)
  
      lines(xx, dens.tot.perm, lwd=2, col="red")
  
      ### legend ###
  
      txt.1 <- paste0("Histogram of HSIC(X", i, ",Y)")
      txt.11 <- "Asymptotic Gamma distribution"
      txt.12 <- "Finite-sample Gamma distribution"
  
      txt.2 <- paste0("Histogram of T", i, " = HSIC(X,Y) - HSIC(X", 
                      paste(setdiff(1:p, i), collapse=""), ",Y)")
      txt.21 <- "Finite-sample Gamma distribution"
  
      all.cap <- c(txt.1, txt.11, txt.12, txt.2, txt.21)
      all.col <- c("cyan", "darkorchid", "blue", "deeppink", "red")
      all.lwd <- c(7, 2, 2, 7, 2)
  
      legend("topright", legend=all.cap, col=all.col, lwd=all.lwd, y.intersp=1.3)

    }
}

test_63 <- function() {


    # Examples for the functional toy fonctions

    # atantemp function

    y0 <- atantemp.fun(matrix(c(-7,0,7,-7,0,7),ncol=2))
    plot(y0[1,],type="l")
    apply(y0,1,lines)

    n <- 100
    X <- matrix(c(runif(2*n,-7,7)),ncol=2)
    y <- atantemp.fun(X)
    plot(y0[2,],ylim=c(-2,2),type="l")
    apply(y,1,lines)

    # campbell1D function

    N1=100         # nombre de simulations pour courbes 1D
    min=-1 ; max=5
    nominal=(max+min)/2

    X1 = NULL ; y1 = NULL
    Xnom=matrix(nominal,nr=1,nc=4)
    ynom=campbell1D.fun(Xnom,theta=-90:90)
    plot(ynom,ylim=c(8,30),type="l",col="red")
    for (i in 1:N1){
      X=matrix(runif(4,min=min,max=max),nr=1,nc=4)
      rbind(X1,X)
      y=campbell1D.fun(X,theta=-90:90)
      rbind(y1,y)
      lines(y)
    }
}

test_64 <- function() {
    n <- 100  # sample size
    c <- 1.5
    Y <- rnorm(n)
    Yt <- weightTSA(Y, c)
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

