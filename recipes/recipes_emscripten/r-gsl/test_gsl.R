library(gsl)
test_1 <- function() {
    airy_Ai(1:5)
}

test_2 <- function() {

    x <- seq(from=0,to=1,by=0.01)

    f <- function(x){
    cbind(x=x, Ai= airy_Ai(x), Aidash= airy_Ai_deriv(x),
    Bi=airy_Ai(x),Bidash=airy_Bi_deriv(x))
    }

    f(x)  #table 10.11, p475
    f(-x) #table 10.11, p476


    x <- 1:10  #table 10.13, p478
    cbind(x,
     airy_zero_Ai(x), airy_Ai_deriv(airy_zero_Ai(x)),
     airy_zero_Ai_deriv(x), airy_Ai(airy_zero_Ai_deriv(x)),
     airy_zero_Bi(x), airy_Bi_deriv(airy_zero_Bi(x)),

     airy_zero_Bi_deriv(x), airy_Bi(airy_zero_Bi_deriv(x))
     )


    # Verify 10.4.4 and 10.4.5, p446:
    3^(-2/3)/gamma(2/3)   - airy_Ai(0)
    3^(-1/3) / gamma(1/3) + airy_Ai_deriv(0) 
    3^(-1/6) / gamma(2/3) - airy_Bi(0)
    3^(1/6) / gamma(1/3)  - airy_Bi_deriv(0)
    #  All should be small
}

test_3 <- function() {

    # Compare native R routine with GSL:
    besselK(0.55,4) - bessel_Knu(4,0.55)  # should be small


    x <- seq(from=0,to=15,len=1000)
    plot(x,bessel_J0(x),xlim=c(0,16),ylim=c(-0.8,1.1),type="l",
               xaxt="n",yaxt="n",bty="n",xlab="",ylab="",
               main="Figure 9.1, p359")
    jj.Y0 <- bessel_Y0(x)
    jj.Y0[jj.Y0< -0.8] <- NA
    lines(x,jj.Y0)
    lines(x,bessel_J1(x),lty=2)
    jj.Y1 <- bessel_Y1(x)
    jj.Y1[jj.Y1< -0.8] <- NA
    lines(x,jj.Y1,lty=2)
    axis(1,pos=0,at=1:15,
         labels=c("","2","","4","","6","","8","","10","","12","","14","") )
    axis(2,pos=0,at=seq(from=-8,to=10,by=2)/10,
    labels=c("-.8","-.6","-.4","-.2","0",".2",".4",".6",".8","1.0"))
    arrows(0,0,16,0,length=0.1,angle=10)
    arrows(0,0,0,1.1,length=0.1,angle=10)
    text(1.1, 0.83, expression(J[0]))
    text(0.37, 0.3, expression(J[1]))
    text(0.34,-0.3, expression(Y[0]))
    text(1.7,-0.5, expression(Y[1]))
    text(4.2, 0.43, expression(Y[1]))
    text(7.2, 0.33, expression(J[0]))
    text(8.6, 0.3, expression(J[0],paste("    ,")))
    text(9.1, 0.3, expression(Y[0]))

    x <- seq(from=0,to=13,len=100)
    y <- t(bessel_jl_array(3,x))
    y[y>0.6] <- NA
     matplot(x,y,col="black",type="l",xaxt="n",yaxt="n",bty="n",
             xlab="",ylab="",xlim=c(0,16),ylim=c(-0.3,0.75),
             main="Figure 10.1, p438")
    axis(1,pos=0,at=2*(1:7))
    arrows(0,0,15,0,length=0.1,angle=10)
    arrows(0,0,0,0.65,length=0.1,angle=10)
    axis(2,pos=0,las=1,at=seq(from=-3,to=6)/10,
             labels=c("-.3","-.2","-.1","0",".1",".2",".3",".4",".5",".6"))
    text(0, 0.7, expression(J[n](x)))
    text(15.5, 0, expression(x))
    text(2.2,0.58,expression(n==0))
    text(3.2,0.4,expression(n==1))
    text(4.3,0.3,expression(n==2))
    text(6.0,0.22,expression(n==3))



    x <- seq(from=0 ,to=5,by=0.1)
    cbind(x, bessel_J0(x),bessel_J1(x),bessel_Jn(2,x))      #table 9.1, p390
    cbind(x, bessel_Y0(x),bessel_Y1(x),bessel_Yn(2,x))      #table 9.2, p391
    t(bessel_Jn_array(3,9,x*2))                             #table 9.2, p398



     x <- seq(from=8,to=10,by=0.2)
     jj <- t(bessel_Jn(n=3:9,x=t(matrix(x,11,7))))
    colnames(jj) <- paste("J",3:9,"(x)",sep="")
    cbind(x,jj)                 #another part of table 9.2, p398


     x <- seq(from=8,to=10,by=0.2)
     jj <- t(bessel_Yn(n=3:9,x=t(matrix(x,11,7))))
    colnames(jj) <- paste("J",3:9,"(x)",sep="")
    cbind(x,jj)                 #part of table 9.2, p399

    cbind(                       x,                         #table 9.8, p416
            exp(-x)*bessel_I0  (x),
            exp(-x)*bessel_I1  (x),
             x^(-2)*bessel_In(2,x)
    )

    cbind(                      x,                          #table 9.8, p417
            exp(x)*bessel_K0  (x),
            exp(x)*bessel_K1  (x),
             x^(2)*bessel_Kn(2,x)
    )

    cbind(x,                                                #table 10.1 , p457
        bessel_j0(x),
        bessel_j1(x),
        bessel_j2(x),
        bessel_y0(x),
        bessel_y1(x),
        bessel_y2(x)
    )

     cbind(0:9,"x=1"=bessel_yl(l=0:9,x=1), "x=2"=bessel_yl(l=0:9,x=2), "x=5"=bessel_yl(l=0:9,x=5)) 
                                                            #table 10.5, p466, top
}

test_4 <- function() {

    x <- (0:30)*pi/180
    clausen(x)          #table 27.8, p1006
}

test_5 <- function() {

    x <- seq(from=0,to=14,len=300)
    jj <- coulomb_wave_FG(1,10,x,0)
    plot(x,jj$val_F,type="l",xaxt="n",yaxt="n",bty="n",xlab="",ylab="",
           main="Figure 14.1, p539")
    lines(x,jj$val_G,type="l",lty=2)
    axis(1,pos=0,at=1:14,
           labels=c("","2","","4","","6","","8","","10","","12","","14"))
    lines(c(0,1),c(0,0))
    axis(2,pos=0)
    text(9.5, 0.63, expression(F[L]))
    text(8.5, 1.21, expression(G[L]))





    x <- seq(from=0,to=24,len=400)
    plot(x,coulomb_wave_FG(eta=1,x,L_F=0,k=0)$val_F,type="l",
         ylim=c(-1.3,1.7), xlim=c(0,26),
         xaxt="n",yaxt="n",bty="n",xlab="",ylab="",main="Figure 14.3, p541",lty=3)
    lines(x,coulomb_wave_FG(eta= 0,x,L_F=0,k=0)$val_F,type="l",lty=1)
    lines(x,coulomb_wave_FG(eta= 5,x,L_F=0,k=0)$val_F,type="l",lty=6)
    lines(x,coulomb_wave_FG(eta=10,x,L_F=0,k=0)$val_F,type="l",lty=6)
    lines(x,coulomb_wave_FG(eta=x/2,x,L_F=0,k=0)$val_F,type="l",lty="F3")
    axis(1,pos=0,at=1:24,
           labels=c("","2","","4","","","","8","","10","","12",
                    "","14","","","","18","","","","22","","24"))
    lines(c(0,26),c(0,0))
    axis(2,pos=0,at=0.2*(-6:9),
           labels=c("","-1.2","","-.8","","-.4","","0","",".4",
                    "",".8","","1.2","","1.6"))
    text(2.5, -0.8, expression(eta == 0))
    text(4.5,1.1,adj=0, expression(eta == 1))
    text(14,1.4,adj=0, expression(eta == 5))
    text(22,1.4,adj=0, expression(eta == 10))






    x <- seq(from=0.5,to=10,by=0.5)
    jj <- coulomb_wave_FG(eta=t(matrix(x,20,5)), x=1:5,0,0)
    jj.F <- t(jj$val_F)
    jj.G <- t(jj$val_G)
    colnames(jj.F) <- 1:5
    colnames(jj.G) <- 1:5
    cbind(x,jj.F)        #table 14.1, p 546, top bit.
    cbind(x,jj.G)        #table 14.1, p 547, top bit.
}

test_6 <- function() {
    coupling_3j(1,2,3,4,5,6)
    coupling_6j(1,2,3,4,5,6)
    coupling_9j(1,2,3,4,5,6,7,8,9)
}

test_7 <- function() {

    x <- seq(from=0,to=2,by=0.01)
    dawson(x)   #table 7.5 of Ab and St
}

test_8 <- function() {

    x <- seq(from=0,to=10,by=0.1)
    cbind(x,debye_1(x),debye_2(x),debye_3(x),debye_4(x))  #table 27.1
}

test_9 <- function() {

    x <- seq(from=0, to=0.1,by=0.01)
    cbind(x,"f(x)"=dilog(1-x))   #table 27.7, p1005
}

test_10 <- function() {
    ellint_Kcomp(0.3)
    ellint_Ecomp(0.3)
    ellint_F(0.4,0.7)
    ellint_E(0.4,0.7)
    ellint_P(0.4,0.7,0.3)
    ellint_D(0.4,0.3)
    ellint_RC(0.5,0.6)
    ellint_RD(0.5,0.6,0.7)
    ellint_RF(0.5,0.6,0.7)
    ellint_RJ(0.5,0.6,0.7,0.1)


    x <- seq(from=0,to=0.5,by=0.01)
    col1 <- ellint_Kcomp(sqrt(x))
    col2 <- ellint_Kcomp(sqrt(1-x))
    col3 <- exp(-pi*col2/col1)
    cbind(x,col1,col2,col3)         #table 17.1, p608

    x <- 0:45
    col1 <- ellint_Kcomp(sin(pi/180*x))
    col2 <- ellint_Kcomp(sin(pi/2-pi/180*x))
    col3 <- exp(-pi*col2/col1)
    cbind(x,col1,col2,col3)       #table 17.2, p610

    x <- seq(from=0,to=90,by=2)
    f <- function(a){ellint_F(phi=a*pi/180,sin(x*pi/180))}
    g <- function(a){ellint_E(phi=a*pi/180,sin(x*pi/180))}
    h <- function(a,n){ellint_P(phi=a*pi/180,sin( a*15*pi/180),n)}
    i <- function(x){ellint_P(phi=x*pi/180, k=sin((0:6)*15*pi/180),  n= -0.6)}


    cbind(x,f(5),f(10),f(15),f(20),f(25),f(30))          #table 17.5, p613
    cbind(x,g(5),g(10),g(15),g(20),g(25),g(30))          #table 17.6, p616



    cbind(i(15),i(30),i(45),i(60),i(75),i(90))           #table 17.9,
                                                         #(BOTTOM OF p625)
}

test_11 <- function() {

    K <- ellint_F(phi=pi/2,k=sqrt(1/2))  #note the sqrt: m=k^2
    u <- seq(from=0,to=4*K,by=K/24)
    jj <- elljac(u,1/2)
    plot(u,jj$sn,type="l",xaxt="n",yaxt="n",bty="n",ylab="",xlab="",main="Fig 16.1, p570")
    lines(u,jj$cn,lty=2)
    lines(u,jj$dn,lty=3)
    axis(1,pos=0,at=c(K,2*K,3*K,4*K),labels=c("K","2K","3K","4K"))
    abline(0,0)
    axis(2,pos=0,at=c(-1,1))
    text(1.8*K,0.6,"sn u")
    text(1.6*K,-0.5,"cn u")
    text(2.6*K,0.9,"dn u")



     a <- seq(from=-5,to=5,len=100)
    jj <- outer(a,a,function(a,b){a})
    z <- jj+1i*t(jj)
    e <- Re(gsl_cd(z,m=0.2))
    e[abs(e)>10] <- NA
    contour(a,a,e,nlev=55)
}

test_12 <- function() {


    erf(0.745) # Example 1, page 304
}

test_13 <- function() {
    x <- seq(from=0.5, to=1, by=0.01)
    cbind(x,Si(x),Ci(x),expint_Ei(x),expint_E1(x))  #table 5.1 of AS, p239

    x <- seq(from=0, to=12, len=100)
    plot(x,Ci(x),col="black",type="l",xaxt="n",yaxt="n",bty="n",
             xlab="",ylab="",main="Figure 5.6, p232",
             xlim=c(0,12),ylim=c(-1,2.0))
    lines(x,Si(x))
    axis(1,pos=0)
    axis(2,pos=0)
     abline(h=pi/2,lty=2)


    # Table 5.4, page 245:
     xvec <- seq(from=0,by=0.01,len=20)
     nvec <- c(2,3,4,10,20)
     x <- kronecker(xvec,t(rep(1,5)))
     n <- kronecker(t(nvec),rep(1,20))
     ans <- cbind(x=xvec,expint_En(n,x))
     rownames(ans) <- rep(" ",length(xvec))
     colnames(ans) <- c("x",paste("n=",nvec,sep=""))
     class(ans) <- "I do not understand the first column"

     ans
}

test_14 <- function() {

    x <- seq(from=0,to=2,by=0.01)
    fermi_dirac_m1(x)   #table 7.5 of Ab and St
}

test_15 <- function() {
    gsl_sf_gamma(3)

    lngamma_complex(1+seq(from=0,to=5,by=0.1)*1i)  #table 6.7, p 277 (LH col)
                                                   #note 2pi phase diff


    jj <- expand.grid(1:10,2:5)
    x <- taylorcoeff(jj$Var1,jj$Var2)
    dim(x) <- c(10,4)
    x    #table 23.5, p818


    jj <- expand.grid(36:50,9:13)
    x <- gsl_sf_choose(jj$Var1,jj$Var2)
    dim(x) <- c(15,5)
    x     #table 24.1, p829  (bottom bit)

    gamma_inc(1.2,1.3)
    beta(1.2, 1.3)
    lnbeta(1.2,1.55)
    beta_inc(1.2,1.4,1.6)

    gamma_inc_P(1.8, 5) - pgamma(5, 1.8)  # should be small
}

test_16 <- function() {

    x <- seq(from=-1 ,to=1,len=300)
    y <- gegenpoly_array(6,0.5,x)
    matplot(x,t(y[-(1:2),]), xlim=c(-1,1.2),ylim=c(-0.5,1.5),
           type="l",xaxt="n",yaxt="n",bty="n",xlab="",ylab="",
           main="Figure 22.5, p777",col="black")
    axis(1,pos=0)
    axis(2,pos=0)


    plot(x, gegenpoly_n(5,lambda=0.2, x,give=FALSE,strict=TRUE),
    xlim=c(-1,1),ylim=c(-1.5,1.5),main="Figure 22.5, p777",
    type="n",xaxt="n",yaxt="n",bty="n",xlab="",ylab="")
    lines(x, gegenpoly_n(5,lambda=0.2, x,give=FALSE,strict=TRUE))
    lines(x, gegenpoly_n(5,lambda=0.4, x,give=FALSE,strict=TRUE))
    lines(x, gegenpoly_n(5,lambda=0.6, x,give=FALSE,strict=TRUE))
    lines(x, gegenpoly_n(5,lambda=0.8, x,give=FALSE,strict=TRUE))
    lines(x, gegenpoly_n(5,lambda=1.0, x,give=FALSE,strict=TRUE))
    axis(1,pos=0)
    axis(2,pos=0,las=1)
}

test_17 <- function() {

    hyperg_0F1(0.1,0.55)

    hyperg_1F1_int(2,3,0.555)
    hyperg_1F1(2.12312,3.12313,0.555)
    hyperg_U_int(2, 3, 0.555)
    hyperg_U(2.234, 3.234, 0.555)
}

test_18 <- function() {

    x <- seq(from=0,to=6,len=100)
    plot(x,laguerre_n(2,0,x),xlim=c(0,6),ylim=c(-2,3),
              type="l",xaxt="n",yaxt="n",bty="n",xlab="",ylab="",
              main="Figure 22.9, p780")

    lines(x,laguerre_n(3,0,x))
    lines(x,laguerre_n(4,0,x))
    lines(x,laguerre_n(5,0,x))
    axis(1,pos=0)
    axis(2,pos=0)
}

test_19 <- function() {
    a <- runif(6)
    L <- lambert_W0(a)
    print(L*exp(L) - a)
}

test_20 <- function() {
     theta <- seq(from=0,to=pi/2,len=100)
     plot(theta,legendre_P1(cos(theta)),type="l",ylim=c(-0.5,1), main="Figure 8.1, p338")
     abline(1,0)
     lines(theta,legendre_P2(cos(theta)),type="l")
     lines(theta,legendre_P3(cos(theta)),type="l")

    x <- seq(from=0,to=1,len=600)
    plot(x, legendre_Plm(3,1,x), type="l",lty=3,main="Figure 8.2, p338: note sign error")
    lines(x,legendre_Plm(2,1,x), type="l",lty=2)
    lines(x,legendre_Plm(1,1,x), type="l",lty=1)
    abline(0,0)


    plot(x,legendre_Ql(0,x),xlim=c(0,1), ylim=c(-1,1.5), type="l",lty=1,
    main="Figure 8.4, p339")
    lines(x,legendre_Ql(1,x),lty=2)
    lines(x,legendre_Ql(2,x),lty=3)
    lines(x,legendre_Ql(3,x),lty=4)
    abline(0,0)

    #table 8.1 of A&S:
    t(legendre_Pl_array(10, seq(from=0,to=1,by=0.01))[1+c(2,3,9,10),])

    #table 8.3:
    f <- function(n){legendre_Ql(n, seq(from=0,to=1,by=0.01))}
    sapply(c(0,1,2,3,9,10),f)


    # Some checks for the legendre_array() series:

    # P_6^1(0.3):
    legendre_array(0.3,7)[7,2]         # MMA:  LegendreP[6,1,0.3]; note off-by-one issue

    # d/dx  P_8^5(x) @ x=0.2:
    legendre_deriv_array(0.2,8)[9,6]   # MMA: D[LegendreP[8,5,x],x] /. {x -> 0.2}


    # alternative derivatives:
     legendre_deriv_alt_array(0.4,8)[9,6]  # D[LegendreP[8,5,Cos[x]],x] /. x -> ArcCos[0.4]
}

test_21 <- function() {

    x <- seq(from=0.1,to=2,by=0.01)
    log(x)   #table 7.5 of Ab and St
}

test_22 <- function() {
    a <- matrix(1:4,2,2)
    rownames(a) <- letters[1:2]
    (jj <- gsl_poly(1:3,a))

    jj-(1 + 2*a + 3*a^2)  #should be small
}

test_23 <- function() {
    pow_int(pi/2,1:10)
}

test_24 <- function() {

    x <- seq(from=1.2,to=1.25,by=0.005)
    cbind(x,psi(x),psi_1(x))
    #tabe 6.1, p267, bottom bit

    psi_int(1:6)
    psi(pi+(1:6))
    psi_1piy(pi+(1:6))
    psi_1_int(1:6)
    psi_n(m=5,x=c(1.123,1.6523))
}

test_25 <- function() {
    q <- qrng_alloc(dim = 2)
    qrng_name(q)
    qrng_get(q, 10)
}

test_26 <- function() {
    r <- rng_alloc("cmrg")
    rng_set(r, 100)
    rng_uniform(r, 10)
}

test_27 <- function() {

    x <- seq(from=0,to=2,by=0.01)
    synchrotron_1(x)
    synchrotron_2(x)
}

test_28 <- function() {

    x <- seq(from=0,to=2,by=0.01)
    transport_2(x)
    transport_3(x)
}

test_29 <- function() {

    x <- seq(from=0,to=2,by=0.01)
    gsl_sf_sin(x)   #table xx of Ab and St
    gsl_sf_cos(x)   #table xx of Ab and St

    f <- function(x){abs(sin(x+1)-sin(x)*cos(1)-cos(x)*sin(1))}
    g <-
    function(x){abs(gsl_sf_sin(x+1)-gsl_sf_sin(x)*gsl_sf_cos(1)-gsl_sf_cos(x)*gsl_sf_sin(1))}

    f(100000:100010)
    g(100000:100010)
}

test_30 <- function() {

    n <- 1:10
    cbind(n,zeta(n),eta(n))   #table 23.3, p 811


    zeta_int(1:5)
    zeta(c(pi,pi*2))
    zetam1_int(1:5)
    zetam1(c(pi,pi*2))
    hzeta(1.1,1.2)
    eta_int(1:5)
    eta(c(pi,pi*2))
}

test_31 <- function() {

    # COMMENTED OUT PENDING PERMANENT FIX
    # The Rosenbrock function:

    # x0 <- c(-1.2, 1)
    # f <- function(x) (1 - x[1])^2 + 100 * (x[2] - x[1]^2)^2
    # df <- function(x) c(-2*(1 - x[1]) + 100 * 2 * (x[2] - x[1]^2) * (-2*x[1]),
    #                     100 * 2 * (x[2] - x[1]^2))
    # 
    # # The simple way to call multimin.
    # state <- multimin(x0, f, df)
    # print(state$x)
    # 
    # # The fine-control way to call multimin.
    # state <- multimin.init(x0, f, df, method="conjugate-fr")
    # for (i in 1:200)
    # 	state <- multimin.iterate(state)
    # print(state$x)
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

