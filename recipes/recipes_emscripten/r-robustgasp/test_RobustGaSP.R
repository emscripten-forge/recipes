print('Loading RobustGaSP package')
library(RobustGaSP)
print('... RobustGaSP package loaded successfully')

test_1 <- function() {
      #------------------------
      # a 3 dimensional example
      #------------------------
      # dimensional of the inputs
      dim_inputs <- 3    
      # number of the inputs
      num_obs <- 30       
      # uniform samples of design
      input <- matrix(runif(num_obs*dim_inputs), num_obs,dim_inputs) 
  
      # Following codes use maximin Latin Hypercube Design, which is typically better than uniform
      # library(lhs)
      # input <- maximinLHS(n=num_obs, k=dim_inputs)  ##maximin lhd sample
  
      ####
      # outputs from the 3 dim dettepepel.3.data function
  
      output = matrix(0,num_obs,1)
      for(i in 1:num_obs){
        output[i]<-dettepepel.3.data(input[i,])
      }
  
      # use constant mean basis, with no constraint on optimization
      m1<- rgasp(design = input, response = output, lower_bound=FALSE)
  
      # the following use constraints on optimization
      # m1<- rgasp(design = input, response = output, lower_bound=TRUE)
  
      # the following use a single start on optimization
      # m1<- rgasp(design = input, response = output, lower_bound=FALSE)
  
      # number of points to be predicted 
      num_testing_input <- 5000    
      # generate points to be predicted
      testing_input <- matrix(runif(num_testing_input*dim_inputs),num_testing_input,dim_inputs)
      # Perform prediction
      m1.predict<-predict(m1, testing_input, outasS3 = FALSE)
      # Predictive mean
      #m1.predict@mean  
  
      # The following tests how good the prediction is 
      testing_output <- matrix(0,num_testing_input,1)
      for(i in 1:num_testing_input){
        testing_output[i]<-dettepepel.3.data(testing_input[i,])
      }
  
      # compute the MSE, average coverage and average length
      # out of sample MSE
      MSE_emulator <- sum((m1.predict@mean-testing_output)^2)/(num_testing_input)  
  
      # proportion covered by 95% posterior predictive credible interval
      prop_emulator <- length(which((m1.predict@lower95<=testing_output)
                       &(m1.predict@upper95>=testing_output)))/num_testing_input
  
      # average length of  posterior predictive credible interval
      length_emulator <- sum(m1.predict@upper95-m1.predict@lower95)/num_testing_input
  
      # output of prediction
      MSE_emulator
      prop_emulator
      length_emulator  
      # normalized RMSE
      sqrt(MSE_emulator/mean((testing_output-mean(output))^2 ))
}

test_2 <- function() {
      #------------------------
      # a 1 dimensional example
      #------------------------
  
    ###########1dim higdon.1.data 
    p1 = 1     ###dimensional of the inputs
    dim_inputs1 <- p1
    n1 = 15   ###sample size or number of training computer runs you have 
    num_obs1 <- n1
    input1 = 10*matrix(runif(num_obs1*dim_inputs1), num_obs1,dim_inputs1) ##uniform
    #####lhs is better
    #library(lhs)
    #input1 = 10*maximinLHS(n=num_obs1, k=dim_inputs1)  ##maximin lhd sample
    output1 = matrix(0,num_obs1,1)
    for(i in 1:num_obs1){
      output1[i]=higdon.1.data (input1[i])
    }





    m1<- rgasp(design = input1, response = output1, lower_bound=FALSE)

    #####locations to samples
    testing_input1 = seq(0,10,1/50) 
    testing_input1=as.matrix(testing_input1)
    #####draw 10 samples
    m1_sample=Sample(m1,testing_input1,num_sample=10)

    #####plot these samples
    matplot(testing_input1,m1_sample, type='l',xlab='input',ylab='output')
    lines(input1,output1,type='p')
}

test_3 <- function() {
      #------------------------
      # a 3 dimensional example
      #------------------------
      # dimensional of the inputs
      dim_inputs <- 3    
      # number of the inputs
      num_obs <- 30       
      # uniform samples of design
      input <- matrix(runif(num_obs*dim_inputs), num_obs,dim_inputs) 
  
      # Following codes use maximin Latin Hypercube Design, which is typically better than uniform
      # library(lhs)
      # input <- maximinLHS(n=num_obs, k=dim_inputs)  ##maximin lhd sample
  
      # outputs from the 3 dim dettepepel.3.data function
  
      output = matrix(0,num_obs,1)
      for(i in 1:num_obs){
        output[i]<-dettepepel.3.data (input[i,])
      }
  
      # use constant mean basis, with no constraint on optimization
      m1<- rgasp(design = input, response = output, lower_bound=FALSE)
  
      # the following use constraints on optimization
      # m1<- rgasp(design = input, response = output, lower_bound=TRUE)
  
      # the following use a single start on optimization
      # m1<- rgasp(design = input, response = output, lower_bound=FALSE, multiple_starts=FALSE)
  
      # number of points to be predicted 
      num_testing_input <- 5000    
      # generate points to be predicted
      testing_input <- matrix(runif(num_testing_input*dim_inputs),num_testing_input,dim_inputs)
      # Perform prediction
      m1.predict<-predict(m1, testing_input, outasS3 = FALSE)
  
      # The returned object is of predrgasp-class
      str(m1.predict)
      # To have the prediction as a list
      m1.predict.aslist <- as.S3prediction(m1.predict)
      str(m1.predict.aslist)
}

test_4 <- function() {
      #------------------------
      # a 3 dimensional example
      #------------------------
      # dimensional of the inputs
      dim_inputs <- 3    
      # number of the inputs
      num_obs <- 30       
      # uniform samples of design
      input <- matrix(runif(num_obs*dim_inputs), num_obs,dim_inputs) 
  
      # Following codes use maximin Latin Hypercube Design, which is typically better than uniform
      # library(lhs)
      # input <- maximinLHS(n=num_obs, k=dim_inputs)  ##maximin lhd sample
  
      # outputs from the 3 dim dettepepel.3.data function
  
      output = matrix(0,num_obs,1)
      for(i in 1:num_obs){
        output[i]<-dettepepel.3.data (input[i,])
      }
  
      # use constant mean basis, with no constraint on optimization
      m1<- rgasp(design = input, response = output, lower_bound=FALSE)
  
      # the following use constraints on optimization
      # m1<- rgasp(design = input, response = output, lower_bound=TRUE)
  
      # the following use a single start on optimization
      # m1<- rgasp(design = input, response = output, lower_bound=FALSE, multiple_starts=FALSE)
  
      # number of points to be predicted 
      num_testing_input <- 5000    
      # generate points to be predicted
      testing_input <- matrix(runif(num_testing_input*dim_inputs),num_testing_input,dim_inputs)
      # Perform prediction
      m1.predict<-predict(m1, testing_input, outasS3 = FALSE)
      # Notice the call slot of the object
      print(m1.predict@call)
  
      # To convert the prediction to a S3 object 
      m1.predict.aslist <- as.S3prediction(m1.predict)
      # To recover back the prediction as a predrgasp-class object
      m1.predict.aspredgasp <- as.S4prediction.predict(m1.predict.aslist)
      str(m1.predict.aslist)
      # Notice that in this case the @call slot is different than the initial
      print(m1.predict.aspredgasp@call)
}

test_5 <- function() {
      # dimensional of the inputs
      dim_inputs <- 8    
  
      # number of the inputs
      num_obs <- 30       
  
      # uniform samples of design
      input <-matrix(runif(num_obs*dim_inputs), num_obs,dim_inputs) 

      # the Euclidean distance matrix 
      R0=euclidean_distance(input, input)
}

test_6 <- function() {
      #-----------------------------------------------
      # test for inert inputs in the Borehole function
      #-----------------------------------------------
    # dimensional of the inputs
    dim_inputs <- 8    
    # number of the inputs
    num_obs <- 40       

    # uniform samples of design
    set.seed(0)
    input <-matrix(runif(num_obs*dim_inputs), num_obs,dim_inputs) 
    # Following codes use maximin Latin Hypercube Design, which is typically better than uniform
    # library(lhs)
    # input <- maximinLHS(n=num_obs, k=dim_inputs)  # maximin lhd sample

    # rescale the design to the domain
    input[,1]<-0.05+(0.15-0.05)*input[,1];
    input[,2]<-100+(50000-100)*input[,2];
    input[,3]<-63070+(115600-63070)*input[,3];
    input[,4]<-990+(1110-990)*input[,4];
    input[,5]<-63.1+(116-63.1)*input[,5];
    input[,6]<-700+(820-700)*input[,6];
    input[,7]<-1120+(1680-1120)*input[,7];
    input[,8]<-9855+(12045-9855)*input[,8];

    # outputs from the 8 dim Borehole function

    output=matrix(0,num_obs,1)
    for(i in 1:num_obs){
      output[i]=borehole(input[i,])
    }





    # use constant mean basis with trend, with no constraint on optimization
    m3<- rgasp(design = input, response = output, lower_bound=FALSE)

    P=findInertInputs(m3)
}

test_7 <- function() {

    s <- seq(0,10,0.01)
    y <- higdon.1.data(s)
    plot(s,y, xlab='s',ylab='y',type='l',main='Higdon (2002) function')
}

test_8 <- function() {
    library(RobustGaSP)
     #------------------------
      # a 3 dimensional example
      #------------------------
      # dimensional of the inputs
      dim_inputs <- 3    
      # number of the inputs
      num_obs <- 30       
      # uniform samples of design
      input <- matrix(runif(num_obs*dim_inputs), num_obs,dim_inputs) 
  
      # Following codes use maximin Latin Hypercube Design, which is typically better than uniform
      # library(lhs)
      # input <- maximinLHS(n=num_obs, k=dim_inputs)  ##maximin lhd sample
  
      ####
      # outputs from the 3 dim dettepepel.3.data function
  
      output = matrix(0,num_obs,1)
      for(i in 1:num_obs){
        output[i]<-dettepepel.3.data (input[i,])
      }
  
      # use constant mean basis, with no constraint on optimization
      m1<- rgasp(design = input, response = output, lower_bound=FALSE)
  
      ##leave one out predict
      leave_one_out_m1=leave_one_out_rgasp(m1)
  
      ##predictive mean 
      leave_one_out_m1$mean
      ##standard deviation
      leave_one_out_m1$sd
      ##standardized error
      (leave_one_out_m1$mean-output)/leave_one_out_m1$sd
}

test_9 <- function() {
    # inputs
    x<-runif(10);
    n<-length(x);

    # default prior parameters
    a<-0.2
    b<-n^{-1}*(a+1)
    R0<-as.matrix(abs(outer(x,x, "-")))
    CL<- mean(R0[which(R0>0)])

    # compute the density of log reference prior up to a normalizing constant
    param <- seq(-10,10,0.01)
    prior <- rep(0,length(param))
    for(i in 1:length(param)){
      prior[i] <- exp(log_approx_ref_prior(param[i],nugget=0,nugget_est=FALSE,CL,a,b) )
    }
    # plot
    plot(param,prior,type='l',
                    xlab='Logarithm of inverse range parameters',
                    ylab='Prior density up to a normalizing constant')
}

test_10 <- function() {
     library(RobustGaSP)
      #------------------------
      # a 3 dimensional example
      #------------------------
      # dimensional of the inputs
      dim_inputs <- 3    
      # number of the inputs
      num_obs <- 30       
      # uniform samples of design
      input <- matrix(runif(num_obs*dim_inputs), num_obs,dim_inputs) 
  
      # Following codes use maximin Latin Hypercube Design, which is typically better than uniform
      # library(lhs)
      # input <- maximinLHS(n=num_obs, k=dim_inputs)  ##maximin lhd sample
  
      # outputs from the 3 dim dettepepel.3.data function
  
      output = matrix(0,num_obs,1)
      for(i in 1:num_obs){
        output[i]<-dettepepel.3.data (input[i,])
      }
  
      # use constant mean basis, with no constraint on optimization
      m1<- rgasp(design = input, response = output, lower_bound=FALSE)
 
      # plot
      plot(m1)
}

test_11 <- function() {
      library(RobustGaSP)
      #----------------------------------
      # an example of environmental model
      #----------------------------------
  
      set.seed(1)
      #Here the sample size is very small. Consider to use more observations 
      n=80
      p=4
      ##using the latin hypercube will be better
      #library(lhs)
      #input_samples=maximinLHS(n,p)
      input_samples=matrix(runif(n*p),n,p)
      input=matrix(0,n,p)
      input[,1]=7+input_samples[,1]*6
      input[,2]=0.02+input_samples[,2]*1
      input[,3]=0.01+input_samples[,3]*2.99
      input[,4]=30.01+input_samples[,4]*0.285
  
      k=300
      output=matrix(0,n,k)
      ##environ.4.data is an environmental model on a spatial-time vector
      ##? environ.4.data
      for(i in 1:n){
        output[i,]=environ.4.data(input[i,],s=seq(0.15,3,0.15),t=seq(4,60,4)  )
      }
  
      ##samples some test inputs
      n_star=1000
      sample_unif=matrix(runif(n_star*p),n_star,p)
  
      testing_input=matrix(0,n_star,p)
      testing_input[,1]=7+sample_unif[,1]*6
      testing_input[,2]=0.02+sample_unif[,2]*1
      testing_input[,3]=0.01+sample_unif[,3]*2.99
      testing_input[,4]=30.01+sample_unif[,4]*0.285
  
  
      testing_output=matrix(0,n_star,k)
  
      s=seq(0.15,3,0.15)
      t=seq(4,60,4) 
  
      for(i in 1:n_star){
        testing_output[i,]=environ.4.data(testing_input[i,],s=s,t=t )
      }
  
      ##we do a transformation of the output 
      ##one can change the number of initial values to test
      log_output_1=log(output+1)
      #since we have lots of output, we use 'nelder-mead' for optimization
      m.ppgasp=ppgasp(design=input,response=log_output_1,kernel_type
                      ='pow_exp',num_initial_values=2,optimization='nelder-mead')
  
      m_pred.ppgasp=predict(m.ppgasp,testing_input)
      ##we transform back for the prediction
      m_pred_ppgasp_median=exp(m_pred.ppgasp$mean)-1
      ##mean squared error
      mean( (m_pred_ppgasp_median-testing_output)^2)
      ##variance of the testing outputs
      var(as.numeric(testing_output))
  
      ##makes plots for the testing 
      par(mfrow=c(1,2))
      testing_plot_1=matrix(testing_output[1,],  length(t), length(s) )
  
      max_testing_plot_1=max(testing_plot_1)
      min_testing_plot_1=min(testing_plot_1)
  
      image(x=t,y=s,testing_plot_1,  col = hcl.colors(100, "terrain"),main='test outputs')
      contour(x=t,y=s,testing_plot_1, levels = seq(min_testing_plot_1, max_testing_plot_1,
                                                   by = (max_testing_plot_1-min_testing_plot_1)/5),
              add = TRUE, col = "brown")
  
      ppgasp_plot_1=matrix(m_pred_ppgasp_median[1,],  length(t), length(s) )
      max_ppgasp_plot_1=max(ppgasp_plot_1)
      min_ppgasp_plot_1=min(ppgasp_plot_1)
  
      image(x=t,y=s,ppgasp_plot_1,  col = hcl.colors(100, "terrain"),main='prediction')
      contour(x=t,y=s,ppgasp_plot_1, levels = seq(min_testing_plot_1, max_ppgasp_plot_1,
                                                  by = (max_ppgasp_plot_1-min_ppgasp_plot_1)/5),
              add = TRUE, col = "brown")
      dev.off()
}

test_12 <- function() {
      #------------------------
      # a 3 dimensional example
      #------------------------
      # dimensional of the inputs
      dim_inputs <- 3    
      # number of the inputs
      num_obs <- 30       
      # uniform samples of design
      input <- matrix(runif(num_obs*dim_inputs), num_obs,dim_inputs) 
  
      # Following codes use maximin Latin Hypercube Design, which is typically better than uniform
      # library(lhs)
      # input <- maximinLHS(n=num_obs, k=dim_inputs)  ##maximin lhd sample
  
      # outputs from the 3 dim dettepepel.3.data function
  
      output = matrix(0,num_obs,1)
      for(i in 1:num_obs){
        output[i]<-dettepepel.3.data (input[i,])
      }
  
      # use constant mean basis, with no constraint on optimization
      m1<- rgasp(design = input, response = output, lower_bound=FALSE)
  
      # the following use constraints on optimization
      # m1<- rgasp(design = input, response = output, lower_bound=TRUE)
  
      # the following use a single start on optimization
      # m1<- rgasp(design = input, response = output, lower_bound=FALS)
  
      # number of points to be predicted 
      num_testing_input <- 5000    
      # generate points to be predicted
      testing_input <- matrix(runif(num_testing_input*dim_inputs),num_testing_input,dim_inputs)
      # Perform prediction
      m1.predict<-predict(m1, testing_input)
      # Predictive mean
      # m1.predict$mean  
  
      # The following tests how good the prediction is 
      testing_output <- matrix(0,num_testing_input,1)
      for(i in 1:num_testing_input){
        testing_output[i]<-dettepepel.3.data(testing_input[i,])
      }
  
      # compute the MSE, average coverage and average length
      # out of sample MSE
      MSE_emulator <- sum((m1.predict$mean-testing_output)^2)/(num_testing_input)  
  
      # proportion covered by 95% posterior predictive credible interval
      prop_emulator <- length(which((m1.predict$lower95<=testing_output)
                       &(m1.predict$upper95>=testing_output)))/num_testing_input
  
      # average length of  posterior predictive credible interval
      length_emulator <- sum(m1.predict$upper95-m1.predict$lower95)/num_testing_input
  
      # output of prediction
      MSE_emulator
      prop_emulator
      length_emulator  
      # normalized RMSE
      sqrt(MSE_emulator/mean((testing_output-mean(output))^2 ))


      #-----------------------------------
      # a 2 dimensional example with trend
      #-----------------------------------
      # dimensional of the inputs
      dim_inputs <- 2    
      # number of the inputs
      num_obs <- 20       
  
      # uniform samples of design
      input <-matrix(runif(num_obs*dim_inputs), num_obs,dim_inputs) 
      # Following codes use maximin Latin Hypercube Design, which is typically better than uniform
      # library(lhs)
      # input <- maximinLHS(n=num_obs, k=dim_inputs)  ##maximin lhd sample
  
      # outputs from the 2 dim Brainin function
  
      output <- matrix(0,num_obs,1)
      for(i in 1:num_obs){
        output[i]<-limetal.2.data (input[i,])
      }
  
      #mean basis (trend)
      X<-cbind(rep(1,num_obs), input )
  
  
      # use constant mean basis with trend, with no constraint on optimization
      m2<- rgasp(design = input, response = output,trend =X,  lower_bound=FALSE)
  
  
      # number of points to be predicted 
      num_testing_input <- 5000    
      # generate points to be predicted
      testing_input <- matrix(runif(num_testing_input*dim_inputs),num_testing_input,dim_inputs)
  
      # trend of testing
      testing_X<-cbind(rep(1,num_testing_input), testing_input )
  
  
      # Perform prediction
      m2.predict<-predict(m2, testing_input,testing_trend=testing_X)
      # Predictive mean
      #m2.predict$mean  
  
      # The following tests how good the prediction is 
      testing_output <- matrix(0,num_testing_input,1)
      for(i in 1:num_testing_input){
        testing_output[i]<-limetal.2.data(testing_input[i,])
      }
  
      # compute the MSE, average coverage and average length
      # out of sample MSE
      MSE_emulator <- sum((m2.predict$mean-testing_output)^2)/(num_testing_input)  
  
      # proportion covered by 95% posterior predictive credible interval
      prop_emulator <- length(which((m2.predict$lower95<=testing_output)
                       &(m2.predict$upper95>=testing_output)))/num_testing_input
  
      # average length of  posterior predictive credible interval
      length_emulator <- sum(m2.predict$upper95-m2.predict$lower95)/num_testing_input
  
      # output of prediction
      MSE_emulator
      prop_emulator
      length_emulator  
      # normalized RMSE
      sqrt(MSE_emulator/mean((testing_output-mean(output))^2 ))


        ###here try the isotropic kernel (a function of Euclidean distance)
      m2_isotropic<- rgasp(design = input, response = output,trend =X,  
                 lower_bound=FALSE,isotropic=TRUE)
  
      m2_isotropic.predict<-predict(m2_isotropic, testing_input,testing_trend=testing_X)
  
      # compute the MSE, average coverage and average length
      # out of sample MSE
      MSE_emulator_isotropic <- sum((m2_isotropic.predict$mean-testing_output)^2)/(num_testing_input)
  
      # proportion covered by 95% posterior predictive credible interval
      prop_emulator_isotropic <- length(which((m2_isotropic.predict$lower95<=testing_output)
                                    &(m2_isotropic.predict$upper95>=testing_output)))/num_testing_input
  
      # average length of  posterior predictive credible interval
      length_emulator_isotropic <- sum(m2_isotropic.predict$upper95-
      m2_isotropic.predict$lower95)/num_testing_input
  
      MSE_emulator_isotropic
      prop_emulator_isotropic
      length_emulator_isotropic
      ##the result of isotropic kernel is not as good as the product kernel for this example


      #--------------------------------------------------------------------------------------
      # an 8 dimensional example using only a subset inputs and a noise with unknown variance
      #--------------------------------------------------------------------------------------
      set.seed(1)
      # dimensional of the inputs
      dim_inputs <- 8    
      # number of the inputs
      num_obs <- 50       
  
      # uniform samples of design
      input <-matrix(runif(num_obs*dim_inputs), num_obs,dim_inputs) 
      # Following codes use maximin Latin Hypercube Design, which is typically better than uniform
      # library(lhs)
      # input <- maximinLHS(n=num_obs, k=dim_inputs)  # maximin lhd sample
  
      # rescale the design to the domain
      input[,1]<-0.05+(0.15-0.05)*input[,1];
      input[,2]<-100+(50000-100)*input[,2];
      input[,3]<-63070+(115600-63070)*input[,3];
      input[,4]<-990+(1110-990)*input[,4];
      input[,5]<-63.1+(116-63.1)*input[,5];
      input[,6]<-700+(820-700)*input[,6];
      input[,7]<-1120+(1680-1120)*input[,7];
      input[,8]<-9855+(12045-9855)*input[,8];
  
      # outputs from the 8 dim Borehole function
  
      output=matrix(0,num_obs,1)
      for(i in 1:num_obs){
        output[i]=borehole(input[i,])
      }
  
  
    
    
  
      # use constant mean basis with trend, with no constraint on optimization
      m3<- rgasp(design = input[,c(1,4,6,7,8)], response = output,
                 nugget.est=TRUE, lower_bound=FALSE)
  
  
      # number of points to be predicted 
      num_testing_input <- 5000    
      # generate points to be predicted
      testing_input <- matrix(runif(num_testing_input*dim_inputs),num_testing_input,dim_inputs)
  
      # resale the points to the region to be predict
      testing_input[,1]<-0.05+(0.15-0.05)*testing_input[,1];
      testing_input[,2]<-100+(50000-100)*testing_input[,2];
      testing_input[,3]<-63070+(115600-63070)*testing_input[,3];
      testing_input[,4]<-990+(1110-990)*testing_input[,4];
      testing_input[,5]<-63.1+(116-63.1)*testing_input[,5];
      testing_input[,6]<-700+(820-700)*testing_input[,6];
      testing_input[,7]<-1120+(1680-1120)*testing_input[,7];
      testing_input[,8]<-9855+(12045-9855)*testing_input[,8];
  
  
      # Perform prediction
      m3.predict<-predict(m3, testing_input[,c(1,4,6,7,8)])
      # Predictive mean
      #m3.predict$mean  
  
      # The following tests how good the prediction is 
      testing_output <- matrix(0,num_testing_input,1)
      for(i in 1:num_testing_input){
        testing_output[i]<-borehole(testing_input[i,])
      }
  
      # compute the MSE, average coverage and average length
      # out of sample MSE
      MSE_emulator <- sum((m3.predict$mean-testing_output)^2)/(num_testing_input)  
  
      # proportion covered by 95% posterior predictive credible interval
      prop_emulator <- length(which((m3.predict$lower95<=testing_output)
                       &(m3.predict$upper95>=testing_output)))/num_testing_input
  
      # average length of  posterior predictive credible interval
      length_emulator <- sum(m3.predict$upper95-m3.predict$lower95)/num_testing_input
  
      # output of sample prediction
      MSE_emulator
      prop_emulator
      length_emulator  
      # normalized RMSE
      sqrt(MSE_emulator/mean((testing_output-mean(output))^2 ))
}

test_13 <- function() {
      library(RobustGaSP)
      #------------------------
      # a 3 dimensional example
      #------------------------
      # dimensional of the inputs
      dim_inputs <- 3    
      # number of the inputs
      num_obs <- 50       
      # uniform samples of design
      input <- matrix(runif(num_obs*dim_inputs), num_obs,dim_inputs) 
  
      # Following codes use maximin Latin Hypercube Design, which is typically better than uniform
      # library(lhs)
      # input <- maximinLHS(n=num_obs, k=dim_inputs)  ##maximin lhd sample
  
      ####
      # outputs from the 3 dim dettepepel.3.data function
  
      output = matrix(0,num_obs,1)
      for(i in 1:num_obs){
        output[i]<-dettepepel.3.data (input[i,])
      }
  
      # use constant mean basis, with no constraint on optimization
      # and marginal posterior mode estimation
      m1<- rgasp(design = input, response = output, lower_bound=FALSE)
  
      # you can use specify the estimation as maximum likelihood estimation (MLE)
      m2<- rgasp(design = input, response = output, method='mle',lower_bound=FALSE)
  
      ##let's do some comparison on prediction
      n_testing=1000
      testing_input=matrix(runif(n_testing*dim_inputs),n_testing,dim_inputs)
  
      m1_pred=predict(m1,testing_input=testing_input)
      m2_pred=predict(m2,testing_input=testing_input)
  
  
      ##root of mean square error and interval
      test_output = matrix(0,n_testing,1)
      for(i in 1:n_testing){
        test_output[i]<-dettepepel.3.data (testing_input[i,])
      }
  
      ##root of mean square error
      sqrt(mean( (m1_pred$mean-test_output)^2))
      sqrt(mean( (m2_pred$mean-test_output)^2))
      sd(test_output)
      #---------------------------------------
      # a 1 dimensional example with zero mean
      #---------------------------------------


      input=10*seq(0,1,1/14)
      output<-higdon.1.data(input)
      #the following code fit a GaSP with zero mean by setting zero.mean="Yes"
      model<- rgasp(design = input, response = output, zero.mean="Yes")
      model
  
      testing_input = as.matrix(seq(0,10,1/100))
      model.predict<-predict(model,testing_input)
      names(model.predict)
  
      #########plot predictive distribution
      testing_output=higdon.1.data(testing_input)
      plot(testing_input,model.predict$mean,type='l',col='blue',
           xlab='input',ylab='output')
      polygon( c(testing_input,rev(testing_input)),c(model.predict$lower95,
            rev(model.predict$upper95)),col =  "grey80", border = FALSE)
      lines(testing_input, testing_output)
      lines(testing_input,model.predict$mean,type='l',col='blue')
      lines(input, output,type='p')
  
      ## mean square erros
      mean((model.predict$mean-testing_output)^2)


      #-----------------------------------
      # a 2 dimensional example with trend
      #-----------------------------------
      # dimensional of the inputs
      dim_inputs <- 2    
      # number of the inputs
      num_obs <- 20       
  
      # uniform samples of design
      input <-matrix(runif(num_obs*dim_inputs), num_obs,dim_inputs) 
      # Following codes use maximin Latin Hypercube Design, which is typically better than uniform
      # library(lhs)
      # input <- maximinLHS(n=num_obs, k=dim_inputs)  # maximin lhd sample
  
      # outputs from a 2 dim function
  
      output <- matrix(0,num_obs,1)
      for(i in 1:num_obs){
        output[i]<-limetal.2.data (input[i,])
      }
  
      ####trend or mean basis
      X<-cbind(rep(1,num_obs), input )
  
  
      # use constant mean basis with trend, with no constraint on optimization
      m2<- rgasp(design = input, response = output,trend =X,  lower_bound=FALSE)

      show(m2)      # show this rgasp object 
  
      m2@beta_hat       # estimated inverse range parameters
      m2@theta_hat      # estimated trend parameters

      #--------------------------------------------------------------------------------------
      # an 8 dimensional example using only a subset inputs and a noise with unknown variance
      #--------------------------------------------------------------------------------------
      set.seed(1)
      # dimensional of the inputs
      dim_inputs <- 8    
      # number of the inputs
      num_obs <- 50       
  
      # uniform samples of design
      input <-matrix(runif(num_obs*dim_inputs), num_obs,dim_inputs) 
      # Following codes use maximin Latin Hypercube Design, which is typically better than uniform
      # library(lhs)
      # input <- maximinLHS(n=num_obs, k=dim_inputs)  # maximin lhd sample
  
      # rescale the design to the domain
      input[,1]<-0.05+(0.15-0.05)*input[,1];
      input[,2]<-100+(50000-100)*input[,2];
      input[,3]<-63070+(115600-63070)*input[,3];
      input[,4]<-990+(1110-990)*input[,4];
      input[,5]<-63.1+(116-63.1)*input[,5];
      input[,6]<-700+(820-700)*input[,6];
      input[,7]<-1120+(1680-1120)*input[,7];
      input[,8]<-9855+(12045-9855)*input[,8];
  
      # outputs from the 8 dim Borehole function
  
      output=matrix(0,num_obs,1)
      for(i in 1:num_obs){
        output[i]=borehole(input[i,])
      }
  
  
    
    
  
      # use constant mean basis with trend, with no constraint on optimization
      m3<- rgasp(design = input[,c(1,4,6,7,8)], response = output, 
                nugget.est=TRUE, lower_bound=FALSE)

      m3@beta_hat       # estimated inverse range parameters
      m3@nugget
}

test_14 <- function() {
      #------------------------
      # a 3 dimensional example
      #------------------------
      # dimensional of the inputs
      dim_inputs <- 3    
      # number of the inputs
      num_obs <- 30       
      # uniform samples of design
      input <- matrix(runif(num_obs*dim_inputs), num_obs,dim_inputs) 
  
      # Following codes use maximin Latin Hypercube Design, which is typically better than uniform
      # library(lhs)
      # input <- maximinLHS(n=num_obs, k=dim_inputs)  ##maximin lhd sample
  
      ####
      # outputs from the 3 dim dettepepel.3.data function
  
      output = matrix(0,num_obs,1)
      for(i in 1:num_obs){
        output[i]<-dettepepel.3.data (input[i,])
      }
  
      # use constant mean basis, with no constraint on optimization
      m1<- rgasp(design = input, response = output, lower_bound=FALSE)
  
      # the following use constraints on optimization
      # m1<- rgasp(design = input, response = output, lower_bound=TRUE)
  
      # the following use a single start on optimization
      # m1<- rgasp(design = input, response = output, lower_bound=FALSE)
  
  
      show(m1)
}

test_15 <- function() {

      library(RobustGaSP)
  
      ###PP GaSP model for the humanity model
      data(humanity_model)
      ##pp gasp
      m.ppgasp=ppgasp(design=humanity.X,response=humanity.Y,nugget.est= TRUE)
      show(m.ppgasp)
}

test_16 <- function() {
      #------------------------
      # a 1 dimensional example
      #------------------------
  
    ###########1dim higdon.1.data 
    p1 = 1     ###dimensional of the inputs
    dim_inputs1 <- p1
    n1 = 15   ###sample size or number of training computer runs you have 
    num_obs1 <- n1
    input1 = 10*matrix(runif(num_obs1*dim_inputs1), num_obs1,dim_inputs1) ##uniform
    #####lhs is better
    #library(lhs)
    #input1 = 10*maximinLHS(n=num_obs1, k=dim_inputs1)  ##maximin lhd sample
    output1 = matrix(0,num_obs1,1)
    for(i in 1:num_obs1){
      output1[i]=higdon.1.data (input1[i])
    }




    m1<- rgasp(design = input1, response = output1, lower_bound=FALSE)

    #####locations to samples
    testing_input1 = seq(0,10,1/50) 
    testing_input1=as.matrix(testing_input1)
    #####draw 10 samples
    m1_sample=simulate(m1,testing_input1,num_sample=10)

    #####plot these samples
    matplot(testing_input1,m1_sample, type='l',xlab='input',ylab='output')
    lines(input1,output1,type='p')
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

